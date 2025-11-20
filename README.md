# Advanced Roblox Studio AI Assistant (MCP)

This project implements a Model Context Protocol (MCP) server that bridges Cursor AI to Roblox Studio, providing over 40+ tools to manipulate the game environment directly from the AI.

## Prerequisites
- Node.js installed.
- Roblox Studio installed.

## Setup

1.  **Install Dependencies**:
    ```bash
    npm install
    ```

2.  **Build the Project**:
    ```bash
    npm run build
    ```

3.  **Install the Roblox Plugin**:
    - Locate the file `plugin/loader.server.lua` in this project.
    - Copy this file.
    - Open your Roblox Plugins folder:
      - Windows: `%LOCALAPPDATA%\Roblox\Plugins`
      - Mac: `~/Documents/Roblox/Plugins`
    - Paste the file there. You may need to rename it to `McpLoader.server.lua` or similar.
    - Alternatively, in Roblox Studio, go to the "Plugins" tab -> "Plugin Folder", and paste it there.

4.  **Allow HTTP Requests**:
    - In Roblox Studio, when the plugin runs, it might ask for permission to access `localhost:8081`. Grant it.
    - If using as a game script, enable "Allow HTTP Requests" in Game Settings.

## Running

1.  **Start the MCP Server**:
    You need to configure Cursor to run this server.
    
    Add a new MCP server in Cursor settings:
    - **Name**: RobloxStudio
    - **Type**: command
    - **Command**: `node`
    - **Args**: `D:\lickato'ing\dist\index.js` (Update path if moved)

2.  **Connect**:
    Once added, the server will start automatically. It hosts a local HTTP server on port `8081` which the Roblox plugin connects to.

3.  **Usage**:
    Ask Cursor to "Create a part", "Make a script", "Move the player", etc.

## Architecture
- **MCP Server (Node.js)**: Receives commands from Cursor and queues them.
- **Roblox Plugin (Lua)**: Polls the Node server every 0.5s for new commands, executes them, and returns results.

## Troubleshooting
- **"Timeout"**: Ensure the Roblox Plugin is running (Studio is open).
- **"Connection Refused"**: Ensure the Node server is running (Cursor should start it).

