local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local WALK_SPEED = 30

local humanoid

local function onCharacter(character)
	humanoid = character:WaitForChild("Humanoid")
	humanoid.WalkSpeed = WALK_SPEED
end

player.CharacterAdded:Connect(onCharacter)

if player.Character then
	onCharacter(player.Character)
end

RunService.RenderStepped:Connect(function()
	if not humanoid then
		return
	end

	humanoid.WalkSpeed = WALK_SPEED
end)

print("Movement system loaded: fixed walk speed")
