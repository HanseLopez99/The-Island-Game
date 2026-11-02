local Players = game:GetService("Players")

local lobbyFolder = workspace:FindFirstChild("Lobby")
local lobbySpawn = lobbyFolder and lobbyFolder:FindFirstChild("LobbySpawn")

Players.PlayerAdded:Connect(function(player)
	player.Team = nil

	player.CharacterAdded:Connect(function(character)
		task.wait(0.2)

		if lobbySpawn then
			character:MoveTo(lobbySpawn.Position)
		end
	end)
end)