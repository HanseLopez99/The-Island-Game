--[[
    LocalScript (LocalScript)
    Path: StarterGui → StatsDisplayGui → StatsFrame → RoundUI
    Parent: RoundUI
    Properties:
        Disabled: false
    Exported: 2026-09-02 16:23:32
]]
local Players = game:GetService("Players")

local remote = game.ReplicatedStorage:WaitForChild("RoundTimeUpdate")
local endgameRemote = game.ReplicatedStorage:WaitForChild("EndgameEvent")

local player = Players.LocalPlayer
local label = script.Parent:WaitForChild("TextLabel")

local currentState = "Waiting"

-- 🔥 NUEVO
local endgameOpen = false

--------------------------------------------------
-- ⏱️ FORMATO MM:SS
--------------------------------------------------

local function formatTime(seconds)
	local minutes = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%02d:%02d", minutes, secs)
end

--------------------------------------------------
-- 🔥 ENDGAME ABIERTO
--------------------------------------------------

endgameRemote.OnClientEvent:Connect(function()
	endgameOpen = true
end)

--------------------------------------------------
-- 🔄 RESET CUANDO REAPARECE / VUELVE
--------------------------------------------------

player.CharacterAdded:Connect(function()

	task.wait(0.5)

	-- 🔥 reset estado
	endgameOpen = false
	currentState = "Waiting"

	label.Text = "Waiting for players..."
	label.TextColor3 = Color3.fromRGB(200, 200, 200)
end)

--------------------------------------------------
-- 🔄 ROUND UI
--------------------------------------------------

remote.OnClientEvent:Connect(function(timeLeft, state, winner)

	-- 🔥 IGNORAR SI ENDGAME ESTÁ ABIERTO
	if endgameOpen then
		return
	end

	currentState = state

	if state == "Waiting" then

		label.Text = "Waiting for players..."
		label.TextColor3 = Color3.fromRGB(200, 200, 200)

	elseif state == "NotReady" then

		label.Text = "Waiting for balanced teams..."
		label.TextColor3 = Color3.fromRGB(255, 120, 120)

	elseif state == "Countdown" then

		label.Text = "Starting in "..timeLeft
		label.TextColor3 = Color3.fromRGB(255, 215, 0)

	elseif state == "Playing" then

		label.Text = formatTime(timeLeft)
		label.TextColor3 = Color3.fromRGB(255, 255, 255)

	elseif state == "End" then

		if winner == "Empate" then

			label.Text = "Draw!"
			label.TextColor3 = Color3.fromRGB(255,255,255)

		elseif winner == "Red" then

			label.Text = "Red Wins!"
			label.TextColor3 = Color3.fromRGB(255,80,80)

		else

			label.Text = "Blue Wins!"
			label.TextColor3 = Color3.fromRGB(0,150,255)
		end
	end
end)