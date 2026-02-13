import { EventEmitter } from 'events';

export interface RobloxCommand {
  id: string;
  method: string;
  params: any;
}

export interface RobloxResult {
  id: string;
  success: boolean;
  data: any;
  error?: string;
}

class RobloxBridge extends EventEmitter {
  private commandQueue: RobloxCommand[] = [];
  private pendingResponses = new Map<string, (result: RobloxResult) => void>();

  // Add a command to the queue and wait for response
  async execute(method: string, params: any): Promise<any> {
    const id = Math.random().toString(36).substring(7);
    const command: RobloxCommand = { id, method, params };
    
    this.commandQueue.push(command);
    
    this.emit('new_command');

    return new Promise((resolve, reject) => {
      // Set a timeout
      const timeout = setTimeout(() => {
        this.pendingResponses.delete(id);
        reject(new Error('Roblox Studio execution timed out. Is the plugin running?'));
      }, 30000); // 30s timeout

      this.pendingResponses.set(id, (result) => {
        clearTimeout(timeout);
        if (result.success) {
          resolve(result.data);
        } else {
          reject(new Error(result.error || 'Unknown Roblox error'));
        }
      });
    });
  }

  // Get pending commands (called by Roblox)
  getPendingCommands(): RobloxCommand[] {
    const commands = [...this.commandQueue];
    this.commandQueue = []; // Clear queue after retrieval
    return commands;
  }

  // Handle result from Roblox
  handleResult(result: RobloxResult) {
    const resolver = this.pendingResponses.get(result.id);
    if (resolver) {
      resolver(result);
      this.pendingResponses.delete(result.id);
    }
  }
}

export const bridge = new RobloxBridge();

