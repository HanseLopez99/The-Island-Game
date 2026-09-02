--[[
    LocalScript (LocalScript)
    Path: StarterGui → EndgameGui
    Parent: EndgameGui
    Properties:
        Disabled: false
    Exported: 2026-09-02 16:23:32
]]
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

local remote = game.ReplicatedStorage:WaitForChild("EndgameEvent")
local continueRemote = game.ReplicatedStorage:WaitForChild("ContinueEvent")

local gui = script.Parent
local frame = gui:WaitForChild("MainFrame")

local winnerLabel = frame:WaitForChild("WinnerLabel")
local rankingFrame = frame:WaitForChild("RankingFrame")
local footer = frame:WaitForChild("FooterContainer"):WaitForChild("Footer")
local continueButton = frame.FooterContainer:WaitForChild("ContinueButton")

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

gui.Enabled = false

local canContinue = false

--------------------------------------------------
-- ❄️ BLOQUEAR MOVIMIENTO
--------------------------------------------------

local function blockMovement()
	return Enum.ContextActionResult.Sink
end

local function freezePlayer()

	ContextActionService:BindAction(
		"FreezeMovement",
		blockMovement,
		false,
		Enum.PlayerActions.CharacterForward,
		Enum.PlayerActions.CharacterBackward,
		Enum.PlayerActions.CharacterLeft,
		Enum.PlayerActions.CharacterRight,
		Enum.PlayerActions.CharacterJump
	)

	--------------------------------------------------
	-- 🔥 FREEZE REAL (MÓVIL + PC)
	--------------------------------------------------

	local character = player.Character

	if character then

		local humanoid = character:FindFirstChild("Humanoid")

		if humanoid then
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
		end
	end

	--------------------------------------------------
	-- 🔥 LIBERAR CURSOR
	--------------------------------------------------

	UserInputService.MouseIconEnabled = true
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default

	--------------------------------------------------
	-- 🔥 SALIR TEMPORALMENTE FPS
	--------------------------------------------------

	player.CameraMode = Enum.CameraMode.Classic
end

--------------------------------------------------
-- 🧹 LIMPIAR RANKING
--------------------------------------------------

local function clearRanking()

	for _, child in ipairs(rankingFrame:GetChildren()) do

		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
end

--------------------------------------------------
-- 🏁 ENDGAME
--------------------------------------------------

remote.OnClientEvent:Connect(function(winner, ranking)

	gui.Enabled = true
	canContinue = false

	--------------------------------------------------
	-- ❄️ FREEZE + CURSOR
	--------------------------------------------------

	freezePlayer()

	--------------------------------------------------
	-- 🎬 ANIMACIÓN
	--------------------------------------------------

	frame.Size = UDim2.new(0,0,0,0)

	TweenService:Create(frame, TweenInfo.new(0.3), {
		Size = UDim2.new(0.4,0,0.5,0)
	}):Play()

	--------------------------------------------------
	-- 🏆 WINNER
	--------------------------------------------------

	if winner == "Empate" then

		winnerLabel.Text = "Draw!"
		winnerLabel.TextColor3 = Color3.fromRGB(255,255,255)

	else

		winnerLabel.Text = winner.." Team Wins!"

		if winner == "Red" then
			winnerLabel.TextColor3 = Color3.fromRGB(255,80,80)

		else
			winnerLabel.TextColor3 = Color3.fromRGB(0,150,255)
		end
	end

	--------------------------------------------------
	-- 🧹 LIMPIAR
	--------------------------------------------------

	clearRanking()

	--------------------------------------------------
	-- 🥇 RANKING
	--------------------------------------------------

	if ranking then

		for i, data in ipairs(ranking) do

			local label = Instance.new("TextLabel")

			if i == 1 then
				label.Size = UDim2.new(1, 0, 0, 40)

			elseif i <= 3 then
				label.Size = UDim2.new(1, 0, 0, 30)

			else
				label.Size = UDim2.new(1, 0, 0, 28)
			end

			label.BackgroundTransparency = 1
			label.TextScaled = true
			label.Font = Enum.Font.GothamBold
			label.LayoutOrder = i

			label.Text = i..". "..data.name.." - "..data.kills.." Kills"

			if i == 1 then
				label.TextColor3 = Color3.fromRGB(255, 215, 0)

			elseif i == 2 then
				label.TextColor3 = Color3.fromRGB(192, 192, 192)

			elseif i == 3 then
				label.TextColor3 = Color3.fromRGB(205, 127, 50)

			else
				label.TextColor3 = Color3.fromRGB(255,255,255)
			end

			label.TextStrokeTransparency = 0.5
			label.TextStrokeColor3 = Color3.fromRGB(0,0,0)

			label.Parent = rankingFrame
		end
	end

	rankingFrame.CanvasPosition = Vector2.new(0,0)

	--------------------------------------------------
	-- ⏱️ COUNTDOWN VISUAL
	--------------------------------------------------

	for i = 5, 1, -1 do

		footer.Text = "Continue available in "..i

		task.wait(1)
	end

	footer.Text = "Press Continue"

	canContinue = true
end)

--------------------------------------------------
-- 🟢 CONTINUE BUTTON
--------------------------------------------------

continueButton.MouseButton1Click:Connect(function()

	if not canContinue then
		return
	end

	canContinue = false
	continueButton.Active = false

	--------------------------------------------------
	-- 🔥 DESBLOQUEAR MOVIMIENTO
	--------------------------------------------------

	ContextActionService:UnbindAction("FreezeMovement")

	continueRemote:FireServer()

	gui.Enabled = false
end)
