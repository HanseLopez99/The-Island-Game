--[[
    Script (Script)
    Path: Workspace → Decoration → CampfireStructure → FireDamageArea
    Parent: FireDamageArea
    Properties:
        Disabled: false
        RunContext: Enum.RunContext.Legacy
    Exported: 2026-09-02 16:23:32
]]
local damage = 10
local burnTime = 3 -- segundos que sigue quemándose
local playersBurning = {}

script.Parent.Touched:Connect(function(hit)
	local character = hit.Parent
	local humanoid = character:FindFirstChild("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")

	if humanoid and rootPart and not playersBurning[character] then
		playersBurning[character] = true

		-- 🔥 Crear fuego
		local fire = Instance.new("Fire")
		fire.Size = 6
		fire.Heat = 10
		fire.Parent = rootPart

		-- Guardamos referencia
		local burnEnd = tick() + burnTime

		task.spawn(function()
			while humanoid.Health > 0 do
				humanoid:TakeDamage(damage)
				task.wait(1)

				-- Si ya pasó el tiempo de quemadura y no está tocando el fuego
				if tick() > burnEnd then
					break
				end
			end

			-- 🧯 Quitar efecto
			if fire then
				fire:Destroy()
			end

			playersBurning[character] = nil
		end)
	end
end)