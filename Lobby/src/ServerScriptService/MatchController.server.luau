local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local remote = game.ReplicatedStorage:WaitForChild("RoundTimeUpdate")

local MATCH_PLACE_ID = 117126510355758

local folder = workspace:WaitForChild("2vs2")

local blueZone = folder:WaitForChild("BluePad")
local redZone = folder:WaitForChild("RedPad")

local REQUIRED = 1
local COUNTDOWN = 5

local countdownActive = false

-- 🔍 detectar jugadores dentro de la zona
local function getPlayers(zone)
	local list = {}

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if not character then continue end

		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then continue end

		local dist = (root.Position - zone.Position).Magnitude

		if dist < (zone.Size.X / 1.5) then
			table.insert(list, player)
		end
	end

	return list
end

-- ⏱️ countdown + teleport
local function startCountdown()
	if countdownActive then return end

	local blue = getPlayers(blueZone)
	local red = getPlayers(redZone)

	if #blue < REQUIRED or #red < REQUIRED then
		return
	end

	countdownActive = true

	print("Countdown started")

	local playersToSend = {}

	for _, player in ipairs(blue) do
		table.insert(playersToSend, player)
	end

	for _, player in ipairs(red) do
		table.insert(playersToSend, player)
	end

	-- 🔥 COUNTDOWN SOLO PARA EL GRUPO
	for i = COUNTDOWN, 1, -1 do
		for _, player in ipairs(playersToSend) do
			remote:FireClient(player, i, "Countdown")
		end
		task.wait(1)
	end

	print("MATCH START")

	if #playersToSend == 0 then
		warn("❌ No players to send")
		countdownActive = false
		return
	end

	-- 🔥 GUARDAR EQUIPOS
	local teamData = {}

	for _, player in ipairs(playersToSend) do
		if player.Team then
			table.insert(teamData, {
				userId = player.UserId,
				team = player.Team.Name
			})
		end
	end

	-- 🔥 CREAR SERVIDOR PRIVADO
	local reservedServerCode = TeleportService:ReserveServer(MATCH_PLACE_ID)

	local success, err = pcall(function()
		TeleportService:TeleportToPrivateServer(
			MATCH_PLACE_ID,
			reservedServerCode,
			playersToSend,
			nil,
			{
				mode = "2v2",
				returnServer = game.JobId,
				teams = teamData
			}
		)
	end)

	if success then
		print("✅ Teleport a server privado correcto")
	else
		warn("❌ Teleport error:", err)
	end

	-- 🔥 RESET
	task.delay(1, function()
		countdownActive = false
	end)
end

-- 🔄 loop principal
while true do
	task.wait(0.5)

	local blue = getPlayers(blueZone)
	local red = getPlayers(redZone)

	print("Blue:", #blue, "Red:", #red)

	-- 🔥 RESET UI SOLO PARA LOS QUE NO ESTÁN EN MATCH
	for _, player in ipairs(Players:GetPlayers()) do
		if not table.find(blue, player) and not table.find(red, player) then
			remote:FireClient(player, 0, "Waiting")
		end
	end

	if #blue >= REQUIRED and #red >= REQUIRED then
		startCountdown()
	end
end