# Roblox Studio MCP Assistant - Quick Start

## 1. Installation

### Step A: Setup Node Server
1. Open terminal in this folder (`C:/Desktop/roblox-studio-mcp-server-V1`).
2. Install dependencies:
   ```bash
   npm install
   ```
3. Build the server:
   ```bash
   npm run build
   ```

### Step B: Install Roblox Plugin
1. Copy the file `plugin/loader.server.lua` from this folder.
2. Open **Roblox Studio**.
3. Right-click **ServerScriptService** in the Explorer -> **Paste into**.
4. (Optional) For permanent installation, save it to your local Plugins folder (`%LOCALAPPDATA%\Roblox\Plugins`).

### Step C: Configure Cursor MCP
Add this to your MCP settings (Settings > Features > MCP > Edit in settings.json):

```json
{
  "roblox-studio": {
    "command": "node",
    "args": [
      "C:\\PATH-TO-roblox-studio-mcp-server-V1\\dist\\index.js"
    ]
  }
}
```

## 2. Test It!

1. **Start the Game** in Roblox Studio (Press F5 or Play).
2. Wait for the output: `[MCP Plugin] Plugin Loaded. Polling http://localhost:8081`.
3. Ask Cursor:
   > "Create a bright neon blue part at position 0, 10, 0 named 'TestPart'"

## 3. Troubleshooting

| Issue | Solution |
|-------|----------|
| **"Connection Refused"** | Ensure the Node server is running. Cursor starts it automatically when you add it to MCP settings. Check Cursor logs if it fails. |
| **"Timeout" / No Response** | Make sure you hit **Play** in Roblox Studio. The plugin only runs when the game (or plugin script) is running. |
| **HTTP 403 (Forbidden)** | In Roblox Studio, go to **Home** > **Game Settings** > **Security** and enable **Allow HTTP Requests**. |
| **"Module not found"** | Did you run `npm install` and `npm run build`? Check the `dist` folder exists. |


