local TweenService = game:GetService("TweenService")

local remote = game.ReplicatedStorage:WaitForChild("HitmarkerEvent")
local killConfirmedRemote = game.ReplicatedStorage:WaitForChild("KillConfirmedEvent")

local gui = script.Parent
local hitmarker = gui:WaitForChild("Hitmarker")

--------------------------------------------------
-- 🔥 CONFIG
--------------------------------------------------

hitmarker.Visible = false
hitmarker.TextTransparency = 1

local fadeTask = nil
local killFadeTask = nil

local killLabel = Instance.new("TextLabel")
killLabel.Name = "KillConfirmation"
killLabel.AnchorPoint = Vector2.new(0.5, 0.5)
killLabel.Position = UDim2.fromScale(0.5, 0.62)
killLabel.Size = UDim2.fromScale(0.32, 0.055)
killLabel.BackgroundTransparency = 1
killLabel.TextColor3 = Color3.fromRGB(255, 225, 90)
killLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
killLabel.TextStrokeTransparency = 0.25
killLabel.Font = Enum.Font.GothamBold
killLabel.TextScaled = true
killLabel.TextTransparency = 1
killLabel.Visible = false
killLabel.ZIndex = 10
killLabel.Parent = gui

local killTextSize = Instance.new("UITextSizeConstraint")
killTextSize.MinTextSize = 12
killTextSize.MaxTextSize = 24
killTextSize.Parent = killLabel

--------------------------------------------------
-- 🎯 HITMARKER
--------------------------------------------------

remote.OnClientEvent:Connect(function()

	--------------------------------------------------
	-- 🔥 CANCELAR FADE ANTERIOR
	--------------------------------------------------

	if fadeTask then
		task.cancel(fadeTask)
	end

	--------------------------------------------------
	-- 🔥 MOSTRAR
	--------------------------------------------------

	hitmarker.Visible = true
	hitmarker.TextTransparency = 0

	--------------------------------------------------
	-- 🔥 ESPERAR ANTES DE FADE
	--------------------------------------------------

	fadeTask = task.delay(0.15, function()

		local tween = TweenService:Create(
			hitmarker,
			TweenInfo.new(0.2),
			{
				TextTransparency = 1
			}
		)

		tween:Play()

		tween.Completed:Connect(function()

			hitmarker.Visible = false
		end)
	end)
end)

killConfirmedRemote.OnClientEvent:Connect(function(data)
	if killFadeTask then
		task.cancel(killFadeTask)
	end

	local targetName = data and data.targetName or ""
	killLabel.Text = targetName ~= ""
		and "KILL CONFIRMED • " .. targetName
		or "KILL CONFIRMED"
	killLabel.Visible = true
	killLabel.TextTransparency = 0

	killFadeTask = task.delay(1.1, function()
		local tween = TweenService:Create(
			killLabel,
			TweenInfo.new(0.4),
			{ TextTransparency = 1 }
		)
		tween:Play()
		tween.Completed:Connect(function()
			killLabel.Visible = false
		end)
	end)
end)
