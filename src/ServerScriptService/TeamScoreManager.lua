--[[
    TeamScoreManager (ModuleScript)
    Path: ServerScriptService
    Parent: ServerScriptService
    Exported: 2026-09-02 16:23:32
]]
local module = {}

local teamScores = {
	Red = 0,
	Blue = 0
}

local remote = game.ReplicatedStorage:WaitForChild("TeamScoreUpdate")

function module.AddPoints(teamName, amount)
	teamScores[teamName] += amount
	remote:FireAllClients(teamScores)
end

function module.Reset()
	teamScores.Red = 0
	teamScores.Blue = 0
	remote:FireAllClients(teamScores)
end

function module.GetScores()
	return teamScores
end

return module