local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local _Selection = game:GetService("Selection")

local SERVER_URL = "http://localhost:8086"

local function log(msg)
	print("[MCP Plugin] " .. tostring(msg))
end

local function getContext()
	if RunService:IsEdit() then
		return "edit"
	elseif RunService:IsServer() then
		return "server"
	else
		return "client"
	end
end

local function sendResult(id, success, data, err)
	local payload = { id = id, success = success, data = data, error = err }
	pcall(function()
		HttpService:PostAsync(SERVER_URL .. "/result", HttpService:JSONEncode(payload))
	end)
end

local function resolvePath(path)
	if path == "game" then
		return game
	end
	local segments = path:split(".")
	local current = game
	local start = 1
	if segments[1] == "game" then
		start = 2
	end
	for i = start, #segments do
		local name = segments[i]
		if not current then
			return nil
		end
		local child = current:FindFirstChild(name)
		if not child and current == game then
			pcall(function()
				child = game:GetService(name)
			end)
		end
		current = child
	end
	return current
end

local Tools = {}

function Tools.RunConsoleCommand(p)
	local func, _err
	pcall(function()
		if loadstring then
			func, _err = loadstring(p.code)
		end
	end)
	if not func then
		local gs = (getfenv and getfenv(0).loadstring) or _G.loadstring
		if gs then
			pcall(function()
				func, _err = gs(p.code)
			end)
		end
	end

	if func then
		local logs = {}
		local env = setmetatable({}, { __index = getfenv() })
		env.print = function(...)
			local args = { ... }
			local strArgs = {}
			for i, v in ipairs(args) do
				table.insert(strArgs, tostring(v))
			end
			table.insert(logs, table.concat(strArgs, " "))
			print(unpack(args))
		end
		setfenv(func, env)
		local res = { pcall(func) }
		local s = res[1]
		table.remove(res, 1)
		local output = table.concat(logs, "\n")
		if not s then
			error(output .. "\nError: " .. tostring(res[1]))
		end
		local returnStr = ""
		if #res > 0 then
			local strRes = {}
			for _, v in ipairs(res) do
				table.insert(strRes, tostring(v))
			end
			returnStr = "Returned: " .. table.concat(strRes, ", ")
		end
		return (output ~= "" and output or "") .. (output ~= "" and returnStr ~= "" and "\n" or "") .. returnStr
	else
		log("Bypassing loadstring restriction via Injection...")
		local runId = "MCP_RUN_" .. math.random(1000, 9999)
		local scriptObj = Instance.new("Script")
		scriptObj.Name = runId
		scriptObj.Source = "local logs = {}\n"
			.. "local oldPrint = print\n"
			.. "local function print(...)\n"
			.. "    local args = {...}\n"
			.. "    local strArgs = {}\n"
			.. "    for i, v in ipairs(args) do\n"
			.. "        table.insert(strArgs, tostring(v))\n"
			.. "    end\n"
			.. "    local msg = table.concat(strArgs, ' ')\n"
			.. "    table.insert(logs, msg)\n"
			.. "    task.spawn(oldPrint, unpack(args))\n"
			.. "end\n"
			.. "local s,r=pcall(function()\n"
			.. p.code
			.. "\nend)\n"
			.. "local output = table.concat(logs, '\\n')\n"
			.. "local resultStr = ''\n"
			.. "if r ~= nil then\n"
			.. "    resultStr = 'Returned: ' .. tostring(r)\n"
			.. "end\n"
			.. "local finalMsg = output\n"
			.. "if finalMsg ~= '' and resultStr ~= '' then\n"
			.. "    finalMsg = finalMsg .. '\\n' .. resultStr\n"
			.. "elseif resultStr ~= '' then\n"
			.. "    finalMsg = resultStr\n"
			.. "end\n"
			.. "if finalMsg == '' then finalMsg = 'Executed (No Output)' end\n"
			.. "script:SetAttribute('Success',s)\n"
			.. "script:SetAttribute('Result',finalMsg)\n"
			.. "script:SetAttribute('Completed',true)"
		scriptObj.Parent = game:GetService("ServerScriptService")
		local start = tick()
		while not scriptObj:GetAttribute("Completed") and tick() - start < 10 do
			task.wait(0.1)
		end
		if not scriptObj:GetAttribute("Completed") then
			scriptObj:Destroy()
			error("Injection Timed Out")
		end
		local ok = scriptObj:GetAttribute("Success")
		local res = scriptObj:GetAttribute("Result")
		scriptObj:Destroy()
		if not ok then
			error("Injection Error: " .. tostring(res))
		end
		return tostring(res)
	end
end

local stopDebounce = false
function Tools.StopPlay()
	local context = getContext()
	if stopDebounce then
		return "Stop already in progress in " .. context
	end
	stopDebounce = true

	log("StopPlay triggered in context: " .. context)

	local function safeEndTest()
		local sts = game:GetService("StudioTestService")
		if sts and sts.EndTest then
			-- Documentation says EndTest(value: Variant)
			sts:EndTest(true)
			return true
		end
		return false
	end

	if RunService:IsEdit() then
		task.spawn(function()
			log("EDIT STOP: Initiating EndTest...")
			pcall(safeEndTest)

			pcall(function()
				RunService:Stop()
			end)

			task.wait(0.5)
			if RunService:IsRunning() then
				log("EDIT STOP: Aggressive fallback...")
				pcall(safeEndTest)
				pcall(function()
					local ts = game:GetService("TestService")
					if ts and ts.Done then
						ts:Done()
					end
				end)
			end
		end)
	elseif RunService:IsServer() then
		task.spawn(function()
			log("SERVER STOP: Attempting clean termination...")
			-- On server, EndTest is often the preferred way to signal Studio to close
			pcall(safeEndTest)

			task.wait(0.2)
			if RunService:IsRunning() then
				log("SERVER STOP: game:Shutdown() fallback")
				pcall(function()
					game:Shutdown()
				end)
			end
		end)
	end

	-- Reset debounce after some time
	task.delay(5, function()
		stopDebounce = false
	end)

	return "Stop sequence initiated from " .. context
end

function Tools.IsPlaying()
	return RunService:IsRunning()
end

function Tools.StartPlaySolo()
	task.spawn(function()
		log("STARTING_PLAY_SOLO...")
		game:GetService("StudioTestService"):ExecutePlayModeAsync({})
	end)
	return "Play Solo Launched"
end

function Tools.GetPlayers()
	local players = {}
	for _, pl in ipairs(game:GetService("Players"):GetPlayers()) do
		table.insert(players, pl.Name)
	end
	return players
end

function Tools.GetPlayerPosition(p)
	local player = game:GetService("Players"):FindFirstChild(p.username)
	if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local pos = player.Character.HumanoidRootPart.Position
		return { pos.X, pos.Y, pos.Z }
	end
	error("Player or character root not found")
end

function Tools.TeleportPlayer(p)
	local player = game:GetService("Players"):FindFirstChild(p.username)
	if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		player.Character:PivotTo(CFrame.new(unpack(p.position)))
		return "Teleported " .. p.username
	end
	error("Player or character root not found")
end

function Tools.CreateInstance(p)
	local parent = resolvePath(p.parentPath)
	if not parent then
		error("Parent not found: " .. tostring(p.parentPath))
	end
	local obj = Instance.new(p.className)
	obj.Name = p.name or p.className
	obj.Parent = parent
	if p.properties then
		for k, v in pairs(p.properties) do
			pcall(function()
				obj[k] = v
			end)
		end
	end
	return obj:GetFullName()
end

function Tools.DeleteInstance(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	obj:Destroy()
	return "Deleted " .. tostring(p.path)
end

function Tools.SetProperty(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	obj[p.property] = p.value
	return "Set " .. p.property .. " to " .. tostring(p.value)
end

function Tools.CreateScript(p)
	local parent = resolvePath(p.parentPath)
	if not parent then
		error("Parent not found")
	end
	local obj = Instance.new(p.type or "Script")
	obj.Name = p.name or "Script"
	obj.Source = p.source
	obj.Parent = parent
	return obj:GetFullName()
end

function Tools.GetChildren(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	local children = {}
	for _, c in ipairs(obj:GetChildren()) do
		table.insert(children, { name = c.Name, className = c.ClassName })
	end
	return children
end

function Tools.GetProperty(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	return obj[p.property]
end

function Tools.GetDescendants(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	local descendants = {}
	-- GetDescendants can range in size, maybe limit? For now return all but just names
	for _, c in ipairs(obj:GetDescendants()) do
		table.insert(descendants, c:GetFullName())
	end
	return descendants
end

function Tools.FindFirstChild(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	local child = obj:FindFirstChild(p.name, p.recursive)
	if child then
		return child:GetFullName()
	end
	return nil
end

function Tools.MoveTo(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	if obj:IsA("Model") then
		obj:MoveTo(Vector3.new(unpack(p.position)))
	elseif obj:IsA("BasePart") then
		obj.Position = Vector3.new(unpack(p.position))
	end
	return "Moved " .. tostring(p.path)
end

function Tools.SetPosition(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	if obj:IsA("BasePart") then
		obj.Position = Vector3.new(p.x, p.y, p.z)
	elseif obj:IsA("Model") then
		obj:PivotTo(CFrame.new(p.x, p.y, p.z) * obj:GetPivot().Rotation)
	end
	return "Set position of " .. tostring(p.path)
end

function Tools.SetRotation(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	if obj:IsA("BasePart") then
		obj.Orientation = Vector3.new(p.x, p.y, p.z)
	elseif obj:IsA("Model") then
		-- Create rotation CFrame from euler angles (degrees to radians)
		local rotCFrame = CFrame.Angles(math.rad(p.x), math.rad(p.y), math.rad(p.z))
		local currentPos = obj:GetPivot().Position
		obj:PivotTo(CFrame.new(currentPos) * rotCFrame)
	end
	return "Set rotation of " .. tostring(p.path)
end

function Tools.SetSize(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	if obj:IsA("BasePart") then
		obj.Size = Vector3.new(p.x, p.y, p.z)
		return "Set size of " .. tostring(p.path)
	end
	return "Object is not a BasePart"
end

function Tools.SetColor(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	if obj:IsA("BasePart") then
		obj.Color = Color3.fromRGB(p.r, p.g, p.b)
		return "Set color of " .. tostring(p.path)
	end
	return "Object is not a BasePart"
end

function Tools.SetTransparency(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	if obj:IsA("BasePart") or obj:IsA("Decal") then
		obj.Transparency = p.value
		return "Set transparency of " .. tostring(p.path)
	end
	return "Object does not support Transparency"
end

function Tools.SetMaterial(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	if obj:IsA("BasePart") then
		-- Try to find enum
		local matEnum
		for _, enumItem in ipairs(Enum.Material:GetEnumItems()) do
			if enumItem.Name == p.material then
				matEnum = enumItem
				break
			end
		end
		if not matEnum then
			matEnum = Enum.Material.Plastic
		end
		obj.Material = matEnum
		return "Set material of " .. tostring(p.path)
	end
	return "Object is not a BasePart"
end

function Tools.SetAnchored(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	if obj:IsA("BasePart") then
		obj.Anchored = p.anchored
		return "Set anchored of " .. tostring(p.path)
	end
	return "Object is not a BasePart"
end

function Tools.SetCanCollide(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	if obj:IsA("BasePart") then
		obj.CanCollide = p.canCollide
		return "Set CanCollide of " .. tostring(p.path)
	end
	return "Object is not a BasePart"
end

-- Script Tools
function Tools.GetScriptSource(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	if obj:IsA("LuaSourceContainer") then
		return obj.Source
	end
	return "Object is not a script"
end

function Tools.SetScriptSource(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	if obj:IsA("LuaSourceContainer") then
		obj.Source = p.source
		return "Updated source of " .. tostring(p.path)
	end
	return "Object is not a script"
end

function Tools.AppendToScript(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	if obj:IsA("LuaSourceContainer") then
		obj.Source = obj.Source .. "\n" .. p.code
		return "Appended to " .. tostring(p.path)
	end
	return "Object is not a script"
end

function Tools.ReplaceScriptLines(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	if obj:IsA("LuaSourceContainer") then
		local lines = obj.Source:split("\n")
		local newLines = {}
		for i = 1, #lines do
			if i < p.startLine or i > p.endLine then
				table.insert(newLines, lines[i])
			elseif i == p.startLine then
				table.insert(newLines, p.content)
			end
		end
		obj.Source = table.concat(newLines, "\n")
		return "Replaced lines " .. p.startLine .. "-" .. p.endLine .. " in " .. tostring(p.path)
	end
	return "Object is not a script"
end

function Tools.InsertScriptLines(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	if obj:IsA("LuaSourceContainer") then
		local lines = obj.Source:split("\n")
		table.insert(lines, p.lineNumber, p.content)
		obj.Source = table.concat(lines, "\n")
		return "Inserted lines at " .. p.lineNumber .. " in " .. tostring(p.path)
	end
	return "Object is not a script"
end

-- Selection Tools
function Tools.GetSelection()
	local selection = game:GetService("Selection"):Get()
	local paths = {}
	for _, obj in ipairs(selection) do
		table.insert(paths, obj:GetFullName())
	end
	return paths
end

function Tools.SetSelection(p)
	local objects = {}
	for _, path in ipairs(p.paths) do
		local obj = resolvePath(path)
		if obj then
			table.insert(objects, obj)
		end
	end
	game:GetService("Selection"):Set(objects)
	return "Selection set to " .. #objects .. " objects"
end

function Tools.AddToSelection(p)
	local current = game:GetService("Selection"):Get()
	for _, path in ipairs(p.paths) do
		local obj = resolvePath(path)
		if obj then
			table.insert(current, obj)
		end
	end
	game:GetService("Selection"):Set(current)
	return "Added to selection"
end

function Tools.ClearSelection()
	game:GetService("Selection"):Set({})
	return "Selection cleared"
end

function Tools.GroupSelection(p)
	local selection = game:GetService("Selection"):Get()
	if #selection == 0 then
		return "Nothing selected"
	end
	local model = Instance.new("Model")
	model.Name = p.name
	model.Parent = selection[1].Parent -- Basic parenting guess
	for _, obj in ipairs(selection) do
		obj.Parent = model
	end
	game:GetService("Selection"):Set({ model })
	return "Grouped selection into " .. model:GetFullName()
end

function Tools.UngroupModel(p)
	local model = resolvePath(p.path)
	if not model or not model:IsA("Model") then
		return "Invalid model"
	end
	local parent = model.Parent
	for _, child in ipairs(model:GetChildren()) do
		child.Parent = parent
	end
	model:Destroy()
	return "Ungrouped " .. tostring(p.path)
end

-- Environment Tools
function Tools.SetTimeOfDay(p)
	game:GetService("Lighting").TimeOfDay = p.time
	return "Set time to " .. p.time
end

function Tools.SetBrightness(p)
	game:GetService("Lighting").Brightness = p.brightness
	return "Set brightness to " .. p.brightness
end

function Tools.SetAtmosphereDensity(p)
	local lighting = game:GetService("Lighting")
	local atmosphere = lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = lighting
	end
	atmosphere.Density = p.density
	return "Set atmosphere density to " .. p.density
end

function Tools.CreateLight(p)
	local parent = resolvePath(p.parentPath)
	if not parent then
		error("Parent not found: " .. tostring(p.parentPath))
	end
	local light = Instance.new(p.type)
	light.Brightness = p.brightness or 1
	if p.color then
		light.Color = Color3.fromRGB(unpack(p.color))
	end
	light.Parent = parent
	return light:GetFullName()
end

-- Tag Tools
function Tools.AddTag(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	game:GetService("CollectionService"):AddTag(obj, p.tag)
	return "Added tag " .. p.tag
end

function Tools.RemoveTag(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	game:GetService("CollectionService"):RemoveTag(obj, p.tag)
	return "Removed tag " .. p.tag
end

function Tools.GetTags(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	return game:GetService("CollectionService"):GetTags(obj)
end

function Tools.HasTag(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	return game:GetService("CollectionService"):HasTag(obj, p.tag)
end

-- Attribute Tools
function Tools.SetAttribute(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	obj:SetAttribute(p.name, p.value)
	return "Set attribute " .. p.name .. " on " .. tostring(p.path)
end

function Tools.GetAttribute(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	return obj:GetAttribute(p.name)
end

function Tools.GetAttributes(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	return obj:GetAttributes()
end

-- Misc Tools
function Tools.KickPlayer(p)
	local player = game:GetService("Players"):FindFirstChild(p.username)
	if player then
		player:Kick(p.reason or "Kicked via MCP")
		return "Kicked " .. p.username
	end
	error("Player not found")
end

function Tools.SavePlace()
	local s, e = pcall(function()
		game:Save()
	end)
	if not s then
		return "Save failed: " .. tostring(e)
	end
	return "Save triggered"
end

function Tools.GetPlaceInfo()
	return { PlaceId = game.PlaceId, Name = "RunService" }
end

function Tools.GetService(p)
	local s, service = pcall(function()
		return game:GetService(p.service)
	end)
	if s then
		return "Service found: " .. service.Name
	end
	error("Service not found or invalid: " .. p.service)
end

function Tools.CloneInstance(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	local clone = obj:Clone()
	if p.parentPath then
		local parent = resolvePath(p.parentPath)
		if parent then
			clone.Parent = parent
		else
			error("Parent not found")
		end
	else
		clone.Parent = obj.Parent
	end
	return clone:GetFullName()
end

function Tools.RenameInstance(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	obj.Name = p.newName
	return "Renamed " .. tostring(p.path) .. " to " .. p.newName
end

function Tools.Chat(p)
	print("CHAT SYSTEM: " .. p.message)
	return "Logged to output: " .. p.message
end

-- Physics and Test Tools
function Tools.PivotTo(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	if obj:IsA("PVInstance") then
		local cf = CFrame.new(unpack(p.cframe))
		obj:PivotTo(cf)
		return "Pivoted " .. tostring(p.path)
	end
	error("Object is not a PVInstance")
end

function Tools.GetPivot(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	if obj:IsA("PVInstance") then
		local cf = obj:GetPivot()
		return { cf:GetComponents() }
	end
	error("Object is not a PVInstance")
end

function Tools.PlaySound(p)
	local sound = Instance.new("Sound")
	sound.SoundId = p.soundId
	sound.Volume = p.volume or 0.5
	local parent = p.parentPath and resolvePath(p.parentPath) or game:GetService("SoundService")
	sound.Parent = parent
	sound:Play()
	game:GetService("Debris"):AddItem(sound, 10)
	return "Playing sound " .. p.soundId
end

function Tools.StopSound(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	if obj:IsA("Sound") then
		obj:Stop()
		return "Stopped sound"
	end
	error("Object is not a Sound")
end

function Tools.GetDistance(p)
	local obj1 = resolvePath(p.path1)
	local obj2 = resolvePath(p.path2)
	if not obj1 or not obj2 then
		error("One or more objects not found")
	end

	local pos1 = (obj1:IsA("BasePart") and obj1.Position) or (obj1:IsA("PVInstance") and obj1:GetPivot().Position)
	local pos2 = (obj2:IsA("BasePart") and obj2.Position) or (obj2:IsA("PVInstance") and obj2:GetPivot().Position)

	if pos1 and pos2 then
		return (pos1 - pos2).Magnitude
	end
	error("Cannot determine position for one or more objects")
end

function Tools.HighlightObject(p)
	local obj = resolvePath(p.path)
	if not obj then
		error("Object not found: " .. tostring(p.path))
	end
	local highlight = Instance.new("Highlight")
	if p.color then
		highlight.FillColor = Color3.fromRGB(unpack(p.color))
	end
	highlight.Parent = obj
	if p.duration then
		game:GetService("Debris"):AddItem(highlight, p.duration)
	end
	return "Highlighted " .. tostring(p.path)
end

function Tools.StartPlay()
	task.spawn(function()
		log("STARTING_RUN_MODE...")
		game:GetService("StudioTestService"):ExecuteRunModeAsync()
	end)
	return "Run Mode Started"
end

-- TestService Tools
function Tools.TestCheck(p)
	game:GetService("TestService"):Check(p.condition, p.message)
	return "Test Check executed"
end

function Tools.TestMessage(p)
	game:GetService("TestService"):Message(p.message)
	return "Test Message sent"
end

function Tools.TestError(p)
	game:GetService("TestService"):Error(p.message)
	return "Test Error sent"
end

function Tools.TestRun()
	task.spawn(function()
		pcall(function()
			game:GetService("TestService"):RunAsync()
		end)
	end)
	return "TestService Run initiated"
end

local function handleCommand(cmd)
	log("Executing Tool: " .. tostring(cmd.method))
	local func = Tools[cmd.method]
	if func then
		local success, result = pcall(function()
			return func(cmd.params)
		end)
		sendResult(cmd.id, success, result, not success and result or nil)
	else
		sendResult(cmd.id, false, nil, "Method " .. tostring(cmd.method) .. " not found in Plugin V13")
	end
end

task.spawn(function()
	local context = getContext()
	if context == "client" then
		return
	end
	log("MCP_POLL_START: " .. context)
	while true do
		local success, response = pcall(function()
			return HttpService:GetAsync(SERVER_URL .. "/poll?context=" .. context)
		end)
		if success then
			local commands = HttpService:JSONDecode(response)
			for _, cmd in ipairs(commands) do
				handleCommand(cmd)
			end
		end
		task.wait(0.4) -- Slightly faster polling
	end
end)

log("Plugin Loaded. Port " .. SERVER_URL)
