import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import express from 'express';
import bodyParser from 'body-parser';
import { tools } from './toolDefinitions';
import { bridge } from './bridge';

// --- Express Server for Roblox Bridge ---
const app = express();
const PORT = 8081;

app.use(bodyParser.json());

// Endpoint for Roblox to poll for commands
app.get('/poll', (req, res) => {
  const commands = bridge.getPendingCommands();
  res.json(commands);
});

// Endpoint for Roblox to post results
app.post('/result', (req, res) => {
  const result = req.body;
  bridge.handleResult(result);
  res.json({ status: 'ok' });
});

app.listen(PORT, () => {
  // console.error(`Roblox Bridge Server running on port ${PORT}`);
  // We use stderr for logs because stdout is for MCP protocol
});

// --- MCP Server ---
const server = new Server(
  {
    name: "roblox-studio-mcp",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: tools,
  };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const toolName = request.params.name;
  const args = request.params.arguments;

  // Check if tool exists in our definitions
  const toolDef = tools.find(t => t.name === toolName);
  if (!toolDef) {
    throw new Error(`Tool ${toolName} not found`);
  }

  try {
    // Forward to Roblox Bridge
    const result = await bridge.execute(toolName, args);
    
    // Format output for MCP
    return {
      content: [
        {
          type: "text",
          text: typeof result === 'string' ? result : JSON.stringify(result, null, 2),
        },
      ],
    };
  } catch (error: any) {
    return {
      content: [
        {
          type: "text",
          text: `Error: ${error.message}`,
        },
      ],
      isError: true,
    };
  }
});

async function run() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

run().catch((error) => {
  process.exit(1);
});

