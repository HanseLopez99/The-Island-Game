local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

-- 🔥 ID REAL DEL LOBBY
local LOBBY_PLACE_ID = 95018085174690

local mapSpawns = workspace:WaitForChild("MapSpawns"):GetChildren()

local gameRunning = ReplicatedStorage:WaitForChild("GameRunning")
local timeRemote = ReplicatedStorage:WaitForChild("RoundTimeUpdate")
local endgameRemote = ReplicatedStorage:WaitForChild("EndgameEvent")
local continueRemote = ReplicatedStorage:WaitForChild("ContinueEvent")

local TeamScore = require(game.ServerScriptService:WaitForChild("TeamScoreManager"))
local ZoneReset = require(game.ServerScriptService:WaitForChild("ZoneResetManager"))

-- 🔥 DEBUG
local ROUND_TIME = 300

--------------------------------------------------
-- 🎲 TELEPORT A MAPA
--------------------------------------------------

local function teleportToMap()

	for _, player in ipairs(Players:GetPlayers()) do

		if player.Character then

			local spawn = mapSpawns[math.random(1, #mapSpawns)]

			player.Character:MoveTo(spawn.Position)
		end
	end
end

--------------------------------------------------
-- 🏆 OBTENER GANADOR
--------------------------------------------------

local function getWinner()

	local scores = TeamScore.GetScores()

	if scores.Red > scores.Blue then
		return "Red"

	elseif scores.Blue > scores.Red then
		return "Blue"

	else
		return "Empate"
	end
end

--------------------------------------------------
-- 🥇 RANKING SOLO GANADOR
--------------------------------------------------

local function getRanking(winner)

	local ranking = {}

	for _, player in ipairs(Players:GetPlayers()) do

		if player.Team and player.Team.Name == winner then

			if player:FindFirstChild("leaderstats") then

				local kills = player.leaderstats:FindFirstChild("Kills")

				if kills then

					table.insert(ranking, {
						name = player.Name,
						kills = kills.Value
					})
				end
			end
		end
	end

	table.sort(ranking, function(a, b)
		return a.kills > b.kills
	end)

	return ranking
end

--------------------------------------------------
-- 🖱️ CONTINUE → TELEPORT
--------------------------------------------------

continueRemote.OnServerEvent:Connect(function(player)

	local success, err = pcall(function()

		TeleportService:Teleport(LOBBY_PLACE_ID, player)

	end)

	if success then
		print("✔", player.Name, "volvió al lobby")

	else
		warn("❌ Error al volver:", err)
	end
end)

--------------------------------------------------
-- 🔁 LOOP PRINCIPAL
--------------------------------------------------

while true do

	print("Iniciando partida...")

	gameRunning.Value = true

	--------------------------------------------------
	-- 🔥 RESET SOLO AL INICIO
	--------------------------------------------------

	TeamScore.Reset()
	ZoneReset.ResetZones()

	teleportToMap()

	--------------------------------------------------
	-- ⏳ ROUND TIMER
	--------------------------------------------------

	for i = ROUND_TIME, 0, -1 do

		timeRemote:FireAllClients(i, "Playing")

		task.wait(1)
	end

	print("Ronda terminada")

	gameRunning.Value = false

	--------------------------------------------------
	-- 🏆 ENDGAME
	--------------------------------------------------

	local winner = getWinner()
	local ranking = getRanking(winner)

	endgameRemote:FireAllClients(winner, ranking)

	--------------------------------------------------
	-- 🔥 ESPERAR QUE TODOS SALGAN
	--------------------------------------------------

	repeat
		task.wait(1)

	until #Players:GetPlayers() == 0

	print("Servidor vacío → reiniciando ronda")
end