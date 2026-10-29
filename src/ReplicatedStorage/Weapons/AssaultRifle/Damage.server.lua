local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local tool = script.Parent
local remote = tool:WaitForChild("FireEvent")

-- 🔥 hitmarker
local hitmarkerRemote =
	game.ReplicatedStorage:WaitForChild("HitmarkerEvent")
local killConfirmedRemote =
	game.ReplicatedStorage:WaitForChild("KillConfirmedEvent")
local killFeedRemote =
	game.ReplicatedStorage:WaitForChild("KillFeedEvent")

local SHOT_INTERVAL = 0.075
local MAX_ORIGIN_DISTANCE = 8
local MAX_RAY_DISTANCE = 2000
local lastShotAt = 0

remote.OnServerEvent:Connect(function(player, origin, direction)
	local now = os.clock()
	if now - lastShotAt < SHOT_INTERVAL then
		return
	end

	if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
		return
	end

	local character = player.Character
	local attackerHumanoid = character and character:FindFirstChildOfClass("Humanoid")
	local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
	local head = character and character:FindFirstChild("Head")

	if tool.Parent ~= character
		or not attackerHumanoid
		or attackerHumanoid.Health <= 0
		or not playerRoot
		or not head
		or direction.Magnitude < 1
		or direction.Magnitude > MAX_RAY_DISTANCE
	then
		return
	end

	if (origin - head.Position).Magnitude > MAX_ORIGIN_DISTANCE then
		return
	end

	lastShotAt = now
	origin = head.Position
	direction = direction.Unit * MAX_RAY_DISTANCE

	--------------------------------------------------
	-- 🔥 SONIDO GLOBAL
	--------------------------------------------------

	if character then

		local root =
			character:FindFirstChild("HumanoidRootPart")

		if root then

			local sound =
				tool:WaitForChild("Gunshot"):Clone()

			sound.Parent = root
			sound:Play()

			Debris:AddItem(sound, 2)
		end
	end

	--------------------------------------------------
	-- 🔥 RAYCAST
	--------------------------------------------------

	local params = RaycastParams.new()

	params.FilterDescendantsInstances = {player.Character}

	-- 🔥 API nueva
	params.FilterType =
		Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(origin, direction, params)

	if result then

		local hit = result.Instance

		local hitCharacter =
			hit:FindFirstAncestorOfClass("Model")

		if hitCharacter then

			local humanoid =
				hitCharacter:FindFirstChild("Humanoid")

			--------------------------------------------------
			-- 🔥 EVITAR SELF DAMAGE
			--------------------------------------------------

			if humanoid
				and hitCharacter ~= player.Character then

				local targetPlayer = Players:GetPlayerFromCharacter(hitCharacter)
				if targetPlayer and player.Team and targetPlayer.Team
					and player.Team == targetPlayer.Team then
					return
				end

				--------------------------------------------------
				-- 🔥 TAG DEL ATACANTE
				--------------------------------------------------

				local oldTag =
					humanoid:FindFirstChild("creator")

				if oldTag then
					oldTag:Destroy()
				end

				local creatorTag =
					Instance.new("ObjectValue")

				creatorTag.Name = "creator"
				creatorTag.Value = player
				creatorTag.Parent = humanoid

				Debris:AddItem(creatorTag, 2)

				--------------------------------------------------
				-- 🛑 EVITAR MULTIPLE CONEXIÓN
				--------------------------------------------------

				if not humanoid:FindFirstChild("KillConnected") then

					local flag =
						Instance.new("BoolValue")

					flag.Name = "KillConnected"
					flag.Parent = humanoid

					humanoid.Died:Connect(function()

						local tag =
							humanoid:FindFirstChild("creator")

						if tag and tag.Value then

							local killer = tag.Value

							if killer:FindFirstChild("leaderstats") then

								local kills =
									killer.leaderstats:FindFirstChild("Kills")

								if kills then
									kills.Value += 1
								end
							end

							killConfirmedRemote:FireClient(killer, {
								targetName = Players:GetPlayerFromCharacter(hitCharacter)
									and Players:GetPlayerFromCharacter(hitCharacter).DisplayName
									or hitCharacter.Name,
							})

							local targetPlayer = Players:GetPlayerFromCharacter(hitCharacter)
							killFeedRemote:FireAllClients({
								killerName = killer.DisplayName,
								victimName = targetPlayer and targetPlayer.DisplayName or hitCharacter.Name,
								killerTeam = killer.Team and killer.Team.Name or "Neutral",
								victimTeam = targetPlayer and targetPlayer.Team and targetPlayer.Team.Name or "Neutral",
							})
						end
					end)
				end

				--------------------------------------------------
				-- 💥 DAMAGE
				--------------------------------------------------

				humanoid:TakeDamage(20)

				--------------------------------------------------
				-- 🔥 HITMARKER
				--------------------------------------------------

				hitmarkerRemote:FireClient(player)
			end
		end
	end
end)
