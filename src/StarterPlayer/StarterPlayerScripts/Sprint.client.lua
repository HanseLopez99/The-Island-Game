local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local normalSpeed = 20
local sprintSpeed = 30

local normalFOV = 70
local sprintFOV = 85

local humanoid

--------------------------------------------------
-- 🔥 ESTADO
--------------------------------------------------

local sprinting = false
local sprintRequested = false

--------------------------------------------------
-- 🧍 PERSONAJE
--------------------------------------------------

local function onCharacter(char)

	humanoid = char:WaitForChild("Humanoid")
	humanoid.WalkSpeed = normalSpeed

	sprinting = false
	sprintRequested = false
end

player.CharacterAdded:Connect(onCharacter)

if player.Character then
	onCharacter(player.Character)
end

--------------------------------------------------
-- 🎬 CÁMARA
--------------------------------------------------

local function tweenFOV(target)

	TweenService:Create(
		camera,
		TweenInfo.new(0.2),
		{
			FieldOfView = target
		}
	):Play()
end

--------------------------------------------------
-- 🟢 START SPRINT
--------------------------------------------------

local function startSprint()

	if humanoid and not sprinting then

		sprinting = true
		humanoid.WalkSpeed = sprintSpeed
	end
end

--------------------------------------------------
-- 🔴 STOP SPRINT
--------------------------------------------------

local function stopSprint()

	if humanoid and sprinting then

		sprinting = false
		humanoid.WalkSpeed = normalSpeed
		tweenFOV(normalFOV)
	end
end

--------------------------------------------------
-- 💻 PC (SHIFT)
--------------------------------------------------

UserInputService.InputBegan:Connect(function(input, gameProcessed)

	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.LeftShift then

		sprintRequested = true
	end
end)

UserInputService.InputEnded:Connect(function(input)

	if input.KeyCode == Enum.KeyCode.LeftShift then

		sprintRequested = false
	end
end)

--------------------------------------------------
-- 📱 BOTÓN MÓVIL
--------------------------------------------------

local function sprintAction(actionName, inputState)

	if inputState == Enum.UserInputState.Begin then

		sprintRequested = true

	elseif inputState == Enum.UserInputState.End then

		sprintRequested = false
	end
end

ContextActionService:BindActionAtPriority(
	"Run",
	sprintAction,
	true,
	Enum.ContextActionPriority.High.Value,
	Enum.KeyCode.LeftShift
)

--------------------------------------------------
-- 📱 CONFIG BOTÓN
--------------------------------------------------

ContextActionService:SetTitle(
	"Run",
	"RUN"
)

ContextActionService:SetPosition(
	"Run",
	UDim2.new(0.94,0,0.97,0)
)

ContextActionService:SetImage(
	"Run",
	"rbxassetid://6031090990"
)

--------------------------------------------------
-- 🔥 LOOP
--------------------------------------------------

RunService.RenderStepped:Connect(function()

	if not humanoid then
		return
	end

	--------------------------------------------------
	-- 🔥 SI SHIFT SIGUE PRESIONADO
	--------------------------------------------------

	if sprintRequested then

		startSprint()

	else

		stopSprint()
	end

	--------------------------------------------------
	-- 🔥 FOV
	--------------------------------------------------

	if sprinting
		and humanoid.MoveDirection.Magnitude > 0 then

		if camera.FieldOfView ~= sprintFOV then
			tweenFOV(sprintFOV)
		end

	else

		if camera.FieldOfView ~= normalFOV then
			tweenFOV(normalFOV)
		end
	end
end)


print("Sprint system loaded")