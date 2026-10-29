local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local tool = script.Parent
local remote = tool:WaitForChild("FireEvent")

-- 🔥 hitmarker
local hitmarkerRemote =
	game.ReplicatedStorage:WaitForChild("HitmarkerEvent")
local killConfirmedRemote =
	game.ReplicatedStorage:WaitForChild("KillConfirmedEvent")

remote.OnServerEvent:Connect(function(player, origin, direction)

	--------------------------------------------------
	-- 🔥 SONIDO GLOBAL
	--------------------------------------------------

	local character = player.Character

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

	local result =
		workspace:Raycast(origin, direction, params)

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
