local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local gui = script.Parent
local miniMap = gui:WaitForChild("MiniMapFrame")
local playerArrow = miniMap:WaitForChild("PlayerArrow")

-- Set to false before publishing the game. This only creates local fake feed
-- entries and does not affect kills, scores, or server gameplay.
local SIMULATION_MODE = true
local MAX_KILL_FEED_ENTRIES = 5
local KILL_FEED_LIFETIME = 5

local killFeed = Instance.new("Frame")
killFeed.Name = "KillFeed"
killFeed.Position = UDim2.new(0, 0, 1, 8)
killFeed.Size = UDim2.new(1, 0, 0, 150)
killFeed.BackgroundTransparency = 1
killFeed.BorderSizePixel = 0
killFeed.ZIndex = 20
killFeed.Parent = miniMap

local killFeedLayout = Instance.new("UIListLayout")
killFeedLayout.SortOrder = Enum.SortOrder.LayoutOrder
killFeedLayout.Padding = UDim.new(0, 4)
killFeedLayout.Parent = killFeed

local killFeedEntries = {}

local function teamColor(teamName)
	if teamName == "Red" then
		return Color3.fromRGB(255, 90, 90)
	elseif teamName == "Blue" then
		return Color3.fromRGB(80, 190, 255)
	end
	return Color3.fromRGB(235, 235, 235)
end

local function removeOldestEntry()
	local entry = table.remove(killFeedEntries, 1)
	if entry and entry.Parent then
		entry:Destroy()
	end
end

local function addKillFeedEntry(data)
	while #killFeedEntries >= MAX_KILL_FEED_ENTRIES do
		removeOldestEntry()
	end

	local entry = Instance.new("TextLabel")
	entry.Name = "KillEntry"
	entry.Size = UDim2.new(1, 0, 0, 24)
	entry.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	entry.BackgroundTransparency = 0.35
	entry.BorderSizePixel = 0
	entry.Font = Enum.Font.GothamBold
	entry.TextSize = 14
	entry.TextScaled = false
	entry.TextTruncate = Enum.TextTruncate.AtEnd
	entry.TextWrapped = false
	entry.TextXAlignment = Enum.TextXAlignment.Center
	entry.TextColor3 = Color3.fromRGB(255, 255, 255)
	entry.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	entry.TextStrokeTransparency = 0.35
	entry.Text = string.format("%s  ›  %s", data.killerName or "Unknown", data.victimName or "Unknown")
	entry.ZIndex = 21
	entry.Parent = killFeed

	local stroke = Instance.new("UIStroke")
	stroke.Color = teamColor(data.killerTeam)
	stroke.Thickness = 1
	stroke.Transparency = 0.35
	stroke.Parent = entry

	table.insert(killFeedEntries, entry)

	task.delay(KILL_FEED_LIFETIME, function()
		if not entry.Parent then
			return
		end

		local tween = TweenService:Create(
			entry,
			TweenInfo.new(0.4),
			{ TextTransparency = 1, BackgroundTransparency = 1 }
		)
		tween:Play()
		tween.Completed:Connect(function()
			if entry.Parent then
				entry:Destroy()
			end
		end)
	end)
end

local killFeedRemote = ReplicatedStorage:WaitForChild("KillFeedEvent")
killFeedRemote.OnClientEvent:Connect(addKillFeedEntry)

if SIMULATION_MODE then
	task.spawn(function()
		local fakeKills = {
			{ killerName = "Raven", victimName = "Ghost", killerTeam = "Blue" },
			{ killerName = "Ghost", victimName = "Raven", killerTeam = "Red" },
			{ killerName = "Nova", victimName = "Shadow", killerTeam = "Blue" },
			{ killerName = "Shadow", victimName = "Nova", killerTeam = "Red" },
		}

		task.wait(2)
		local index = 1
		while SIMULATION_MODE and killFeed.Parent do
			addKillFeedEntry(fakeKills[index])
			index = index % #fakeKills + 1
			task.wait(2.5)
		end
	end)
end

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
