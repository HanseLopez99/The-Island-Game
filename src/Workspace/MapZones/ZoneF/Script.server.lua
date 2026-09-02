--[[
    Script (Script)
    Path: Workspace → MapZones → ZoneF
    Parent: ZoneF
    Properties:
        Disabled: false
        RunContext: Enum.RunContext.Legacy
    Exported: 2026-09-02 16:23:32
]]
local zone = script.Parent
local prompt = zone:WaitForChild("ProximityPrompt")

local remote = game.ReplicatedStorage:WaitForChild("ZoneUpdate")
local gameRunning = game.ReplicatedStorage:WaitForChild("GameRunning")

local TeamScore = require(game.ServerScriptService:WaitForChild("TeamScoreManager"))

local owner = nil
local captureId = 0

local UPDATE_RATE = 0.05
local DISTANCE_LIMIT = 15

prompt.PromptButtonHoldBegan:Connect(function(player)
	if not player.Team then return end

	local teamName = player.Team.Name

	-- ❌ si ya es dueño
	if owner == teamName then return end

	-- 🔥 nueva sesión de captura
	captureId += 1
	local currentId = captureId

	local state = owner and owner ~= teamName and "Re-Capture" or "Capturing"

	local startTime = tick()
	local duration = prompt.HoldDuration

	task.spawn(function()
		while true do
			task.wait(UPDATE_RATE)

			-- ❌ si ya no es la sesión actual → matar loop
			if currentId ~= captureId then return end

			if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
				break
			end

			local dist = (player.Character.HumanoidRootPart.Position - zone.Position).Magnitude
			if dist > DISTANCE_LIMIT then
				break
			end

			local progress = (tick() - startTime) / duration

			remote:FireAllClients({
				zone = zone.Name,
				progress = math.clamp(progress, 0, 1),
				state = state,
				color = teamName
			})

			if progress >= 0.9 then
				-- 🔥 finalizar captura
				captureId += 1
				owner = teamName

				-- 🔥 guardar owner para ZoneResetManager
				zone:SetAttribute("Owner", owner)

				-- 🟣 puntos equipo SOLO si la ronda está activa
				if gameRunning.Value then
					TeamScore.AddPoints(owner, 5)
				end

				remote:FireAllClients({
					zone = zone.Name,
					progress = 1,
					state = "Captured",
					color = owner
				})

				return
			end
		end

		-- 🔴 cancelar captura
		if currentId == captureId then
			captureId += 1

			remote:FireAllClients({
				zone = zone.Name,
				progress = owner and 1 or 0,
				state = owner and "Captured" or "Capture",
				color = owner or "Neutral"
			})
		end
	end)
end)

prompt.PromptButtonHoldEnded:Connect(function()
	-- 🔥 cancelar captura inmediatamente
	captureId += 1

	remote:FireAllClients({
		zone = zone.Name,
		progress = owner and 1 or 0,
		state = owner and "Captured" or "Capture",
		color = owner or "Neutral"
	})
end)

-- 🟣 GENERACIÓN DE PUNTOS POR CONTROL (EQUIPO)
task.spawn(function()
	while true do
		task.wait(2)

		-- ❌ NO sumar puntos si la ronda terminó
		if not gameRunning.Value then
			continue
		end

		if owner then
			TeamScore.AddPoints(owner, 1)
		end
	end
end)