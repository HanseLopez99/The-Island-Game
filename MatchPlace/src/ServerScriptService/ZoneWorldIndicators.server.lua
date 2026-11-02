local Workspace = game:GetService("Workspace")

local zonesFolder = Workspace:WaitForChild("MapZones")

local COLORS = {
	Neutral = Color3.fromRGB(190, 190, 190),
	Blue = Color3.fromRGB(40, 180, 255),
	Red = Color3.fromRGB(255, 75, 75),
}

local function getZoneColor(owner)
	return COLORS[owner] or COLORS.Neutral
end

local function createIndicator(zone)
	if not zone:IsA("BasePart") then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ZoneHologram"
	billboard.Adornee = zone
	-- Respect terrain and objects between the camera and the zone.
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 300
	billboard.Size = UDim2.fromOffset(170, 62)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 13, 0)
	billboard.Parent = zone

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.fromScale(1, 1)
	panel.BackgroundColor3 = Color3.fromRGB(10, 18, 25)
	panel.BackgroundTransparency = 0.25
	panel.BorderSizePixel = 0
	panel.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.18, 0)
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Name = "TeamStroke"
	stroke.Thickness = 2
	stroke.Transparency = 0.1
	stroke.Parent = panel

	local title = Instance.new("TextLabel")
	title.Name = "ZoneName"
	title.Position = UDim2.fromScale(0.05, 0.04)
	title.Size = UDim2.fromScale(0.9, 0.42)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.TextStrokeTransparency = 0.35
	title.Parent = panel

	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Position = UDim2.fromScale(0.05, 0.48)
	status.Size = UDim2.fromScale(0.9, 0.42)
	status.BackgroundTransparency = 1
	status.Font = Enum.Font.GothamBold
	status.TextScaled = true
	status.TextStrokeTransparency = 0.35
	status.Parent = panel

	local prompt = zone:FindFirstChildWhichIsA("ProximityPrompt")
	local capturingTeam

	local function update()
		local owner = zone:GetAttribute("Owner")
		local capturing = capturingTeam ~= nil
		local color = capturing
			and Color3.fromRGB(255, 230, 0)
			or getZoneColor(owner)

		local zoneLetter = string.sub(zone.Name, -1)
		title.Text = "ZONE " .. string.upper(zoneLetter)
		status.Text = capturing
			and "CAPTURING"
			or (owner and string.upper(owner .. " TEAM") or "NEUTRAL")
		status.TextColor3 = color
		stroke.Color = color
	end

	if prompt then
		prompt.PromptButtonHoldBegan:Connect(function(player)
			capturingTeam = player.Team and player.Team.Name or "Neutral"
			update()
		end)

		prompt.PromptButtonHoldEnded:Connect(function()
			capturingTeam = nil
			update()
		end)
	end

	zone:GetAttributeChangedSignal("Owner"):Connect(function()
		capturingTeam = nil
		update()
	end)
	update()
end

for _, zone in ipairs(zonesFolder:GetChildren()) do
	createIndicator(zone)
end

zonesFolder.ChildAdded:Connect(createIndicator)
