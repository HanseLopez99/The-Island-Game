--[[
    DeveloperToolsController.client.lua (LocalScript)
    Path: StarterPlayer → StarterPlayerScripts
    Parent: StarterPlayerScripts
    Properties:
        Disabled: false
    Exported: 2026-09-02 16:23:32
]]
-- StarterPlayerScripts/DeveloperToolsController.client
-- Press F10 to open/close the developer panel.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")

local player = Players.LocalPlayer

-- Safety gate: set to false only while testing in Studio.
local STUDIO_ONLY = true
local ALLOWED_USER_IDS = {
	-- [123456789] = true,
}

local RunService = game:GetService("RunService")
if STUDIO_ONLY and not RunService:IsStudio() and not ALLOWED_USER_IDS[player.UserId] then
	return
end

local WeaponData = require(ReplicatedStorage:WaitForChild("WeaponData"))
local ViewportRenderer = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ViewportRenderer"))
local weaponsFolder = ReplicatedStorage:WaitForChild("Weapons")

local state = {
	weaponName = nil,
	config = nil,
	viewport = nil,
	valueLabels = {},
	sliders = {},
	previousMouseBehavior = UserInputService.MouseBehavior,
	previousMouseIconEnabled = UserInputService.MouseIconEnabled,
	mousUnlockBound = false,
	previousCameraType = nil,
	previousCameraSubject = nil,
	previousCameraCFrame = nil,
	previousCameraFieldOfView = nil,
}

local function setInputMode(panelVisible)
	if panelVisible then
		state.previousMouseBehavior = UserInputService.MouseBehavior
		state.previousMouseIconEnabled = UserInputService.MouseIconEnabled
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		player:SetAttribute("DeveloperToolsOpen", true)
		local camera = workspace.CurrentCamera
		if camera then
			state.previousCameraType = camera.CameraType
			state.previousCameraSubject = camera.CameraSubject
			state.previousCameraCFrame = camera.CFrame
			state.previousCameraFieldOfView = camera.FieldOfView
			camera.CameraType = Enum.CameraType.Scriptable
		end
		if not state.mousUnlockBound then
			RunService:BindToRenderStep("DeveloperTools_UnlockMouse", Enum.RenderPriority.Last.Value, function()
				if state.root and state.root.Visible then
					UserInputService.MouseBehavior = Enum.MouseBehavior.Default
					UserInputService.MouseIconEnabled = true
					local currentCamera = workspace.CurrentCamera
					if currentCamera then
						currentCamera.CameraType = Enum.CameraType.Scriptable
					end
				end
			end)
			state.mousUnlockBound = true
		end
	else
		if state.mousUnlockBound then
			RunService:UnbindFromRenderStep("DeveloperTools_UnlockMouse")
			state.mousUnlockBound = false
		end
		player:SetAttribute("DeveloperToolsOpen", false)
		local camera = workspace.CurrentCamera
		if camera and state.previousCameraType then
			camera.CameraType = state.previousCameraType
			camera.CameraSubject = state.previousCameraSubject
			if state.previousCameraCFrame then camera.CFrame = state.previousCameraCFrame end
			if state.previousCameraFieldOfView then camera.FieldOfView = state.previousCameraFieldOfView end
		end
		UserInputService.MouseBehavior = state.previousMouseBehavior
		UserInputService.MouseIconEnabled = state.previousMouseIconEnabled
	end
end

local COLORS = {
	background = Color3.fromRGB(13, 17, 24),
	panel = Color3.fromRGB(22, 28, 39),
	panel2 = Color3.fromRGB(29, 37, 52),
	text = Color3.fromRGB(235, 241, 250),
	muted = Color3.fromRGB(150, 164, 184),
	accent = Color3.fromRGB(74, 161, 255),
	accent2 = Color3.fromRGB(48, 105, 178),
	border = Color3.fromRGB(58, 72, 94),
}

local function create(className, properties, parent)
	local object = Instance.new(className)
	for key, value in pairs(properties or {}) do
		object[key] = value
	end
	object.Parent = parent
	return object
end

local function round(parent, radius)
	create("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, parent)
end

local function stroke(parent, color, thickness)
	create("UIStroke", { Color = color or COLORS.border, Thickness = thickness or 1 }, parent)
end

local function formatNumber(value)
	return string.format("%.3f", value):gsub("0+$", ""):gsub("%.$", "0")
end

local function makeConfig(source)
	local sourceOffset = source.Offset or Vector3.zero
	local sourceRotation = source.Rotation or Vector3.zero
	local function clampAngle(value)
		local normalized = ((value + 180) % 360) - 180
		return normalized
	end
	local function clampVector(vector, minimum, maximum)
		return Vector3.new(
			math.clamp(vector.X, minimum, maximum),
			math.clamp(vector.Y, minimum, maximum),
			math.clamp(vector.Z, minimum, maximum)
		)
	end

	return {
		Distance = math.clamp(source.Distance or 2, 0.2, 20),
		Offset = clampVector(sourceOffset, -2, 2),
		Rotation = Vector3.new(
			clampAngle(sourceRotation.X),
			clampAngle(sourceRotation.Y),
			clampAngle(sourceRotation.Z)
		),
		Slot = source.Slot,
		DisplayName = source.DisplayName,
	}
end

local function setConfigValue(path, value)
	if path == "Distance" then
		state.config.Distance = value
	elseif path:sub(1, 6) == "Offset" then
		local vector = state.config.Offset
		local axis = path:sub(7, 7)
		state.config.Offset = Vector3.new(axis == "X" and value or vector.X, axis == "Y" and value or vector.Y, axis == "Z" and value or vector.Z)
	elseif path:sub(1, 8) == "Rotation" then
		local vector = state.config.Rotation
		local axis = path:sub(9, 9)
		state.config.Rotation = Vector3.new(axis == "X" and value or vector.X, axis == "Y" and value or vector.Y, axis == "Z" and value or vector.Z)
	end
end

local function getConfigValue(path)
	if path == "Distance" then return state.config.Distance end
	local vector = path:sub(1, 6) == "Offset" and state.config.Offset or state.config.Rotation
	local axis = path:sub(path:sub(1, 6) == "Offset" and 7 or 9, path:sub(1, 6) == "Offset" and 7 or 9)
	return axis == "X" and vector.X or axis == "Y" and vector.Y or vector.Z
end

local function render()
	local tool = weaponsFolder:FindFirstChild(state.weaponName)
	if tool and state.viewport then
		local ok, renderError = pcall(function()
			ViewportRenderer.RenderTool(state.viewport, tool, state.config)
		end)
		if not ok then
			warn("DeveloperTools: failed to render " .. tostring(state.weaponName) .. ": " .. tostring(renderError))
		end
	elseif state.viewport then
		state.viewport:ClearAllChildren()
		warn("DeveloperTools: missing Tool in ReplicatedStorage.Weapons: " .. tostring(state.weaponName))
	end
end

local function refreshControls()
	for path, label in pairs(state.valueLabels) do
		label.Text = formatNumber(getConfigValue(path))
	end
	for path, slider in pairs(state.sliders) do
		local minValue, maxValue = slider.MinValue, slider.MaxValue
		local alpha = math.clamp((getConfigValue(path) - minValue) / (maxValue - minValue), 0, 1)
		slider.Knob.Position = UDim2.fromScale(alpha, 0.5)
		slider.Fill.Size = UDim2.fromScale(alpha, 1)
	end
end

local buildSnippet

local function createSlider(parent, path, title, minValue, maxValue, suffix)
	local row = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 46) }, parent)
	create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(0.36, 0, 0, 20), Text = title, TextColor3 = COLORS.text, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, row)
	local valueLabel = create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromScale(0.81, 0), Size = UDim2.new(0.19, 0, 0, 20), TextColor3 = COLORS.muted, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right }, row)
	state.valueLabels[path] = valueLabel
	local track = create("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.37, 0.56), Size = UDim2.new(0.41, 0, 0, 18), BackgroundTransparency = 1, Active = true, Selectable = true }, row)
	round(track, 4)
	local trackVisual = create("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, 5), BackgroundColor3 = COLORS.panel2, Active = false }, track)
	round(trackVisual, 4)
	local fill = create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = COLORS.accent }, trackVisual)
	round(fill, 4)
	local knob = create("TextButton", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(18, 18), BackgroundColor3 = COLORS.text, Text = "", AutoButtonColor = false, Active = true, Selectable = true }, track)
	round(knob, 8)
	local slider = { MinValue = minValue, MaxValue = maxValue, Knob = knob, Fill = fill, Track = track }
	state.sliders[path] = slider
	local dragging = false
	local function update(inputX)
		local alpha = math.clamp((inputX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		local value = minValue + (maxValue - minValue) * alpha
		value = math.round(value * 1000) / 1000
		setConfigValue(path, value)
		refreshControls()
		render()
		if state.snippet then
			state.snippet.Text = buildSnippet()
		end
	end
	knob.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true end end)
	UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
	UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input.Position.X) end end)
	track.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then update(input.Position.X) end end)
	valueLabel.Text = formatNumber(getConfigValue(path)) .. (suffix or "")
end

buildSnippet = function()
	local cfg = state.config
	return string.format([[%s = {
	Slot = %s,
	DisplayName = %q,
	Distance = %s,
	Offset = Vector3.new(%s, %s, %s),
	Rotation = Vector3.new(%s, %s, %s),
},]], state.weaponName, tostring(cfg.Slot or "nil"), cfg.DisplayName or state.weaponName, formatNumber(cfg.Distance), formatNumber(cfg.Offset.X), formatNumber(cfg.Offset.Y), formatNumber(cfg.Offset.Z), formatNumber(cfg.Rotation.X), formatNumber(cfg.Rotation.Y), formatNumber(cfg.Rotation.Z))
end

local function selectWeapon(name)
	local source = WeaponData[name]
	if not source then return end
	state.weaponName = name
	state.config = makeConfig(source)
	state.weaponButton.Text = source.DisplayName or name
	refreshControls()
	state.snippet.Text = buildSnippet()
	render()
end

local function buildUI()
	local first
	for name, config in pairs(WeaponData) do
		if type(config) == "table" and (not first or (config.Slot or 999) < (WeaponData[first].Slot or 999)) then
			first = name
		end
	end
	if first then
		-- Sliders read state.config while they are being created, so initialize
		-- the first weapon before building the controls.
		state.weaponName = first
		state.config = makeConfig(WeaponData[first])
	else
		-- Keep the panel usable even if WeaponData is temporarily empty.
		state.weaponName = "NoWeapon"
		state.config = makeConfig({})
	end

	local gui = create("ScreenGui", { Name = "DeveloperTools", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 100 }, player:WaitForChild("PlayerGui"))
	local root = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(920, 570), BackgroundColor3 = COLORS.background, Visible = false }, gui)
	state.root = root
	round(root, 12); stroke(root, COLORS.border, 1)
	create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(24, 17), Size = UDim2.new(1, -48, 0, 28), Text = "DEVELOPER TOOLS", TextColor3 = COLORS.text, Font = Enum.Font.GothamBold, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left }, root)
	create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(24, 45), Size = UDim2.new(1, -48, 0, 18), Text = "Weapon calibration workspace  •  F10 to toggle", TextColor3 = COLORS.muted, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left }, root)
	local tabs = create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 78), Size = UDim2.new(1, -40, 0, 34) }, root)
	local tabLayout = create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }, tabs)
	for _, tabName in ipairs({ "🔫  Weapon Viewer", "🎥  ViewModel", "🧭  Compass" }) do
		local tab = create("TextButton", { BackgroundColor3 = tabName:find("Weapon") and COLORS.accent2 or COLORS.panel2, Size = UDim2.fromOffset(150, 32), Text = tabName, TextColor3 = COLORS.text, Font = Enum.Font.GothamMedium, TextSize = 12, AutoButtonColor = false }, tabs)
		round(tab, 6)
	end
	local left = create("Frame", { Position = UDim2.fromOffset(20, 125), Size = UDim2.new(0.51, -26, 1, -145), BackgroundColor3 = COLORS.panel }, root); round(left, 8); stroke(left)
	local right = create("ScrollingFrame", { Position = UDim2.new(0.51, 6, 0, 125), Size = UDim2.new(0.49, -26, 1, -145), BackgroundColor3 = COLORS.panel, BorderSizePixel = 0, CanvasSize = UDim2.fromOffset(0, 0), ScrollBarThickness = 4 }, root); round(right, 8); stroke(right)
	local viewport = create("ViewportFrame", { Position = UDim2.fromOffset(16, 47), Size = UDim2.new(1, -32, 1, -63), BorderSizePixel = 0 }, left); round(viewport, 6); state.viewport = viewport
	create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 14), Size = UDim2.new(1, -32, 0, 20), Text = "LIVE PREVIEW", TextColor3 = COLORS.muted, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left }, left)
	local padding = create("UIPadding", { PaddingTop = UDim.new(0, 16), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16), PaddingBottom = UDim.new(0, 16) }, right)
	local list = create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, right)
	state.weaponButton = create("TextButton", { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = COLORS.panel2, Text = "Select weapon", TextColor3 = COLORS.text, Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, right); round(state.weaponButton, 6); stroke(state.weaponButton)
	state.weaponButton.Activated:Connect(function()
		local names = {}
		for name, config in pairs(WeaponData) do if type(config) == "table" then table.insert(names, name) end end
		table.sort(names, function(a, b) return (WeaponData[a].Slot or 999) < (WeaponData[b].Slot or 999) end)
		if #names == 0 then return end
		local index = table.find(names, state.weaponName) or 0
		local nextName = names[index % #names + 1]
		selectWeapon(nextName)
	end)
	create("TextLabel", { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "CAMERA", TextColor3 = COLORS.muted, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left }, right)
	createSlider(right, "Distance", "Distance", 0.2, 20, "")
	create("TextLabel", { LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "OFFSET", TextColor3 = COLORS.muted, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left }, right)
	createSlider(right, "OffsetX", "Offset X", -2, 2, "")
	createSlider(right, "OffsetY", "Offset Y", -2, 2, "")
	createSlider(right, "OffsetZ", "Offset Z", -2, 2, "")
	create("TextLabel", { LayoutOrder = 8, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "ROTATION", TextColor3 = COLORS.muted, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left }, right)
	createSlider(right, "RotationX", "Rotation X", -180, 180, "°")
	createSlider(right, "RotationY", "Rotation Y", -180, 180, "°")
	createSlider(right, "RotationZ", "Rotation Z", -180, 180, "°")
	local actions = create("Frame", { LayoutOrder = 12, Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1 }, right)
	local reset = create("TextButton", { Size = UDim2.fromScale(0.48, 1), BackgroundColor3 = COLORS.panel2, Text = "Reset", TextColor3 = COLORS.text, Font = Enum.Font.GothamMedium, TextSize = 12 }, actions); round(reset, 6)
	local copy = create("TextButton", { Position = UDim2.fromScale(0.52, 0), Size = UDim2.fromScale(0.48, 1), BackgroundColor3 = COLORS.accent2, Text = "Copy snippet", TextColor3 = COLORS.text, Font = Enum.Font.GothamMedium, TextSize = 12 }, actions); round(copy, 6)
	state.snippet = create("TextBox", { LayoutOrder = 13, Size = UDim2.new(1, 0, 0, 116), BackgroundColor3 = COLORS.background, TextColor3 = COLORS.text, PlaceholderText = "Generated WeaponData snippet", Text = "", ClearTextOnFocus = false, MultiLine = true, TextWrapped = false, Font = Enum.Font.Code, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, right); round(state.snippet, 6); stroke(state.snippet)
	local hint = create("TextLabel", { LayoutOrder = 14, Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Text = "Copy uses the TextBox selection. In Studio, click the snippet and press Ctrl/Cmd+A, then Ctrl/Cmd+C.", TextColor3 = COLORS.muted, Font = Enum.Font.Gotham, TextSize = 10, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, right)
	reset.MouseButton1Click:Connect(function() selectWeapon(state.weaponName) end)
	copy.MouseButton1Click:Connect(function() state.snippet:CaptureFocus(); state.snippet.SelectionStart = 1; state.snippet.CursorPosition = #state.snippet.Text + 1 end)
	list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() right.CanvasSize = UDim2.fromOffset(0, list.AbsoluteContentSize.Y + 32) end)
	if first then selectWeapon(first) end
end

local function togglePanel()
	if state.root then
		state.root.Visible = not state.root.Visible
		setInputMode(state.root.Visible)
	end
end

local lastChatToggle = 0
local function toggleFromChat(message)
	if os.clock() - lastChatToggle < 0.2 then return end
	local command = string.lower(tostring(message)):match("^%s*(/[%w_]+)")
	if command == "/devtools" or command == "/developer" then
		lastChatToggle = os.clock()
		togglePanel()
	end
end

buildUI()

-- Register proper commands for the modern TextChatService. Listening only to
-- MessageReceived is unreliable because chat commands are handled separately.
local developerCommand = TextChatService:FindFirstChild("DeveloperToolsCommand")
if not developerCommand then
	developerCommand = Instance.new("TextChatCommand")
	developerCommand.Name = "DeveloperToolsCommand"
	developerCommand.Parent = TextChatService
end
developerCommand.PrimaryAlias = "/devtools"
developerCommand.SecondaryAlias = "/developer"
developerCommand.Triggered:Connect(function(textSource)
	if textSource and textSource.UserId == player.UserId then
		lastChatToggle = os.clock()
		togglePanel()
	end
end)

-- Fallbacks for chat configurations where TextChatCommand is not created on
-- the client. These are intentionally filtered to the local player's text.
player.Chatted:Connect(toggleFromChat)
TextChatService.MessageReceived:Connect(function(message)
	local source = message.TextSource
	if source and source.UserId == player.UserId then
		toggleFromChat(message.Text)
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if (input.KeyCode == Enum.KeyCode.F10 or input.KeyCode == Enum.KeyCode.F9) and state.root then
		togglePanel()
		return
	end
	if processed then return end
end)

-- Legacy chat fallback for experiences that still use Player.Chatted.
if TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService then
	player.Chatted:Connect(function(message)
		local command = string.lower(message):match("^%s*(/[%w_]+)")
		if command == "/devtools" or command == "/developer" then
			togglePanel()
		end
	end)
end