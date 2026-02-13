import { EventEmitter } from 'events';

export interface RobloxCommand {
  id: string;
  method: string;
  params: any;
  _created?: number;
}

export interface RobloxResult {
  id: string;
  success: boolean;
  data: any;
  error?: string;
}

const STUDIO_COMMANDS = ['StartPlaySolo', 'StartPlay', 'StopPlay', 'IsPlaying'];

class RobloxBridge extends EventEmitter {
  private commandQueue: RobloxCommand[] = [];
  private pendingResponses = new Map<string, (result: RobloxResult) => void>();
  private activeContexts = new Map<string, number>(); // context -> timestamp
  private forceStopTimestamp = 0;

  async execute(method: string, params: any): Promise<any> {
    const now = Date.now();

    if (method === 'IsPlaying') {
      if (now - this.forceStopTimestamp < 10000) return false;
      const gameIsActive = Array.from(this.activeContexts.entries()).some(
        ([ctx, ts]) => (ctx === 'server' || ctx === 'client') && (now - ts) < 15000
      );
      return gameIsActive;
    }

    if (method === 'StopPlay') {
      this.forceStopTimestamp = now;
    }

    const id = Math.random().toString(36).substring(7);
    const command: RobloxCommand = { id, method, params, _created: now };
    this.commandQueue.push(command);

    return new Promise((resolve, reject) => {
      const timeout = setTimeout(() => {
        this.pendingResponses.delete(id);
        if (method === 'StopPlay') {
          resolve("Stop signal broadcasted to all active contexts.");
        } else {
          reject(new Error(`Timed out for ${method}. Check Roblox Studio output.`));
        }
      }, 15000); // Shorter timeout for user responsiveness

      this.pendingResponses.set(id, (result) => {
        clearTimeout(timeout);
        if (result.success) {
          resolve(result.data);
        } else {
          reject(new Error(result.error || 'Unknown error'));
        }
      });
    });
  }

  getPendingCommands(context: string): RobloxCommand[] {
    const now = Date.now();
    this.activeContexts.set(context, now);

    const isEdit = (context === 'edit');
    const isServer = (context === 'server');

    const commandsToReturn: RobloxCommand[] = [];

    for (const cmd of this.commandQueue) {
      if (cmd.method === 'StopPlay') {
        // BROADCAST StopPlay to Edit and Server exactly once per command
        const deliveredKey = `_delivered_${context}`;
        if (!(cmd as any)[deliveredKey] && (isEdit || isServer)) {
          commandsToReturn.push(cmd);
          (cmd as any)[deliveredKey] = true;
        }
        continue;
      }

      const isStudio = STUDIO_COMMANDS.includes(cmd.method);
      if (isStudio) {
        if (isEdit) commandsToReturn.push(cmd);
      } else {
        // Non-studio commands go to Server if available
        const hasServer = Array.from(this.activeContexts.entries()).some(([ctx, ts]) => ctx === 'server' && (now - ts) < 8000);
        if (hasServer) {
          if (isServer) commandsToReturn.push(cmd);
        } else {
          if (isEdit) commandsToReturn.push(cmd);
        }
      }
    }

    // Clean up queue: 
    // 1. Remove commands that were just returned if they aren't StopPlay
    // 2. Remove StopPlay if it's older than 5 seconds
    this.commandQueue = this.commandQueue.filter(cmd => {
      if (commandsToReturn.includes(cmd)) {
        if (cmd.method === 'StopPlay') return true; // Keep StopPlay for broadcasting
        return false; // Consume others
      }
      if (cmd.method === 'StopPlay') {
        const isOld = (now - (cmd._created || 0) > 5000);
        return !isOld;
      }
      return true;
    });

    return commandsToReturn;
  }

  handleResult(result: RobloxResult) {
    const resolver = this.pendingResponses.get(result.id);
    if (resolver) {
      const command = this.commandQueue.find(c => c.id === result.id);
      resolver(result);

      // If it's NOT a StopPlay command, we can delete the resolver immediately.
      // For StopPlay, we briefly keep it to allow both Edit and Server to respond if they want,
      // though the promise resolves on the first one.
      if (!command || command.method !== 'StopPlay') {
        this.pendingResponses.delete(result.id);
      }
    }
  }
}

export const bridge = new RobloxBridge();
