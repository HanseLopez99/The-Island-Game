local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local CombatState = require(
	ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CombatState")
)

local WALK_SPEED = 30
local SPRINT_SPEED = 46
local SLIDE_SPEED = 58

local DEFAULT_FOV = 70
local SPRINT_FOV = 82
local SLIDE_FOV = 88

local SLIDE_DURATION = 0.85
local SLIDE_COOLDOWN = 0.35
local SLIDE_CAMERA_DROP = -0.9

-- Se pueden añadir assets más adelante sin cambiar la lógica del sistema.
local SPRINT_ANIMATION_ID = ""
local SLIDE_ANIMATION_ID = ""

local humanoid
local rootPart
local defaultHipHeight = 2
local sprintHeld = false
local sliding = false
local slideCooldownUntil = 0
local slideToken = 0
local sprintTrack
local slideTrack
local windBlur
local slideDirection = Vector3.zero
local slideStartedAt = 0
local cameraTime = 0

local function developerToolsOpen()
	return player:GetAttribute("DeveloperToolsOpen") == true
end

local function getCamera()
	local camera = workspace.CurrentCamera
	if not camera then
		return nil
	end

	if not windBlur then
		windBlur = Instance.new("BlurEffect")
		windBlur.Name = "SprintWindBlur"
		windBlur.Size = 0
		windBlur.Enabled = false
	end

	if windBlur.Parent ~= camera then
		windBlur.Parent = camera
	end

	return camera
end

local function loadAnimation(animationId)
	if not humanoid or animationId == "" then
		return nil
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://" .. animationId

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	return animator:LoadAnimation(animation)
end

local function stopTrack(track)
	if track and track.IsPlaying then
		track:Stop(0.12)
	end
end

local function stopMovementEffects()
	stopTrack(sprintTrack)
	stopTrack(slideTrack)
	sprintTrack = nil
	slideTrack = nil

	if windBlur then
		windBlur.Enabled = false
		windBlur.Size = 0
	end
end

local function onCharacter(character)
	sliding = false
	sprintHeld = false
	slideToken += 1

	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
	defaultHipHeight = humanoid.HipHeight
	humanoid.WalkSpeed = WALK_SPEED
	humanoid.AutoRotate = true
	humanoid.CameraOffset = Vector3.zero

	stopMovementEffects()
	CombatState.Reset()

	sprintTrack = loadAnimation(SPRINT_ANIMATION_ID)
	slideTrack = loadAnimation(SLIDE_ANIMATION_ID)
end

local function canSprint()
	return humanoid
		and humanoid.Health > 0
		and not developerToolsOpen()
		and not sliding
		and sprintHeld
		and humanoid.MoveDirection.Magnitude > 0.05
		and not CombatState.Aiming
		and not CombatState.Firing
		and not CombatState.Reloading
end

local function canSlide()
	return humanoid
		and rootPart
		and humanoid.Health > 0
		and not developerToolsOpen()
		and not sliding
		and os.clock() >= slideCooldownUntil
		and humanoid.MoveDirection.Magnitude > 0.05
		and not CombatState.Aiming
		and not CombatState.Firing
		and not CombatState.Reloading
end

local function finishSlide(token)
	if token ~= slideToken or not humanoid then
		return
	end

	sliding = false
	humanoid.HipHeight = defaultHipHeight
	humanoid.CameraOffset = Vector3.zero
	humanoid.AutoRotate = true
	stopTrack(slideTrack)
end

local function startSlide()
	if not canSlide() then
		return
	end

	sliding = true
	slideCooldownUntil = os.clock() + SLIDE_COOLDOWN
	slideToken += 1
	local token = slideToken
	slideStartedAt = os.clock()
	slideDirection = humanoid.MoveDirection
	if slideDirection.Magnitude < 0.05 then
		slideDirection = rootPart.CFrame.LookVector
	end
	slideDirection = Vector3.new(slideDirection.X, 0, slideDirection.Z).Unit

	humanoid.HipHeight = math.max(0.5, defaultHipHeight - 0.65)
	humanoid.CameraOffset = Vector3.new(0, SLIDE_CAMERA_DROP, 0)
	humanoid.AutoRotate = false
	rootPart.AssemblyLinearVelocity = Vector3.new(
		slideDirection.X * SLIDE_SPEED,
		rootPart.AssemblyLinearVelocity.Y,
		slideDirection.Z * SLIDE_SPEED
	)

	local facing = CFrame.lookAt(rootPart.Position, rootPart.Position + slideDirection)
	rootPart.CFrame = CFrame.new(rootPart.Position) * facing.Rotation

	if slideTrack then
		slideTrack:Play(0.08, 1, 1)
	end

	task.delay(SLIDE_DURATION, function()
		finishSlide(token)
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if developerToolsOpen() then
		return
	end

	if input.KeyCode == Enum.KeyCode.LeftShift then
		sprintHeld = true
	elseif input.KeyCode == Enum.KeyCode.LeftControl then
		startSlide()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		sprintHeld = false
	end
end)

player.CharacterAdded:Connect(onCharacter)

if player.Character then
	onCharacter(player.Character)
end

RunService.RenderStepped:Connect(function(deltaTime)
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	cameraTime += deltaTime
	local camera = getCamera()
	local sprinting = canSprint()
	local targetSpeed = WALK_SPEED
	local targetFov = DEFAULT_FOV

	if sliding then
		local elapsed = os.clock() - slideStartedAt
		local progress = math.clamp(elapsed / SLIDE_DURATION, 0, 1)
		local momentum = SLIDE_SPEED * (1 - progress * 0.72)
		local yVelocity = rootPart.AssemblyLinearVelocity.Y
		rootPart.AssemblyLinearVelocity = Vector3.new(
			slideDirection.X * momentum,
			yVelocity,
			slideDirection.Z * momentum
		)
		targetSpeed = 0
		targetFov = SLIDE_FOV
	elseif sprinting then
		targetSpeed = SPRINT_SPEED
		targetFov = SPRINT_FOV
	end

	humanoid.WalkSpeed = targetSpeed

	if sliding then
		humanoid.CameraOffset = Vector3.new(0, SLIDE_CAMERA_DROP, 0)
	elseif sprinting then
		local bob = math.sin(cameraTime * 15) * 0.06
		humanoid.CameraOffset = Vector3.new(0, bob, 0)
	else
		humanoid.CameraOffset = Vector3.zero
	end

	if sprinting and sprintTrack and not sprintTrack.IsPlaying then
		sprintTrack:Play(0.15, 1, 1)
	elseif not sprinting then
		stopTrack(sprintTrack)
	end

	if camera then
		local blend = math.clamp(deltaTime * 8, 0, 1)
		camera.FieldOfView += (targetFov - camera.FieldOfView) * blend

		local windAmount = sliding and 4 or (sprinting and 2 or 0)
		if windAmount > 0 then
			windBlur.Enabled = true
			windBlur.Size += (windAmount - windBlur.Size) * blend
		else
			windBlur.Size += (0 - windBlur.Size) * blend
			if windBlur.Size < 0.05 then
				windBlur.Enabled = false
			end
		end
	end
end)
