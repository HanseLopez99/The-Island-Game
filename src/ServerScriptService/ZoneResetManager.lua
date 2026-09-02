--[[
    ZoneResetManager (ModuleScript)
    Path: ServerScriptService
    Parent: ServerScriptService
    Exported: 2026-09-02 16:23:32
]]
local module = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remote = ReplicatedStorage:WaitForChild("ZoneUpdate")

-- 🔄 RESET GENERAL (cuando inicia ronda)
function module.ResetZones()
	local zones = workspace:WaitForChild("MapZones"):GetChildren()

	for _, zone in ipairs(zones) do
		-- 🔥 reset owner
		zone:SetAttribute("Owner", nil)

		-- 🔥 reset UI global
		remote:FireAllClients({
			zone = zone.Name,
			progress = 0,
			state = "Capture",
			color = "Neutral"
		})
	end

	print("✔ Zones reset")
end

-- 🟢 NUEVO: sincronizar estado actual a un jugador
function module.SyncZonesToPlayer(player)
	local zones = workspace:WaitForChild("MapZones"):GetChildren()

	for _, zone in ipairs(zones) do
		local owner = zone:GetAttribute("Owner")

		remote:FireClient(player, {
			zone = zone.Name,
			progress = owner and 1 or 0,
			state = owner and "Captured" or "Capture",
			color = owner or "Neutral"
		})
	end

	print("✔ Zones synced to", player.Name)
end

return module