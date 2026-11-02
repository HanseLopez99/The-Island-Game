local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")

		-- 🔥 velocidad base
		humanoid.WalkSpeed = 20

		-- 🔥 salto mejorado
		humanoid.JumpPower = 60
	end)
end)