local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local compassGui = script.Parent
local compassFrame = compassGui:WaitForChild("CompassFrame")
local headingLabel = compassFrame:WaitForChild("HeadingLabel")
local markersFrame = compassFrame:WaitForChild("Markers")

local zoneDataModule = ReplicatedStorage:WaitForChild("ZoneData")
local zoneData = require(zoneDataModule)
local zoneUpdate = ReplicatedStorage:FindFirstChild("ZoneUpdate")

local CONFIG = {
	-- The visible compass window covers 180 degrees: 90 left and 90 right.
	VISIBLE_DEGREES = 180,
	DEGREE_STEP = 15,
	CARDINAL_FONT_SIZE = 18,
	DEGREE_FONT_SIZE = 12,
	ZONE_FONT_SIZE = 12,
	MARKER_Y_SCALE = 0.20,
	ZONE_Y_SCALE = 0.72,
	EDGE_PADDING = 24,
	DEFAULT_COLOR = Color3.fromRGB(255, 255, 255),
	BLUE_COLOR = Color3.fromRGB(0, 170, 255),
	RED_COLOR = Color3.fromRGB(255, 60, 60),
	CAPTURING_COLOR = Color3.fromRGB(255, 230, 0),
}

local CARDINALS = {
	[0] = "N",
	[45] = "NE",
	[90] = "E",
	[135] = "SE",
	[180] = "S",
	[225] = "SW",
	[270] = "W",
	[315] = "NW",
}

local markerObjects = {}
local zoneObjects = {}
local zoneColors = {}
local blinkingZones = {}

local function normalizeDegrees(degrees)
	return degrees % 360
end

local function shortestDelta(targetDegrees, cameraDegrees)
	local delta = normalizeDegrees(targetDegrees - cameraDegrees)
	if delta > 180 then
		delta -= 360
	end
	return delta
end

local function getCamera()
	return workspace.CurrentCamera
end

local function getCameraHeading(camera)
	local look = camera.CFrame.LookVector
	local worldAngle = math.deg(math.atan2(look.X, look.Z))
	return normalizeDegrees(360 - worldAngle)
end

local function getWorldPosition(value)
	if typeof(value) == "Vector3" then
		return value
	end

	if type(value) == "table" then
		if typeof(value.Position) == "Vector3" then
			return value.Position
		end

		if typeof(value.position) == "Vector3" then
			return value.position
		end
	end

	return nil
end

local function getZoneDisplayName(zoneName)
	local name = tostring(zoneName)
	local suffix = name:match("^Zone(.+)$")
	return suffix or name
end

local function createLabel(name, text, fontSize, yScale, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Size = UDim2.fromOffset(56, 22)
	label.Position = UDim2.new(0.5, 0, yScale, 0)
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = color or CONFIG.DEFAULT_COLOR
	label.TextSize = fontSize
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Visible = false
	label.ZIndex = 2
	label.Parent = markersFrame
	return label
end

local function createCompassMarkers()
	for heading = 0, 345, CONFIG.DEGREE_STEP do
		local text = CARDINALS[heading] or tostring(heading)
		local marker = createLabel(
			"Compass_" .. heading,
			text,
			CARDINALS[heading] and CONFIG.CARDINAL_FONT_SIZE or CONFIG.DEGREE_FONT_SIZE,
			CONFIG.MARKER_Y_SCALE,
			CONFIG.DEFAULT_COLOR
		)

		markerObjects[heading] = marker
	end
end

local function createZoneMarkers()
	for zoneName, zoneValue in pairs(zoneData) do
		if getWorldPosition(zoneValue) then
			local label = createLabel(
				"Zone_" .. tostring(zoneName),
				getZoneDisplayName(zoneName),
				CONFIG.ZONE_FONT_SIZE,
				CONFIG.ZONE_Y_SCALE,
				zoneColors[zoneName] or CONFIG.DEFAULT_COLOR
			)

			zoneObjects[zoneName] = label
		end
	end
end

local function setZoneColor(zoneName, color)
	local label = zoneObjects[zoneName]
	if not label then
		return
	end

	zoneColors[zoneName] = color
	if not blinkingZones[zoneName] then
		label.TextColor3 = color
	end
end

local function colorForZoneUpdate(data)
	if data.state ~= "Capture" and data.state ~= "Captured" then
		return CONFIG.CAPTURING_COLOR
	end

	if data.state == "Capture" then
		return CONFIG.DEFAULT_COLOR
	end

	if data.color == "Blue" then
		return CONFIG.BLUE_COLOR
	end

	if data.color == "Red" then
		return CONFIG.RED_COLOR
	end

	if typeof(data.color) == "Color3" then
		return data.color
	end

	return CONFIG.DEFAULT_COLOR
end

local function stopZoneBlink(zoneName)
	blinkingZones[zoneName] = false
	local label = zoneObjects[zoneName]
	if label then
		label.TextColor3 = zoneColors[zoneName] or CONFIG.DEFAULT_COLOR
	end
end

local function startZoneBlink(zoneName)
	if blinkingZones[zoneName] then
		return
	end

	blinkingZones[zoneName] = true
	task.spawn(function()
		local visible = true
		while blinkingZones[zoneName] do
			local label = zoneObjects[zoneName]
			if not label then
				break
			end

			visible = not visible
			label.TextColor3 = visible and CONFIG.CAPTURING_COLOR or CONFIG.DEFAULT_COLOR
			task.wait(0.25)
		end
	end)
end

local function applyZoneUpdate(data)
	if type(data) ~= "table" or not data.zone then
		return
	end

	local zoneName = data.zone
	local color = colorForZoneUpdate(data)
	zoneColors[zoneName] = color

	if data.state ~= "Capture" and data.state ~= "Captured" then
		startZoneBlink(zoneName)
		return
	end

	stopZoneBlink(zoneName)
	setZoneColor(zoneName, color)
end

local function updateMarker(label, targetHeading, cameraHeading, pixelsPerDegree)
	local delta = shortestDelta(targetHeading, cameraHeading)
	local visible = math.abs(delta) <= CONFIG.VISIBLE_DEGREES / 2 + CONFIG.EDGE_PADDING / pixelsPerDegree

	label.Position = UDim2.new(
		0.5,
		delta * pixelsPerDegree,
		label.Position.Y.Scale,
		label.Position.Y.Offset
	)
	label.Visible = visible
end

local function updateCompassMarkers(camera, cameraHeading, pixelsPerDegree)
	for targetHeading, label in pairs(markerObjects) do
		updateMarker(label, targetHeading, cameraHeading, pixelsPerDegree)
	end

	local cameraPosition = camera.CFrame.Position
	for zoneName, label in pairs(zoneObjects) do
		local position = getWorldPosition(zoneData[zoneName])
		if position then
			local offset = position - cameraPosition
			if offset.Magnitude > 0.001 then
				local worldAngle = math.deg(math.atan2(offset.X, offset.Z))
				local zoneHeading = normalizeDegrees(360 - worldAngle)
				updateMarker(label, zoneHeading, cameraHeading, pixelsPerDegree)
			else
				label.Visible = false
			end
		end
	end
end

local function updateHeadingLabel(cameraHeading)
	local roundedHeading = math.floor(cameraHeading + 0.5) % 360
	headingLabel.Text = string.format("%d°", roundedHeading)
end

createCompassMarkers()
createZoneMarkers()

if zoneUpdate and zoneUpdate:IsA("RemoteEvent") then
	zoneUpdate.OnClientEvent:Connect(applyZoneUpdate)
end

RunService.RenderStepped:Connect(function()
	local camera = getCamera()
	if not camera then
		return
	end

	local frameWidth = compassFrame.AbsoluteSize.X
	if frameWidth <= 0 then
		return
	end

	local pixelsPerDegree = frameWidth / CONFIG.VISIBLE_DEGREES
	local cameraHeading = getCameraHeading(camera)

	updateHeadingLabel(cameraHeading)
	updateCompassMarkers(camera, cameraHeading, pixelsPerDegree)
end)