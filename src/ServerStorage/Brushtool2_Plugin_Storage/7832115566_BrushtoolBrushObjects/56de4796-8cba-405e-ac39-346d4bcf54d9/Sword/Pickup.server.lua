--[[
    Pickup (Script)
    Path: ServerStorage → Brushtool2_Plugin_Storage → 7832115566_BrushtoolBrushObjects → {56de4796-8cba-405e-ac39-346d4bcf54d9} → Sword
    Parent: Sword
    Properties:
        Disabled: false
        RunContext: Enum.RunContext.Legacy
    Exported: 2026-09-02 16:23:32
]]
local pickup = script.Parent
local prompt = pickup:WaitForChild("ProximityPrompt")

local toolName = "Sword" -- nombre EXACTO en ServerStorage
local serverStorage = game:GetService("ServerStorage")

local debounce = {}

prompt.Triggered:Connect(function(player)
	if debounce[player] then return end
	debounce[player] = true

	-- Verificar si ya tiene la espada
	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character

	if backpack:FindFirstChild(toolName) or (character and character:FindFirstChild(toolName)) then
		debounce[player] = nil
		return
	end

	-- Dar herramienta
	local tool = serverStorage:FindFirstChild(toolName)
	if tool then
		local clone = tool:Clone()
		clone.Parent = backpack
	end

	-- Desaparece visualmente (opcional)
	pickup:Destroy()

	task.wait(1)
	debounce[player] = nil
end)