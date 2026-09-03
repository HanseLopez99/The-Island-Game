local TweenService = game:GetService("TweenService")

local remote = game.ReplicatedStorage:WaitForChild("HitmarkerEvent")

local gui = script.Parent
local hitmarker = gui:WaitForChild("Hitmarker")

--------------------------------------------------
-- 🔥 CONFIG
--------------------------------------------------

hitmarker.Visible = false
hitmarker.TextTransparency = 1

local fadeTask = nil

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