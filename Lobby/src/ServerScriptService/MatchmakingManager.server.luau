local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local remote = game.ReplicatedStorage:WaitForChild("RoundTimeUpdate")

local MATCH_PLACE_ID = 117126510355758

local matchmakingFolder = workspace:WaitForChild("Matchmaking")

-- 🔥 CONFIGURACIÓN POR MODO
local MODES = {
	["Mode_1v1"] = {required = 1, countdown = 5},
	["Mode_2v2"] = {required = 2, countdown = 5},
	["Mode_3v3"] = {required = 3, countdown = 5},
	["Mode_4v4"] = {required = 4, countdown = 5},
	["Mode_5v5"] = {required = 5, countdown = 5},
	["Mode_6v6"] = {required = 6, countdown = 5}
}

-- 🔥 estado independiente por modo
local activeCountdowns = {}

--------------------------------------------------
-- 🔍 detectar jugadores en zona
--------------------------------------------------

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

--------------------------------------------------
-- 🚀 START MATCH
--------------------------------------------------

local function startMatch(modeName, modeFolder)
	if activeCountdowns[modeName] then return end

	local config = MODES[modeName]
	if not config then return end

	local blue = getPlayers(modeFolder.BluePad)
	local red = getPlayers(modeFolder.RedPad)

	if #blue < config.required or #red < config.required then
		return
	end

	activeCountdowns[modeName] = true

	local playersToSend = {}

	for _, p in ipairs(blue) do table.insert(playersToSend, p) end
	for _, p in ipairs(red) do table.insert(playersToSend, p) end

	print("Countdown started:", modeName)

	-- 🔥 COUNTDOWN SOLO PARA ESTE GRUPO
	for i = config.countdown, 1, -1 do
		for _, p in ipairs(playersToSend) do
			remote:FireClient(p, i, "Countdown")
		end
		task.wait(1)
	end

	if #playersToSend == 0 then
		activeCountdowns[modeName] = false
		return
	end

	print("MATCH START:", modeName)

	-- 🔥 GUARDAR EQUIPOS
	local teamData = {}

	for _, p in ipairs(playersToSend) do
		if p.Team then
			table.insert(teamData, {
				userId = p.UserId,
				team = p.Team.Name
			})
		end
	end

	-- 🔥 CREAR SERVER PRIVADO (API NUEVA)
	local successReserve, reservedServerCode = pcall(function()
		return TeleportService:ReserveServerAsync(MATCH_PLACE_ID)
	end)

	if not successReserve then
		warn("❌ Failed to reserve server:", reservedServerCode)
		activeCountdowns[modeName] = false
		return
	end

	-- 🚀 TELEPORT
	local successTeleport, err = pcall(function()
		TeleportService:TeleportToPrivateServer(
			MATCH_PLACE_ID,
			reservedServerCode,
			playersToSend,
			nil,
			{
				mode = modeName,
				returnServer = game.JobId,
				teams = teamData
			}
		)
	end)

	if successTeleport then
		print("✅ Teleport correcto:", modeName)
	else
		warn("❌ Teleport error:", err)
	end

	-- 🔥 reset independiente
	task.delay(1, function()
		activeCountdowns[modeName] = false
	end)
end

--------------------------------------------------
-- 🔄 LOOP GLOBAL
--------------------------------------------------

while true do
	task.wait(0.5)

	for modeName, config in pairs(MODES) do
		local modeFolder = matchmakingFolder:FindFirstChild(modeName)
		if not modeFolder then continue end

		local blue = getPlayers(modeFolder.BluePad)
		local red = getPlayers(modeFolder.RedPad)

		print(modeName, "Blue:", #blue, "Red:", #red)

		-- 🔥 RESET UI SOLO PARA LOS QUE NO ESTÁN EN ESTE MATCH
		for _, player in ipairs(Players:GetPlayers()) do
			local inBlue = table.find(blue, player)
			local inRed = table.find(red, player)

			if not inBlue and not inRed then
				remote:FireClient(player, 0, "Waiting")
			end
		end

		-- 🚀 iniciar match independiente
		if #blue >= config.required and #red >= config.required then
			startMatch(modeName, modeFolder)
		end
	end
end