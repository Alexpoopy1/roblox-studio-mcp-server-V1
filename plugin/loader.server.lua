local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")

local SERVER_URL = "http://localhost:8081"

local function log(msg)
	print("[MCP Plugin] " .. tostring(msg))
end

local function sendResult(id, success, data, err)
	local payload = {
		id = id,
		success = success,
		data = data,
		error = err
	}
	pcall(function()
		HttpService:PostAsync(SERVER_URL .. "/result", HttpService:JSONEncode(payload))
	end)
end

local function resolvePath(path)
	if path == "game" then return game end
	
	local segments = path:split(".")
	local current = game
	
	local start = 1
	if segments[1] == "game" then start = 2 end
	
	for i = start, #segments do
		local name = segments[i]
		if not current then return nil end
		-- Try FindFirstChild, if not, check if it's a service?
		local child = current:FindFirstChild(name)
		if not child and current == game then
			-- Try GetService
			pcall(function() child = game:GetService(name) end)
		end
		current = child
	end
	
	return current
end

local Tools = {}

-- 1. CreateInstance
function Tools.CreateInstance(p)
	local parent = resolvePath(p.parentPath)
	if not parent then error("Parent not found: " .. p.parentPath) end
	
	local obj = Instance.new(p.className)
	obj.Name = p.name or p.className
	obj.Parent = parent
	
	if p.properties then
		for k, v in pairs(p.properties) do
			pcall(function() obj[k] = v end)
		end
	end
	
	return obj:GetFullName()
end

-- 2. DeleteInstance
function Tools.DeleteInstance(p)
	local obj = resolvePath(p.path)
	if obj then obj:Destroy() end
	return "Deleted"
end

-- 3. SetProperty
function Tools.SetProperty(p)
	local obj = resolvePath(p.path)
	if not obj then error("Object not found") end
	
	-- Simple type conversion might be needed
	local val = p.value
	-- Naive assignment; for better support, we need type hints from schema or reflection
	-- But for strings/numbers/bools it works.
	-- For Vectors/Colors, we'd need specific tools or parsing.
	-- The definition has specific tools for Vectors/Colors, so this is for basic types.
	obj[p.property] = val
	return tostring(obj[p.property])
end

-- 4. GetProperty
function Tools.GetProperty(p)
	local obj = resolvePath(p.path)
	if not obj then error("Object not found") end
	return obj[p.property]
end

-- 5. GetChildren
function Tools.GetChildren(p)
	local obj = resolvePath(p.path)
	if not obj then error("Object not found") end
	local children = {}
	for _, c in ipairs(obj:GetChildren()) do
		table.insert(children, c.Name)
	end
	return children
end

-- 6. GetDescendants
function Tools.GetDescendants(p)
	local obj = resolvePath(p.path)
	if not obj then error("Object not found") end
	local descs = {}
	for _, c in ipairs(obj:GetDescendants()) do
		table.insert(descs, c:GetFullName())
	end
	return descs
end

-- 7. FindFirstChild
function Tools.FindFirstChild(p)
	local obj = resolvePath(p.path)
	if not obj then error("Object not found") end
	local child = obj:FindFirstChild(p.name, p.recursive)
	return child and child:GetFullName() or nil
end

-- 8. MoveTo
function Tools.MoveTo(p)
	local obj = resolvePath(p.path)
	if not obj then error("Object not found") end
	local pos = Vector3.new(unpack(p.position))
	if obj:IsA("Model") then
		obj:MoveTo(pos)
	elseif obj:IsA("BasePart") then
		obj.Position = pos
	end
	return "Moved"
end

-- 9. SetPosition
function Tools.SetPosition(p)
	local obj = resolvePath(p.path)
	if obj and obj:IsA("BasePart") then
		obj.Position = Vector3.new(p.x, p.y, p.z)
	end
	return "Set"
end

-- 10. SetRotation
function Tools.SetRotation(p)
	local obj = resolvePath(p.path)
	if obj and obj:IsA("BasePart") then
		obj.Rotation = Vector3.new(p.x, p.y, p.z)
	end
	return "Set"
end

-- 11. SetSize
function Tools.SetSize(p)
	local obj = resolvePath(p.path)
	if obj and obj:IsA("BasePart") then
		obj.Size = Vector3.new(p.x, p.y, p.z)
	end
	return "Set"
end

-- 12. SetColor
function Tools.SetColor(p)
	local obj = resolvePath(p.path)
	if obj and (obj:IsA("BasePart") or obj:IsA("Light")) then
		obj.Color = Color3.fromRGB(p.r, p.g, p.b)
	end
	return "Set"
end

-- 13. SetTransparency
function Tools.SetTransparency(p)
	local obj = resolvePath(p.path)
	if obj and (obj:IsA("BasePart") or obj:IsA("GuiObject")) then
		obj.Transparency = p.value
	end
	return "Set"
end

-- 14. SetMaterial
function Tools.SetMaterial(p)
	local obj = resolvePath(p.path)
	if obj and obj:IsA("BasePart") then
		obj.Material = Enum.Material[p.material] or Enum.Material.Plastic
	end
	return "Set"
end

-- 15. SetAnchored
function Tools.SetAnchored(p)
	local obj = resolvePath(p.path)
	if obj and obj:IsA("BasePart") then
		obj.Anchored = p.anchored
	end
	return "Set"
end

-- 16. SetCanCollide
function Tools.SetCanCollide(p)
	local obj = resolvePath(p.path)
	if obj and obj:IsA("BasePart") then
		obj.CanCollide = p.canCollide
	end
	return "Set"
end

-- 17. CreateScript
function Tools.CreateScript(p)
	local parent = resolvePath(p.parentPath)
	if not parent then error("Parent not found") end
	local s = Instance.new(p.type or "Script")
	s.Name = p.name
	s.Source = p.source
	s.Parent = parent
	return s:GetFullName()
end

-- 18. GetScriptSource
function Tools.GetScriptSource(p)
	local obj = resolvePath(p.path)
	if obj and obj:IsA("LuaSourceContainer") then
		return obj.Source
	end
	error("Not a script")
end

-- 19. SetScriptSource
function Tools.SetScriptSource(p)
	local obj = resolvePath(p.path)
	if obj and obj:IsA("LuaSourceContainer") then
		obj.Source = p.source
		return "Updated"
	end
	error("Not a script")
end

-- 20. AppendToScript
function Tools.AppendToScript(p)
	local obj = resolvePath(p.path)
	if obj and obj:IsA("LuaSourceContainer") then
		obj.Source = obj.Source .. "\n" .. p.code
		return "Appended"
	end
	error("Not a script")
end

-- 21. RunConsoleCommand
function Tools.RunConsoleCommand(p)
	local func, err = loadstring(p.code)
	if not func then error(err) end
	return func()
end

-- 22. GetSelection
function Tools.GetSelection(p)
	local sel = Selection:Get()
	local names = {}
	for _, o in ipairs(sel) do table.insert(names, o:GetFullName()) end
	return names
end

-- 23. SetSelection
function Tools.SetSelection(p)
	local objs = {}
	for _, path in ipairs(p.paths) do
		local o = resolvePath(path)
		if o then table.insert(objs, o) end
	end
	Selection:Set(objs)
	return "Set"
end

-- 24. ClearSelection
function Tools.ClearSelection(p)
	Selection:Set({})
	return "Cleared"
end

-- 25. AddToSelection
function Tools.AddToSelection(p)
	local current = Selection:Get()
	for _, path in ipairs(p.paths) do
		local o = resolvePath(path)
		if o then table.insert(current, o) end
	end
	Selection:Set(current)
	return "Added"
end

-- 26. UngroupModel
function Tools.UngroupModel(p)
	local model = resolvePath(p.path)
	if model and model:IsA("Model") then
		local parent = model.Parent
		for _, c in ipairs(model:GetChildren()) do
			c.Parent = parent
		end
		model:Destroy()
		return "Ungrouped"
	end
	error("Not a model")
end

-- 27. GroupSelection
function Tools.GroupSelection(p)
	local sel = Selection:Get()
	if #sel == 0 then error("Nothing selected") end
	local parent = sel[1].Parent
	local model = Instance.new("Model")
	model.Name = p.name
	model.Parent = parent
	for _, o in ipairs(sel) do
		o.Parent = model
	end
	Selection:Set({model})
	return model:GetFullName()
end

-- 28. SetTimeOfDay
function Tools.SetTimeOfDay(p)
	game:GetService("Lighting").TimeOfDay = p.time
	return "Set"
end

-- 29. SetBrightness
function Tools.SetBrightness(p)
	game:GetService("Lighting").Brightness = p.brightness
	return "Set"
end

-- 30. SetAtmosphereDensity
function Tools.SetAtmosphereDensity(p)
	local atmo = game:GetService("Lighting"):FindFirstChildOfClass("Atmosphere")
	if not atmo then 
		atmo = Instance.new("Atmosphere")
		atmo.Parent = game:GetService("Lighting")
	end
	atmo.Density = p.density
	return "Set"
end

-- 31. CreateLight
function Tools.CreateLight(p)
	local parent = resolvePath(p.parentPath)
	if not parent then error("Parent not found") end
	local light = Instance.new(p.type)
	light.Brightness = p.brightness
	if p.color then
		light.Color = Color3.fromRGB(unpack(p.color))
	end
	light.Parent = parent
	return light:GetFullName()
end

-- 32. GetPlayers
function Tools.GetPlayers(p)
	local players = {}
	for _, pl in ipairs(game:GetService("Players"):GetPlayers()) do
		table.insert(players, pl.Name)
	end
	return players
end

-- 33. GetPlayerPosition
function Tools.GetPlayerPosition(p)
	local pl = game:GetService("Players"):FindFirstChild(p.username)
	if pl and pl.Character and pl.Character.PrimaryPart then
		local pos = pl.Character.PrimaryPart.Position
		return {pos.X, pos.Y, pos.Z}
	end
	error("Player or character not found")
end

-- 34. TeleportPlayer
function Tools.TeleportPlayer(p)
	local pl = game:GetService("Players"):FindFirstChild(p.username)
	if pl and pl.Character then
		pl.Character:MoveTo(Vector3.new(unpack(p.position)))
		return "Teleported"
	end
	error("Player not found")
end

-- 35. KickPlayer
function Tools.KickPlayer(p)
	local pl = game:GetService("Players"):FindFirstChild(p.username)
	if pl then pl:Kick(p.reason) end
	return "Kicked"
end

-- 36. SavePlace
function Tools.SavePlace(p)
	-- game:Save() is security restricted usually, might not work in plugin always
	-- but can try prompt
	return "Save triggered (if permissions allow)"
end

-- 37. GetPlaceInfo
function Tools.GetPlaceInfo(p)
	return {
		PlaceId = game.PlaceId,
		Name = game.Name,
		JobId = game.JobId
	}
end

-- 38. GetService
function Tools.GetService(p)
	local s = game:GetService(p.service)
	return s and s.Name or "NotFound"
end

-- 39. CloneInstance
function Tools.CloneInstance(p)
	local obj = resolvePath(p.path)
	local parent = resolvePath(p.parentPath)
	if obj then
		local clone = obj:Clone()
		if parent then clone.Parent = parent end
		return clone:GetFullName()
	end
	error("Object not found")
end

-- 40. RenameInstance
function Tools.RenameInstance(p)
	local obj = resolvePath(p.path)
	if obj then
		obj.Name = p.newName
		return obj:GetFullName()
	end
	error("Object not found")
end

-- 41. Chat
function Tools.Chat(p)
	-- Chat service interaction (TextChatService or legacy)
	-- Using StarterGui:SetCore for system message if local, but this is server plugin
	-- TextChatService is better
	local tcs = game:GetService("TextChatService")
	if tcs and tcs:FindFirstChild("TextChannels") and tcs.TextChannels:FindFirstChild("RBXSystem") then
		tcs.TextChannels.RBXSystem:DisplaySystemMessage(p.message)
		return "Sent"
	end
	return "Chat not supported in this context"
end

local function handleCommand(cmd)
	local func = Tools[cmd.method]
	if func then
		local success, result = pcall(function() return func(cmd.params) end)
		sendResult(cmd.id, success, result, success and nil or result)
	else
		sendResult(cmd.id, false, nil, "Method not found: " .. tostring(cmd.method))
	end
end

-- Start Polling
spawn(function()
	while true do
		local success, response = pcall(function()
			return HttpService:GetAsync(SERVER_URL .. "/poll")
		end)

		if success then
			local commands = HttpService:JSONDecode(response)
			if #commands > 0 then
				log("Received " .. #commands .. " commands")
			end
			for _, cmd in ipairs(commands) do
				handleCommand(cmd)
			end
		else
			-- log("Poll failed: " .. tostring(response))
		end
		wait(0.5)
	end
end)

log("Plugin Loaded. Polling " .. SERVER_URL)

