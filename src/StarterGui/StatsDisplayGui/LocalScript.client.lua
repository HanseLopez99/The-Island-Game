--[[
    LocalScript (LocalScript)
    Path: StarterGui → StatsDisplayGui
    Parent: StatsDisplayGui
    Properties:
        Disabled: false
    Exported: 2026-09-02 16:23:32
]]
local remote = game.ReplicatedStorage:WaitForChild("TeamScoreUpdate")

local gui = script.Parent
local frame = gui:WaitForChild("StatsFrame")

local blueLabel = frame:WaitForChild("ScoreUI1"):WaitForChild("Points")
local redLabel = frame:WaitForChild("ScoreUI2"):WaitForChild("Points")

remote.OnClientEvent:Connect(function(scores)
	blueLabel.Text = tostring(scores.Blue) .. " pts"
	redLabel.Text = tostring(scores.Red) .. " pts"
end)