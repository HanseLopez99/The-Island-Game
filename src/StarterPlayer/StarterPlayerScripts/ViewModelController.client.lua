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
local CombatState = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CombatState"))

local function developerToolsOpen()
	return player:GetAttribute("DeveloperToolsOpen") == true
end

local currentVM = nil
local equippedTool = nil
local endgameOpen = false

--------------------------------------------------
-- RECOIL
--------------------------------------------------

local recoilOffset = CFrame.new()
local recoilRotation = CFrame.Angles(0, 0, 0)
local recoilEvent = ReplicatedStorage:WaitForChild("RecoilEvent")

-- ADS is owned by CombatState. This controller only renders it.
--------------------------------------------------

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
		CombatState.SetAiming(true)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if developerToolsOpen() then
		CombatState.Reset()
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		if not CombatState.ADSLocked then
			CombatState.SetAiming(false)
		end
	end
end)

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
	if CombatState.Aiming then
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
	CombatState.SetFiring(false)
	if not CombatState.ADSLocked then
		CombatState.SetAiming(false)
	end
end

--------------------------------------------------
-- TOOL DETECTION
--------------------------------------------------

local function setupCharacter(char)
	endgameOpen = false
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	CombatState.Reset()
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

	-- The tool may already be equipped before CharacterAdded/ChildAdded hooks
	-- finish connecting after a respawn.
	for _, child in ipairs(char:GetChildren()) do
		if child:IsA("Tool") and child.Name == "AssaultRifle" then
			equipViewModel(child)
			break
		end
	end
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
		CombatState.Reset()

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

	if CombatState.Reloading then
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

	elseif CombatState.Aiming then
		currentOffset = currentOffset:Lerp(adsOffset, 0.15)
		camera.FieldOfView = camera.FieldOfView + (50 - camera.FieldOfView) * 0.15
		local positionReady = (currentOffset.Position - adsOffset.Position).Magnitude < 0.025
		CombatState.SetADSReady(positionReady)

		--------------------------------------------------
		-- HIPFIRE
		--------------------------------------------------

	else
		currentOffset = currentOffset:Lerp(hipOffset, 0.15)
		camera.FieldOfView = camera.FieldOfView + (70 - camera.FieldOfView) * 0.15
		CombatState.SetADSReady(false)
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
