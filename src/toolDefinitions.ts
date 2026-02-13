import { Tool } from "@modelcontextprotocol/sdk/types.js";

export const tools: Tool[] = [
  {
    name: "CreateInstance",
    description: "Create a new Instance in Roblox",
    inputSchema: {
      type: "object",
      properties: {
        className: { type: "string" },
        parentPath: { type: "string", description: "Path to parent (e.g. game.Workspace)" },
        name: { type: "string" },
        properties: { type: "object", description: "Initial properties" }
      },
      required: ["className", "parentPath"]
    }
  },
  {
    name: "DeleteInstance",
    description: "Destroy an Instance",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string", description: "Path to the instance" }
      },
      required: ["path"]
    }
  },
  {
    name: "SetProperty",
    description: "Set a property of an Instance",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" },
        property: { type: "string" },
        value: {
          anyOf: [
            { type: "string" },
            { type: "number" },
            { type: "boolean" }
          ],
          description: "Value to set"
        }
      },
      required: ["path", "property", "value"]
    }
  },
  {
    name: "GetProperty",
    description: "Get a property value",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" },
        property: { type: "string" }
      },
      required: ["path", "property"]
    }
  },
  {
    name: "GetChildren",
    description: "Get names of children",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" }
      },
      required: ["path"]
    }
  },
  {
    name: "GetDescendants",
    description: "Get all descendants (warning: can be large)",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" }
      },
      required: ["path"]
    }
  },
  {
    name: "FindFirstChild",
    description: "Find a child by name",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" },
        name: { type: "string" },
        recursive: { type: "boolean" }
      },
      required: ["path", "name"]
    }
  },
  {
    name: "MoveTo",
    description: "Move a Model or Part to a location",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" },
        position: { type: "array", items: { type: "number" }, minItems: 3, maxItems: 3 }
      },
      required: ["path", "position"]
    }
  },
  {
    name: "SetPosition",
    description: "Set Position property (Vector3)",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" },
        x: { type: "number" },
        y: { type: "number" },
        z: { type: "number" }
      },
      required: ["path", "x", "y", "z"]
    }
  },
  {
    name: "SetRotation",
    description: "Set Rotation (Orientation/CFrame angles)",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" },
        x: { type: "number" },
        y: { type: "number" },
        z: { type: "number" }
      },
      required: ["path", "x", "y", "z"]
    }
  },
  {
    name: "SetSize",
    description: "Set Size property",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" },
        x: { type: "number" },
        y: { type: "number" },
        z: { type: "number" }
      },
      required: ["path", "x", "y", "z"]
    }
  },
  {
    name: "SetColor",
    description: "Set Color3",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" },
        r: { type: "number", description: "0-255" },
        g: { type: "number", description: "0-255" },
        b: { type: "number", description: "0-255" }
      },
      required: ["path", "r", "g", "b"]
    }
  },
  {
    name: "SetTransparency",
    description: "Set Transparency",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" },
        value: { type: "number", description: "0 to 1" }
      },
      required: ["path", "value"]
    }
  },
  {
    name: "SetMaterial",
    description: "Set Material",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" },
        material: { type: "string" }
      },
      required: ["path", "material"]
    }
  },
  {
    name: "SetAnchored",
    description: "Set Anchored property",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" },
        anchored: { type: "boolean" }
      },
      required: ["path", "anchored"]
    }
  },
  {
    name: "SetCanCollide",
    description: "Set CanCollide property",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" },
        canCollide: { type: "boolean" }
      },
      required: ["path", "canCollide"]
    }
  },
  {
    name: "CreateScript",
    description: "Create a new Script with source",
    inputSchema: {
      type: "object",
      properties: {
        name: { type: "string" },
        parentPath: { type: "string" },
        source: { type: "string" },
        type: { type: "string", enum: ["Script", "LocalScript", "ModuleScript"] }
      },
      required: ["name", "parentPath", "source"]
    }
  },
  {
    name: "GetScriptSource",
    description: "Read source of a script",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" }
      },
      required: ["path"]
    }
  },
  {
    name: "SetScriptSource",
    description: "Update script source",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" },
        source: { type: "string" }
      },
      required: ["path", "source"]
    }
  },
  {
    name: "AppendToScript",
    description: "Append code to end of script",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" },
        code: { type: "string" }
      },
      required: ["path", "code"]
    }
  },
  {
    name: "RunConsoleCommand",
    description: "Run arbitrary Luau code in Studio command bar context",
    inputSchema: {
      type: "object",
      properties: {
        code: { type: "string" }
      },
      required: ["code"]
    }
  },
  {
    name: "GetSelection",
    description: "Get currently selected objects",
    inputSchema: {
      type: "object",
      properties: {}
    }
  },
  {
    name: "SetSelection",
    description: "Set selection to specific objects",
    inputSchema: {
      type: "object",
      properties: {
        paths: { type: "array", items: { type: "string" } }
      },
      required: ["paths"]
    }
  },
  {
    name: "ClearSelection",
    description: "Clear selection",
    inputSchema: {
      type: "object",
      properties: {}
    }
  },
  {
    name: "AddToSelection",
    description: "Add objects to current selection",
    inputSchema: {
      type: "object",
      properties: {
        paths: { type: "array", items: { type: "string" } }
      },
      required: ["paths"]
    }
  },
  {
    name: "UngroupModel",
    description: "Ungroup a model (move children to parent and destroy model)",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" }
      },
      required: ["path"]
    }
  },
  {
    name: "GroupSelection",
    description: "Group selected items into a Model",
    inputSchema: {
      type: "object",
      properties: {
        name: { type: "string" }
      },
      required: ["name"]
    }
  },
  {
    name: "SetTimeOfDay",
    description: "Set Lighting TimeOfDay",
    inputSchema: {
      type: "object",
      properties: {
        time: { type: "string", description: "e.g. '14:00:00'" }
      },
      required: ["time"]
    }
  },
  {
    name: "SetBrightness",
    description: "Set Lighting Brightness",
    inputSchema: {
      type: "object",
      properties: {
        brightness: { type: "number" }
      },
      required: ["brightness"]
    }
  },
  {
    name: "SetAtmosphereDensity",
    description: "Set Atmosphere Density",
    inputSchema: {
      type: "object",
      properties: {
        density: { type: "number" }
      },
      required: ["density"]
    }
  },
  {
    name: "CreateLight",
    description: "Create a Light object",
    inputSchema: {
      type: "object",
      properties: {
        parentPath: { type: "string" },
        type: { type: "string", enum: ["PointLight", "SpotLight", "SurfaceLight"] },
        brightness: { type: "number" },
        color: { type: "array", items: { type: "number" }, description: "[r,g,b]" }
      },
      required: ["parentPath", "type"]
    }
  },
  {
    name: "GetPlayers",
    description: "Get list of players",
    inputSchema: {
      type: "object",
      properties: {}
    }
  },
  {
    name: "GetPlayerPosition",
    description: "Get position of a player's character",
    inputSchema: {
      type: "object",
      properties: {
        username: { type: "string" }
      },
      required: ["username"]
    }
  },
  {
    name: "TeleportPlayer",
    description: "Teleport a player to a position",
    inputSchema: {
      type: "object",
      properties: {
        username: { type: "string" },
        position: { type: "array", items: { type: "number" } }
      },
      required: ["username", "position"]
    }
  },
  {
    name: "KickPlayer",
    description: "Kick a player (mock)",
    inputSchema: {
      type: "object",
      properties: {
        username: { type: "string" },
        reason: { type: "string" }
      },
      required: ["username"]
    }
  },
  {
    name: "SavePlace",
    description: "Prompt save (Studio)",
    inputSchema: {
      type: "object",
      properties: {}
    }
  },
  {
    name: "GetPlaceInfo",
    description: "Get PlaceId and Name",
    inputSchema: {
      type: "object",
      properties: {}
    }
  },
  {
    name: "GetService",
    description: "Get a service (ensure it exists)",
    inputSchema: {
      type: "object",
      properties: {
        service: { type: "string" }
      },
      required: ["service"]
    }
  },
  {
    name: "CloneInstance",
    description: "Clone an instance",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" },
        parentPath: { type: "string" }
      },
      required: ["path"]
    }
  },
  {
    name: "RenameInstance",
    description: "Rename an instance",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" },
        newName: { type: "string" }
      },
      required: ["path", "newName"]
    }
  },
  {
    name: "Chat",
    description: "Send a message to the chat system (as system)",
    inputSchema: {
      type: "object",
      properties: {
        message: { type: "string" },
        color: { type: "string", enum: ["Red", "Blue", "Green", "White"] }
      },
      required: ["message"]
    }
  },
  {
    name: "ReplaceScriptLines",
    description: "Replace a range of lines in a script",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" },
        startLine: { type: "number" },
        endLine: { type: "number" },
        content: { type: "string" }
      },
      required: ["path", "startLine", "endLine", "content"]
    }
  },
  {
    name: "InsertScriptLines",
    description: "Insert lines at a specific position in a script",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" },
        lineNumber: { type: "number" },
        content: { type: "string" }
      },
      required: ["path", "lineNumber", "content"]
    }
  },
  {
    name: "SetAttribute",
    description: "Set an attribute on an instance",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" },
        name: { type: "string" },
        value: {
          anyOf: [
            { type: "string" },
            { type: "number" },
            { type: "boolean" }
          ]
        }
      },
      required: ["path", "name", "value"]
    }
  },
  {
    name: "GetAttribute",
    description: "Get an attribute value",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" },
        name: { type: "string" }
      },
      required: ["path", "name"]
    }
  },
  {
    name: "GetAttributes",
    description: "Get all attributes of an instance",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" }
      },
      required: ["path"]
    }
  },
  {
    name: "AddTag",
    description: "Add a CollectionService tag",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" },
        tag: { type: "string" }
      },
      required: ["path", "tag"]
    }
  },
  {
    name: "RemoveTag",
    description: "Remove a CollectionService tag",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" },
        tag: { type: "string" }
      },
      required: ["path", "tag"]
    }
  },
  {
    name: "GetTags",
    description: "Get all tags on an instance",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" }
      },
      required: ["path"]
    }
  },
  {
    name: "HasTag",
    description: "Check if an instance has a tag",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" },
        tag: { type: "string" }
      },
      required: ["path", "tag"]
    }
  },
  {
    name: "PivotTo",
    description: "Set CFrame of a PVInstance (Model/Part) using PivotTo",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" },
        cframe: { type: "array", items: { type: "number" }, minItems: 12, maxItems: 12, description: "12 numbers for CFrame components" }
      },
      required: ["path", "cframe"]
    }
  },
  {
    name: "GetPivot",
    description: "Get CFrame of a PVInstance",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" }
      },
      required: ["path"]
    }
  },
  {
    name: "PlaySound",
    description: "Create and play a sound",
    inputSchema: {
      type: "object",
      properties: {
        soundId: { type: "string" },
        parentPath: { type: "string", description: "Optional parent, defaults to SoundService" },
        volume: { type: "number" }
      },
      required: ["soundId"]
    }
  },
  {
    name: "StopSound",
    description: "Stop a sound",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" }
      },
      required: ["path"]
    }
  },
  {
    name: "GetDistance",
    description: "Calculate distance between two objects",
    inputSchema: {
      type: "object",
      properties: {
        path1: { type: "string" },
        path2: { type: "string" }
      },
      required: ["path1", "path2"]
    }
  },
  {
    name: "HighlightObject",
    description: "Add a Highlight to an object",
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" },
        color: { type: "array", items: { type: "number" } },
        duration: { type: "number", description: "Optional duration in seconds" }
      },
      required: ["path"]
    }
  },
  {
    name: "StartPlaySolo",
    description: "Start a full Play Solo session (Client + Server with character)",
    inputSchema: {
      type: "object",
      properties: {}
    }
  },
  {
    name: "StartPlay",
    description: "Start server-only simulation (Run mode)",
    inputSchema: {
      type: "object",
      properties: {}
    }
  },
  {
    name: "StopPlay",
    description: "Stop the current simulation or test session",
    inputSchema: {
      type: "object",
      properties: {}
    }
  },
  {
    name: "IsPlaying",
    description: "Check if Studio simulation is running",
    inputSchema: {
      type: "object",
      properties: {}
    }
  },
  {
    name: "TestCheck",
    description: "Log a test result via TestService:Check",
    inputSchema: {
      type: "object",
      properties: {
        condition: { type: "boolean" },
        message: { type: "string" }
      },
      required: ["condition", "message"]
    }
  },
  {
    name: "TestMessage",
    description: "Log a message via TestService:Message",
    inputSchema: {
      type: "object",
      properties: {
        message: { type: "string" }
      },
      required: ["message"]
    }
  },
  {
    name: "TestError",
    description: "Log an error via TestService:Error",
    inputSchema: {
      type: "object",
      properties: {
        message: { type: "string" }
      },
      required: ["message"]
    }
  },
  {
    name: "TestRun",
    description: "Run all scripts in TestService",
    inputSchema: {
      type: "object",
      properties: {}
    }
  }
];

