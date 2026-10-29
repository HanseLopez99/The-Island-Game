local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local remote =
	ReplicatedStorage:WaitForChild("ZoneUpdate")

local container =
	script.Parent:WaitForChild("ZoneContainer")

--------------------------------------------------
-- 📍 ZONAS
--------------------------------------------------

local zones = {

	ZoneA = container.ZoneA,
	ZoneB = container.ZoneB,
	ZoneC = container.ZoneC,
	ZoneD = container.ZoneD,
	ZoneE = container.ZoneE,
	ZoneF = container.ZoneF,

}

local announcementFadeTask
local announcement = Instance.new("TextLabel")
announcement.Name = "ZoneAnnouncement"
announcement.AnchorPoint = Vector2.new(0.5, 0.5)
announcement.Position = UDim2.fromScale(0.5, 0.3)
announcement.Size = UDim2.fromScale(0.48, 0.055)
announcement.BackgroundTransparency = 1
announcement.TextColor3 = Color3.fromRGB(255, 230, 90)
announcement.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
announcement.TextStrokeTransparency = 0.25
announcement.Font = Enum.Font.GothamBold
announcement.TextScaled = true
announcement.TextTransparency = 1
announcement.Visible = false
announcement.ZIndex = 10
announcement.Parent = script.Parent

local announcementTextSize = Instance.new("UITextSizeConstraint")
announcementTextSize.MinTextSize = 12
announcementTextSize.MaxTextSize = 24
announcementTextSize.Parent = announcement

local function showZoneAnnouncement(data)
	if announcementFadeTask then
		task.cancel(announcementFadeTask)
	end

	local teamName = data.color == "Red" and "Red Team" or "Blue Team"
	local playerName = data.capturedBy and (" • " .. data.capturedBy) or ""
	announcement.Text = teamName .. playerName .. " captured " .. data.zone
	announcement.TextColor3 = data.color == "Red"
		and Color3.fromRGB(255, 100, 100)
		or Color3.fromRGB(80, 190, 255)
	announcement.Visible = true
	announcement.TextTransparency = 0

	announcementFadeTask = task.delay(2.8, function()
		local tween = TweenService:Create(
			announcement,
			TweenInfo.new(0.5),
			{ TextTransparency = 1 }
		)
		tween:Play()
		tween.Completed:Connect(function()
			announcement.Visible = false
		end)
	end)
end

--------------------------------------------------
-- 🎨 COLORES
--------------------------------------------------

local COLORS = {

	Neutral = Color3.fromRGB(180,180,180),

	Blue = Color3.fromRGB(0,170,255),

	Red = Color3.fromRGB(255,60,60),

	Capturing = Color3.fromRGB(255,230,0)

}

--------------------------------------------------
-- 🎨 CAMBIAR COLOR DEL ANILLO
--------------------------------------------------

local function setRingColor(zoneFrame,color)

	local radial =
		zoneFrame.RadialHolder

	for _,side in ipairs({
		radial.Left,
		radial.Right
		}) do

		for _,stroke in ipairs(side:GetChildren()) do

			if stroke:IsA("Frame") then

				local uiStroke =
					stroke:FindFirstChild("UIStroke")

				if uiStroke then

					local gradient =
						uiStroke:FindFirstChild("UIGradient")

					if gradient then

						gradient.Color =
							ColorSequence.new(color)
					end
				end
			end
		end
	end
end

--------------------------------------------------
-- 📡 ZONE UPDATE
--------------------------------------------------

remote.OnClientEvent:Connect(function(data)

	local zone = zones[data.zone]

	if not zone then
		return
	end

	if data.announce and data.state == "Captured" then
		showZoneAnnouncement(data)
	end

	--------------------------------------------------
	-- 🔄 PROGRESO
	--------------------------------------------------

	zone.RadialHolder.FillRatio.Value =
		data.progress or 0

	--------------------------------------------------
	-- 🎨 ESTADOS
	--------------------------------------------------

	if data.state == "Captured" then

		local color = COLORS.Neutral

		if data.color == "Blue" then

			color = COLORS.Blue

		elseif data.color == "Red" then

			color = COLORS.Red

		end

		zone.Letter.TextColor3 = color

		setRingColor(zone,color)

	elseif data.state == "Capture" then

		zone.Letter.TextColor3 =
			COLORS.Neutral

		setRingColor(
			zone,
			COLORS.Neutral
		)

	else

		--------------------------------------------------
		-- 🟡 CAPTURANDO
		--------------------------------------------------

		zone.Letter.TextColor3 =
			COLORS.Capturing

		setRingColor(
			zone,
			COLORS.Capturing
		)

	end

end)
