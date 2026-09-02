--[[
    SpawnManager (Script)
    Path: ServerScriptService
    Parent: ServerScriptService
    Properties:
        Disabled: false
        RunContext: Enum.RunContext.Legacy
    Exported: 2026-09-02 16:23:32
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local mapSpawns = workspace:WaitForChild("MapSpawns"):GetChildren()

-- 🔥 módulos
local ZoneReset = require(game.ServerScriptService:WaitForChild("ZoneResetManager"))

-- 🔫 carpeta de armas
local weaponsFolder = ReplicatedStorage:WaitForChild("Weapons")

Players.PlayerAdded:Connect(function(player)

	player.CharacterAdded:Connect(function(character)

		task.wait(0.2)

		--------------------------------------------------
		-- 🎲 SPAWN ALEATORIO
		--------------------------------------------------

		if #mapSpawns > 0 then

			local spawn =
				mapSpawns[math.random(1,#mapSpawns)]

			character:MoveTo(spawn.Position)
		end

		--------------------------------------------------
		-- 🔥 SINCRONIZAR ZONAS
		--------------------------------------------------

		task.wait(0.3)

		ZoneReset.SyncZonesToPlayer(player)

		--------------------------------------------------
		-- 🔫 LIMPIAR ARMAS
		--------------------------------------------------

		for _, tool in ipairs(player.Backpack:GetChildren()) do

			if tool:IsA("Tool") then
				tool:Destroy()
			end
		end

		for _, tool in ipairs(character:GetChildren()) do

			if tool:IsA("Tool") then
				tool:Destroy()
			end
		end

		--------------------------------------------------
		-- 🔫 DAR RIFLE
		--------------------------------------------------

		local rifle =
			weaponsFolder:WaitForChild("AssaultRifle"):Clone()

		rifle.Parent = player.Backpack

		--------------------------------------------------
		-- ⚔ DAR ESPADA
		--------------------------------------------------

		local sword =
			ServerStorage:WaitForChild("Sword"):Clone()

		sword.Parent = player.Backpack

		--------------------------------------------------
		-- 🔥 EQUIPAR RIFLE
		--------------------------------------------------

		local humanoid =
			character:WaitForChild("Humanoid")

		task.wait(0.1)

		humanoid:EquipTool(rifle)

	end)

end)