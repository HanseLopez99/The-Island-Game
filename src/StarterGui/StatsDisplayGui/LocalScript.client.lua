local remote = game.ReplicatedStorage:WaitForChild("TeamScoreUpdate")

local gui = script.Parent
local frame = gui:WaitForChild("StatsFrame")

local blueLabel = frame:WaitForChild("ScoreUI1"):WaitForChild("Points")
local redLabel = frame:WaitForChild("ScoreUI2"):WaitForChild("Points")

remote.OnClientEvent:Connect(function(scores)
	blueLabel.Text = tostring(scores.Blue) .. " pts"
	redLabel.Text = tostring(scores.Red) .. " pts"
end)