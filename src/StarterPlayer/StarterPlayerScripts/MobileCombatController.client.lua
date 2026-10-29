local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")
local mobileGui = playerGui:WaitForChild("MobileFireGui")
local fireButton = mobileGui:WaitForChild("FireButton")
local aimButton = mobileGui:WaitForChild("AimButton")
local reloadButton = mobileGui:FindFirstChild("ReloadButton", true)
local CombatState = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CombatState"))

-- Studio's device emulator can report KeyboardEnabled=true because the host
-- computer has a keyboard. TouchEnabled is the reliable mobile/emulator flag.
local mobileOnly = UserInputService.TouchEnabled
local fireHeld = false
local fireToken = 0
local fireTouch = nil

-- A touch that begins over a GuiButton is normally consumed by the UI. Keep
-- tracking that same touch so dragging the fire button can still rotate view.
-- Separate sensitivity for dragging while the fire button is held. This is
-- intentionally higher because the player is using a smaller touch area.
local CAMERA_TOUCH_SENSITIVITY = 0.25

local function trackFireTouch(input)
	fireTouch = input
end

local function releaseFireTouch(input)
	if input == fireTouch then
		fireTouch = nil
	end
end

local function blocked()
	return player:GetAttribute("DeveloperToolsOpen") == true
end

local function updateVisibility()
	local character = player.Character
	local equipped = character and character:FindFirstChild("AssaultRifle") ~= nil
	fireButton.Visible = mobileOnly and equipped
	aimButton.Visible = mobileOnly and equipped
	if reloadButton and reloadButton:IsA("GuiObject") then
		reloadButton.Visible = mobileOnly and equipped
	end
end

local function waitForADS(token)
	while fireHeld and token == fireToken and not blocked() do
		if CombatState.ADSLocked or CombatState.ADSReady then
			CombatState.SetFiring(true)
			return
		end
		RunService.RenderStepped:Wait()
	end
end

fireButton.InputBegan:Connect(function(input)
	if not mobileOnly or blocked() or input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	fireHeld = true
	trackFireTouch(input)
	fireToken += 1
	local token = fireToken
	if CombatState.ADSLocked then
		CombatState.SetFiring(true)
		return
	end
	CombatState.SetAiming(true)
	task.spawn(function()
		waitForADS(token)
	end)
end)

aimButton.Activated:Connect(function()
	if mobileOnly and not blocked() then
		CombatState.SetADSLocked(not CombatState.ADSLocked)
	end
end)

local function connectReloadButton(button)
	if not button or button:GetAttribute("CombatReloadConnected") then
		print("[MobileCombat] connectReloadButton skipped:", button and button.Name or "nil", "already connected:", button and button:GetAttribute("CombatReloadConnected"))
		return
	end
	button:SetAttribute("CombatReloadConnected", true)
	print("[MobileCombat] Connecting reload button:", button:GetFullName())
	button.Activated:Connect(function()
		print("[MobileCombat] Reload button Activated!")
		if not blocked() then
			CombatState.RequestReload()
		end
	end)
end

connectReloadButton(reloadButton)

UserInputService.TouchMoved:Connect(function(input)
	if input ~= fireTouch or blocked() then
		return
	end

	local delta = input.Delta
	if delta.Magnitude <= 0 then
		return
	end

	camera.CFrame = camera.CFrame
		* CFrame.Angles(
			math.rad(-delta.Y * CAMERA_TOUCH_SENSITIVITY),
			math.rad(-delta.X * CAMERA_TOUCH_SENSITIVITY),
			0
		)
end)

-- InputEnded on a GuiButton fires when the finger leaves the button. The
-- action must remain active while that same finger is still touching the
-- screen, so stop only on the global TouchEnded event.
UserInputService.TouchEnded:Connect(function(input)
	if input ~= fireTouch then
		return
	end

	fireHeld = false
	releaseFireTouch(input)
	fireToken += 1
	CombatState.SetFiring(false)
	if not CombatState.ADSLocked then
		CombatState.SetAiming(false)
	end
end)

local function bindMobileGui(newGui)
	if not newGui or newGui == mobileGui then
		return
	end

	mobileGui = newGui
	fireButton = mobileGui:WaitForChild("FireButton")
	aimButton = mobileGui:WaitForChild("AimButton")
	reloadButton = mobileGui:FindFirstChild("ReloadButton", true)

	fireButton.InputBegan:Connect(function(input)
		if not mobileOnly or blocked() or input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		fireHeld = true
		trackFireTouch(input)
		fireToken += 1
		local token = fireToken
		if CombatState.ADSLocked then
			CombatState.SetFiring(true)
			return
		end
		CombatState.SetAiming(true)
		task.spawn(function()
			waitForADS(token)
		end)
	end)

	aimButton.Activated:Connect(function()
		if mobileOnly and not blocked() then
			CombatState.SetADSLocked(not CombatState.ADSLocked)
		end
	end)

	connectReloadButton(reloadButton)
	updateVisibility()
end

mobileGui.ChildAdded:Connect(function(child)
	if child.Name == "ReloadButton" and child:IsA("GuiButton") then
		reloadButton = child
		connectReloadButton(child)
		updateVisibility()
	end
end)

mobileGui.DescendantAdded:Connect(function(child)
	if child.Name == "ReloadButton" and child:IsA("GuiButton") then
		reloadButton = child
		connectReloadButton(child)
		updateVisibility()
	end
end)

playerGui.ChildAdded:Connect(function(child)
	if child.Name == "MobileFireGui" then
		bindMobileGui(child)
	end
end)

playerGui.DescendantAdded:Connect(function(child)
	if child.Name == "ReloadButton" and child:IsA("GuiButton") then
		reloadButton = child
		connectReloadButton(child)
		updateVisibility()
	end
end)

player:GetAttributeChangedSignal("DeveloperToolsOpen"):Connect(function()
	if blocked() then
		fireHeld = false
		fireToken += 1
		CombatState.Reset()
	end
	updateVisibility()
end)

local function hookCharacter(character)
	fireHeld = false
	fireToken += 1
	CombatState.Reset()
	local currentGui = player:WaitForChild("PlayerGui"):FindFirstChild("MobileFireGui")
	if currentGui then
		bindMobileGui(currentGui)
	end
	character.ChildAdded:Connect(updateVisibility)
	character.ChildRemoved:Connect(updateVisibility)
	updateVisibility()
end

player.CharacterAdded:Connect(hookCharacter)
if player.Character then
	hookCharacter(player.Character)
end

updateVisibility()
