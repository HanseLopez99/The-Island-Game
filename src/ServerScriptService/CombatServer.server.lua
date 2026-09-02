--[[
    CombatServer (Script)
    Path: ServerScriptService
    Parent: ServerScriptService
    Properties:
        Disabled: false
        RunContext: Enum.RunContext.Legacy
    Exported: 2026-09-02 16:23:32
]]
local remote = game.ReplicatedStorage:WaitForChild("HitEvent")

local DAMAGE = 25
local KNOCKBACK_FORCE = 60

remote.OnServerEvent:Connect(function(player, enemy)
	print("Evento recibido", enemy)

	if typeof(enemy) ~= "Instance" then return end
	if not enemy:IsDescendantOf(workspace) then return end

	local humanoid = enemy:FindFirstChild("Humanoid")
	local root = enemy:FindFirstChild("HumanoidRootPart")
	local character = player.Character

	if not humanoid or not root or not character then 
		warn("Falta humanoid o root")
		return 
	end

	local playerRoot = character:FindFirstChild("HumanoidRootPart")
	if not playerRoot then return end

	local distance = (playerRoot.Position - root.Position).Magnitude
	if distance > 10 then 
		warn("Muy lejos")
		return 
	end

	-- 🔥 OBTENER JUGADOR ENEMIGO
	local enemyPlayer = game.Players:GetPlayerFromCharacter(enemy)

	-- ❌ EVITAR FUEGO AMIGO
	if enemyPlayer and player.Team and enemyPlayer.Team then
		if player.Team == enemyPlayer.Team then
			print("Fuego amigo bloqueado")
			return
		end
	end

	print("Aplicando daño")

	-- 🔥 TAG DEL ATACANTE (REEMPLAZA EL ANTERIOR)
	local oldTag = humanoid:FindFirstChild("creator")
	if oldTag then
		oldTag:Destroy()
	end

	local creatorTag = Instance.new("ObjectValue")
	creatorTag.Name = "creator"
	creatorTag.Value = player
	creatorTag.Parent = humanoid

	game.Debris:AddItem(creatorTag, 2)

	-- 🛑 EVITAR MULTIPLE CONEXIÓN DE MUERTE
	if not humanoid:FindFirstChild("KillConnected") then
		local flag = Instance.new("BoolValue")
		flag.Name = "KillConnected"
		flag.Parent = humanoid

		humanoid.Died:Connect(function()
			local tag = humanoid:FindFirstChild("creator")

			if tag and tag.Value then
				local killer = tag.Value

				if killer:FindFirstChild("leaderstats") then
					local kills = killer.leaderstats:FindFirstChild("Kills")
					if kills then
						kills.Value += 1
					end
				end
			end
		end)
	end

	-- 💥 DAÑO
	humanoid:TakeDamage(DAMAGE)

	-- 💥 KNOCKBACK
	local direction = (root.Position - playerRoot.Position).Unit

	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = direction * KNOCKBACK_FORCE + Vector3.new(0, 20, 0)
	bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bodyVelocity.Parent = root

	game.Debris:AddItem(bodyVelocity, 0.2)
end)