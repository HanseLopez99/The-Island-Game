--[[
    Fight (LocalScript)
    Path: ServerStorage → Sword
    Parent: Sword
    Properties:
        Disabled: false
    Exported: 2026-09-02 16:23:32
]]
local tool = script.Parent
local handle = tool:WaitForChild("Handle")
local animation = tool:WaitForChild("Animation")

local remote = game.ReplicatedStorage:WaitForChild("HitEvent")

local RANGE = 5
local attacking = false
local hitTargets = {}

local function raycastAttack()
	local character = tool.Parent
	if not character then return end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {character}
	params.FilterType = Enum.RaycastFilterType.Exclude

	-- 🔥 varios puntos (simula la hoja)
	local offsets = {
		Vector3.new(0, 0, 0),
		Vector3.new(0, 1, 0),
		Vector3.new(0, 2, 0),
	}

	for _, offset in ipairs(offsets) do
		local origin = handle.Position + handle.CFrame.UpVector * offset.Y
		local direction = handle.CFrame.LookVector * 6

		local result = workspace:Raycast(origin, direction, params)

		if result then
			local enemy = result.Instance:FindFirstAncestorOfClass("Model")
			local humanoid = enemy and enemy:FindFirstChild("Humanoid")

			if humanoid and not hitTargets[humanoid] then
				hitTargets[humanoid] = true

				print("Hit mejorado:", enemy.Name)

				remote:FireServer(enemy)
			end
		end
	end
end

tool.Activated:Connect(function()
	if attacking then return end
	attacking = true
	hitTargets = {}

	local character = tool.Parent
	local humanoid = character:FindFirstChild("Humanoid")

	if humanoid then
		local animator = humanoid:FindFirstChildOfClass("Animator")

		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = humanoid
		end

		local track = animator:LoadAnimation(animation)
		track.Priority = Enum.AnimationPriority.Action
		track:Play()

		task.wait(0.2)

		for i = 1, 5 do
			raycastAttack()
			task.wait(0.05)
		end
	end

	task.wait(0.8)
	attacking = false
end)