local ReplicatedStorage = game:GetService("ReplicatedStorage")

--------------------------------------------------
-- UI
--------------------------------------------------

local compass = script.Parent:WaitForChild("CompassFrame")
local markers = compass:WaitForChild("Markers")

--------------------------------------------------
-- REMOTE
--------------------------------------------------

local zoneRemote =
	ReplicatedStorage:WaitForChild("ZoneUpdate")

--------------------------------------------------
-- LABELS
--------------------------------------------------

local zoneLabels = {

	ZoneA = markers:WaitForChild("ZoneA"),
	ZoneB = markers:WaitForChild("ZoneB"),
	ZoneC = markers:WaitForChild("ZoneC"),
	ZoneD = markers:WaitForChild("ZoneD"),
	ZoneE = markers:WaitForChild("ZoneE"),
	ZoneF = markers:WaitForChild("ZoneF"),

}

--------------------------------------------------
-- PARPADEO
--------------------------------------------------

local blinkingZones = {}

--------------------------------------------------
-- COLORES
--------------------------------------------------

local COLORS = {

	Neutral = Color3.fromRGB(255,255,255),

	Blue = Color3.fromRGB(0,170,255),

	Red = Color3.fromRGB(255,60,60),

	Capturing = Color3.fromRGB(255,230,0),

}

--------------------------------------------------
-- ACTUALIZAR ZONAS
--------------------------------------------------

zoneRemote.OnClientEvent:Connect(function(data)

	local label = zoneLabels[data.zone]

	if not label then
		return
	end

	--------------------------------------------------
	-- CAPTURANDO / RECAPTURANDO
	--------------------------------------------------

	if data.state ~= "Capture"
		and data.state ~= "Captured" then

		if not blinkingZones[data.zone] then

			blinkingZones[data.zone] = true

			task.spawn(function()

				while blinkingZones[data.zone] do

					label.TextColor3 = COLORS.Capturing

					--------------------------------------------------
					-- Si usas TextScaled, NO cambies TextSize
					--------------------------------------------------

					task.wait(0.25)

					if not blinkingZones[data.zone] then
						break
					end

					label.TextColor3 = COLORS.Neutral

					task.wait(0.25)

				end

			end)

		end

		return
	end

	--------------------------------------------------
	-- DETENER PARPADEO
	--------------------------------------------------

	blinkingZones[data.zone] = false

	--------------------------------------------------
	-- COLOR FINAL
	--------------------------------------------------

	if data.state == "Capture" then

		label.TextColor3 = COLORS.Neutral

	elseif data.color == "Blue" then

		label.TextColor3 = COLORS.Blue

	elseif data.color == "Red" then

		label.TextColor3 = COLORS.Red

	else

		label.TextColor3 = COLORS.Neutral

	end

end)