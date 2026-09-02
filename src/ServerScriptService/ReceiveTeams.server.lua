--[[
    ReceiveTeams (Script)
    Path: ServerScriptService
    Parent: ServerScriptService
    Properties:
        Disabled: false
        RunContext: Enum.RunContext.Legacy
    Exported: 2026-09-02 16:23:32
]]
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

-- 🔥 Cache de teleport data
local teleportDataCache = {}

-- 🟣 Guardar datos al entrar
Players.PlayerAdded:Connect(function(player)
	local joinData = player:GetJoinData()

	if joinData and joinData.TeleportData then
		teleportDataCache[player.UserId] = joinData.TeleportData
	end

	-- 🔥 intentar asignar varias veces
	task.spawn(function()
		for i = 1, 10 do
			local data = teleportDataCache[player.UserId]

			if data and data.teams then
				for _, info in ipairs(data.teams) do
					if info.userId == player.UserId then

						local teamName = info.team

						if Teams:FindFirstChild(teamName) then
							player.Team = Teams[teamName]
							print("✔ Assigned:", player.Name, "→", teamName)
							return
						else
							warn("❌ Team no existe:", teamName)
						end
					end
				end
			end

			task.wait(0.5) -- 🔥 esperar a que lleguen datos
		end

		warn("❌ Failed to assign team for", player.Name)
	end)
end)