local Players = game:GetService("Players")

local remote = game.ReplicatedStorage:WaitForChild("TeamScoreUpdate")

local player = Players.LocalPlayer
local gui = script.Parent
local frame = gui:WaitForChild("StatsFrame")

local scoreUI1 = frame:WaitForChild("ScoreUI1")
local scoreUI2 = frame:WaitForChild("ScoreUI2")
local bluePanel = scoreUI1
local redPanel = scoreUI2

local blueLabel = bluePanel:WaitForChild("Points")
local redLabel = redPanel:WaitForChild("Points")
local blueTeamLabel = bluePanel:WaitForChild("TopBar"):WaitForChild("Team")
local redTeamLabel = redPanel:WaitForChild("TopBar"):WaitForChild("Team")

local function getTeamHighlight(panel, color)
	local highlight = panel:FindFirstChild("LocalTeamHighlight")
	if not highlight then
		highlight = Instance.new("UIStroke")
		highlight.Name = "LocalTeamHighlight"
		highlight.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		highlight.Thickness = 3
		highlight.Parent = panel
	end

	highlight.Color = color
	return highlight
end

local blueHighlight = getTeamHighlight(bluePanel, Color3.fromRGB(0, 170, 255))
local redHighlight = getTeamHighlight(redPanel, Color3.fromRGB(255, 60, 60))

local function updateTeamLayout()
	local playerTeam = player.Team and player.Team.Name
	local playerIsRed = playerTeam == "Red"
	local playerIsBlue = playerTeam == "Blue"

	-- RoundUI remains in the center at LayoutOrder 2.
	if playerIsRed then
		redPanel.LayoutOrder = 1
		bluePanel.LayoutOrder = 3
	else
		bluePanel.LayoutOrder = 1
		redPanel.LayoutOrder = 3
	end

	blueTeamLabel.Text = playerIsBlue and "Blue Team • YOU" or "Blue Team"
	redTeamLabel.Text = playerIsRed and "Red Team • YOU" or "Red Team"
	blueHighlight.Enabled = playerIsBlue
	redHighlight.Enabled = playerIsRed
end

updateTeamLayout()
player:GetPropertyChangedSignal("Team"):Connect(updateTeamLayout)

remote.OnClientEvent:Connect(function(scores)
	blueLabel.Text = tostring(scores.Blue) .. " pts"
	redLabel.Text = tostring(scores.Red) .. " pts"
end)
