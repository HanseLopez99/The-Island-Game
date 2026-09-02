--[[
    WeaponController (LocalScript)
    Path: StarterPlayer → StarterPlayerScripts
    Parent: StarterPlayerScripts
    Properties:
        Disabled: false
    Exported: 2026-09-02 16:23:32
]]
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

--------------------------------------------------
-- 🎒 OCULTAR BACKPACK ROBLOX
--------------------------------------------------

StarterGui:SetCoreGuiEnabled(
	Enum.CoreGuiType.Backpack,
	false
)

--------------------------------------------------
-- 🔫 EQUIPAR SLOT
--------------------------------------------------

local function equipSlot(toolName)

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return end

	local tool =
		backpack:FindFirstChild(toolName)
		or character:FindFirstChild(toolName)

	if not tool then
		return
	end

	--------------------------------------------------
	-- 🔥 EQUIPAR
	--------------------------------------------------

	humanoid:EquipTool(tool)

end

--------------------------------------------------
-- ⌨️ INPUT
--------------------------------------------------

UserInputService.InputBegan:Connect(function(input, gameProcessed)

	--------------------------------------------------
	-- NO bloquear por gameProcessed.
	-- Queremos que funcione incluso
	-- mientras sprinta.
	--------------------------------------------------

	if input.KeyCode == Enum.KeyCode.One then

		equipSlot("AssaultRifle")

	elseif input.KeyCode == Enum.KeyCode.Two then

		equipSlot("Sword")

	end

end)