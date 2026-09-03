local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local gui = script.Parent
local miniMap = gui:WaitForChild("MiniMapFrame")
local playerArrow = miniMap:WaitForChild("PlayerArrow")

--------------------------------------------------
-- 🏁 ZONE UPDATE
--------------------------------------------------

local zoneRemote =
	ReplicatedStorage:WaitForChild("ZoneUpdate")

local zoneLabels = {

	ZoneA = miniMap:WaitForChild("ZoneA"),
	ZoneB = miniMap:WaitForChild("ZoneB"),
	ZoneC = miniMap:WaitForChild("ZoneC"),
	ZoneD = miniMap:WaitForChild("ZoneD"),
	ZoneE = miniMap:WaitForChild("ZoneE"),
	ZoneF = miniMap:WaitForChild("ZoneF"),
}

--------------------------------------------------
-- 🟡 PARPADEO
--------------------------------------------------

local blinkingZones = {}

--------------------------------------------------
-- 🌍 LÍMITES DEL MAPA
--------------------------------------------------

local MIN_X = -747.9
local MAX_X = 744.6

local MIN_Z = -750.1
local MAX_Z = 744.7

--------------------------------------------------
-- 🔄 AJUSTE DE ROTACIÓN
--------------------------------------------------

local ROTATION_OFFSET = 0

--------------------------------------------------
-- 🔄 ACTUALIZAR MINIMAPA
--------------------------------------------------

RunService.RenderStepped:Connect(function()

	local character = player.Character
	if not character then return end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	--------------------------------------------------
	-- 🌍 POSICIÓN MUNDO
	--------------------------------------------------

	local worldX = root.Position.X
	local worldZ = root.Position.Z

	--------------------------------------------------
	-- 📍 CONVERTIR A PORCENTAJE
	--------------------------------------------------

	local percentX = (worldX - MIN_X) / (MAX_X - MIN_X)
	local percentY = (worldZ - MIN_Z) / (MAX_Z - MIN_Z)

	--------------------------------------------------
	-- 🔒 LIMITAR
	--------------------------------------------------

	percentX = math.clamp(percentX, 0, 1)
	percentY = math.clamp(percentY, 0, 1)

	--------------------------------------------------
	-- 📍 POSICIÓN EN MINIMAPA
	--------------------------------------------------

	playerArrow.Position = UDim2.fromScale(
		1 - percentX,
		1 - percentY
	)

	--------------------------------------------------
	-- 🔄 ROTACIÓN (CÁMARA)
	--------------------------------------------------

	local look = camera.CFrame.LookVector

	playerArrow.Rotation =
		-math.deg(math.atan2(look.X, look.Z))
		+ ROTATION_OFFSET

end)

--------------------------------------------------
-- 🎨 ACTUALIZAR COLORES DE ZONAS
--------------------------------------------------

zoneRemote.OnClientEvent:Connect(function(data)

	local label = zoneLabels[data.zone]

	if not label then
		return
	end

	--------------------------------------------------
	-- 🟡 CUALQUIER ESTADO DE CAPTURA
	--------------------------------------------------

	if data.state ~= "Captured"
		and data.state ~= "Capture" then

		if not blinkingZones[data.zone] then

			blinkingZones[data.zone] = true

			task.spawn(function()

				while blinkingZones[data.zone] do

					label.TextColor3 = Color3.fromRGB(255,230,0)
					label.TextSize = 22

					task.wait(0.25)

					if not blinkingZones[data.zone] then
						break
					end

					label.TextColor3 = Color3.fromRGB(255,255,255)
					label.TextSize = 20

					task.wait(0.25)

				end

			end)

		end

		return
	end

	--------------------------------------------------
	-- 🛑 DETENER PARPADEO
	--------------------------------------------------

	blinkingZones[data.zone] = false

	label.TextSize = 20

	--------------------------------------------------
	-- 🔴🔵 COLOR FINAL
	--------------------------------------------------

	if data.color == "Blue" then

		label.TextColor3 = Color3.fromRGB(0,170,255)

	elseif data.color == "Red" then

		label.TextColor3 = Color3.fromRGB(255,60,60)

	else

		label.TextColor3 = Color3.fromRGB(255,255,255)

	end

end)