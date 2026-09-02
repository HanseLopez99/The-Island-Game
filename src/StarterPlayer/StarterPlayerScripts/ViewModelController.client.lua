--[[
    ViewModelController (LocalScript)
    Path: StarterPlayer → StarterPlayerScripts
    Parent: StarterPlayerScripts
    Properties:
        Disabled: false
    Exported: 2026-09-02 16:23:32
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local function developerToolsOpen()
	return player:GetAttribute("DeveloperToolsOpen") == true
end

--------------------------------------------------
-- MOBILE UI
--------------------------------------------------

local playerGui = player:WaitForChild("PlayerGui")
local mobileGui = playerGui:WaitForChild("MobileFireGui")
local aimButton = mobileGui:WaitForChild("AimButton")

local currentVM = nil
local equippedTool = nil
local endgameOpen = false

--------------------------------------------------
-- RECOIL
--------------------------------------------------

local recoilOffset = CFrame.new()
local recoilRotation = CFrame.Angles(0, 0, 0)
local recoilEvent = ReplicatedStorage:WaitForChild("RecoilEvent")

--------------------------------------------------
-- RELOAD
--------------------------------------------------

local reloadEvent = ReplicatedStorage:WaitForChild("ReloadEvent")
local reloadingVM = false

--------------------------------------------------
-- ADS
--------------------------------------------------

local aiming = false

--------------------------------------------------
-- VIEWMODEL POSITIONS
--------------------------------------------------

local hipOffset =
	CFrame.new(1.0, -1.0, -3.0)
	* CFrame.Angles(math.rad(0), math.rad(90), math.rad(0))

local adsOffset =
	CFrame.new(0, -0.89, -1.15)
	* CFrame.Angles(math.rad(0), math.rad(90), math.rad(0))

local currentOffset = hipOffset

--------------------------------------------------
-- CURSOR
--------------------------------------------------

UserInputService.MouseIconEnabled = false

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Escape then
		UserInputService.MouseIconEnabled = true
	end
end)

--------------------------------------------------
-- ADS INPUT PC
--------------------------------------------------

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if developerToolsOpen() or gameProcessed then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		aiming = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if developerToolsOpen() then
		aiming = false
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		aiming = false
	end
end)

--------------------------------------------------
-- ADS MOBILE
--------------------------------------------------

aimButton.MouseButton1Down:Connect(function()
	if developerToolsOpen() then
		return
	end

	aiming = true
end)

aimButton.MouseButton1Up:Connect(function()
	aiming = false
end)

if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
	aimButton.Visible = true
else
	aimButton.Visible = false
end

--------------------------------------------------
-- ENDGAME
--------------------------------------------------

local endgameRemote = ReplicatedStorage:WaitForChild("EndgameEvent")
endgameRemote.OnClientEvent:Connect(function()
	endgameOpen = true
end)

--------------------------------------------------
-- RECOIL FUNCTION
--------------------------------------------------

local function applyRecoil()
	if aiming then
		recoilOffset = CFrame.new(0, 0, 0.04)
		recoilRotation = CFrame.Angles(
			math.rad(-0.4),
			math.rad(math.random(-1, 1) * 0.3),
			0
		)
	else
		recoilOffset = CFrame.new(0, 0, 0.15)
		recoilRotation = CFrame.Angles(
			math.rad(-2),
			math.rad(math.random(-1, 1)),
			0
		)
	end
end

--------------------------------------------------
-- RECOIL + MUZZLE
--------------------------------------------------

recoilEvent.Event:Connect(function()
	if developerToolsOpen() then
		return
	end

	applyRecoil()

	if currentVM then
		local handle = currentVM:FindFirstChild("Handle")
		if handle then
			local attachment = handle:FindFirstChild("MuzzleAttachment")
			if attachment then
				local muzzle = attachment:FindFirstChild("MuzzleFlash")
				if muzzle then
					muzzle:Emit(1)
				end
			end
		end
	end
end)

--------------------------------------------------
-- RELOAD ANIMATION EVENT
--------------------------------------------------

reloadEvent.Event:Connect(function()
	if developerToolsOpen() then
		return
	end

	reloadingVM = true
	task.delay(1.1, function()
		reloadingVM = false
	end)
end)

--------------------------------------------------
-- CREATE VIEWMODEL
--------------------------------------------------

local function equipViewModel(tool)
	if currentVM then
		currentVM:Destroy()
	end

	local vmFolder = ReplicatedStorage:WaitForChild("ViewModels")
	local rifleVM = vmFolder:WaitForChild("RifleVM"):Clone()
	rifleVM.Parent = camera

	local handle = rifleVM:WaitForChild("Handle")
	rifleVM.PrimaryPart = handle

	currentVM = rifleVM
	equippedTool = tool

	local realHandle = tool:FindFirstChild("Handle")
	if realHandle then
		realHandle.LocalTransparencyModifier = 1
	end

	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		aimButton.Visible = true
	end
end

--------------------------------------------------
-- REMOVE VIEWMODEL
--------------------------------------------------

local function unequipViewModel()
	if currentVM then
		currentVM:Destroy()
		currentVM = nil
	end

	if equippedTool then
		local realHandle = equippedTool:FindFirstChild("Handle")
		if realHandle then
			realHandle.LocalTransparencyModifier = 0
		end
	end

	equippedTool = nil
	aimButton.Visible = false
end

--------------------------------------------------
-- TOOL DETECTION
--------------------------------------------------

local function setupCharacter(char)
	endgameOpen = false
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	unequipViewModel()

	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child.Name == "AssaultRifle" then
			equipViewModel(child)
		end
	end)

	char.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and child == equippedTool then
			unequipViewModel()
		end
	end)
end

player.CharacterAdded:Connect(function(char)
	unequipViewModel()
	setupCharacter(char)
end)

if player.Character then
	setupCharacter(player.Character)
end

--------------------------------------------------
-- FPS LOOP
--------------------------------------------------

RunService.RenderStepped:Connect(function()
	--------------------------------------------------
	-- DEVELOPER TOOLS MODE
	--------------------------------------------------

	if developerToolsOpen() then
		aiming = false
		reloadingVM = false

		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true

		-- Hide the gameplay ViewModel while the debugger is open.
		if currentVM then
			currentVM.Parent = nil
		end

		return
	end

	-- Restore the ViewModel after closing DeveloperTools.
	if currentVM and currentVM.Parent == nil then
		currentVM.Parent = camera
	end

	--------------------------------------------------
	-- ENDGAME
	--------------------------------------------------

	if endgameOpen then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		return
	end

	--------------------------------------------------
	-- NORMAL FPS MODE
	--------------------------------------------------

	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false

	--------------------------------------------------
	-- RELOAD ANIMATION
	--------------------------------------------------

	if reloadingVM then
		currentOffset = currentOffset:Lerp(
			hipOffset
				* CFrame.new(0.4, -0.5, 0.5)
				* CFrame.Angles(math.rad(25), math.rad(35), math.rad(45)),
			0.12
		)

		camera.FieldOfView = camera.FieldOfView + (70 - camera.FieldOfView) * 0.15

		--------------------------------------------------
		-- ADS TRANSITION
		--------------------------------------------------

	elseif aiming then
		currentOffset = currentOffset:Lerp(adsOffset, 0.15)
		camera.FieldOfView = camera.FieldOfView + (50 - camera.FieldOfView) * 0.15

		--------------------------------------------------
		-- HIPFIRE
		--------------------------------------------------

	else
		currentOffset = currentOffset:Lerp(hipOffset, 0.15)
		camera.FieldOfView = camera.FieldOfView + (70 - camera.FieldOfView) * 0.15
	end

	--------------------------------------------------
	-- VIEWMODEL
	--------------------------------------------------

	if currentVM then
		currentVM:PivotTo(
			camera.CFrame
				* currentOffset
				* recoilRotation
				* recoilOffset
		)
	end

	--------------------------------------------------
	-- SMOOTH RECOIL
	--------------------------------------------------

	recoilOffset = recoilOffset:Lerp(CFrame.new(), 0.15)
	recoilRotation = recoilRotation:Lerp(CFrame.Angles(0, 0, 0), 0.15)
end)