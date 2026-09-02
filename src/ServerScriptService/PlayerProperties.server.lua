--[[
    PlayerProperties (Script)
    Path: ServerScriptService
    Parent: ServerScriptService
    Properties:
        Disabled: false
        RunContext: Enum.RunContext.Legacy
    Exported: 2026-09-02 16:23:32
]]
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