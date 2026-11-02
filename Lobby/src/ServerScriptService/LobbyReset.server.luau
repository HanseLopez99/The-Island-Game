local Players = game:GetService("Players")
local remote = game.ReplicatedStorage:WaitForChild("RoundTimeUpdate")

local function resetUI(player)
	task.wait(1) -- esperar a que cargue el cliente

	remote:FireClient(player, 0, "Waiting")
end

-- 🟢 cuando entra al lobby
Players.PlayerAdded:Connect(resetUI)

-- 🔥 cuando reaparece (IMPORTANTE)
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		resetUI(player)
	end)
end)