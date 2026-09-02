--[[
    ZoneHUDController (LocalScript)
    Path: StarterGui → ZoneHUD
    Parent: ZoneHUD
    Properties:
        Disabled: false
    Exported: 2026-09-02 16:23:32
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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