local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local LOBBY_PLACE_ID = 95018085174690

Players.PlayerAdded:Connect(function(player)
	local joinData = player:GetJoinData()

	-- 🔥 SI ES SERVER PRIVADO → PERMITIR
	if game.PrivateServerId ~= "" then
		return
	end

	-- 🔥 SI NO VIENE DE MATCHMAKING → SACAR
	if not joinData or not joinData.TeleportData then
		warn(player.Name .. " not from matchmaking → sending to lobby")

		task.wait(1)

		local success, err = pcall(function()
			TeleportService:TeleportAsync(LOBBY_PLACE_ID, {player})
		end)

		if not success then
			warn("Teleport failed:", err)
		end
	end
end)