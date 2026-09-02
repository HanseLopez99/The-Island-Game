--[[
    WeaponHUDController (LocalScript)
    Path: StarterGui → WeaponHUD
    Parent: WeaponHUD
    Properties:
        Disabled: false
    Exported: 2026-09-02 16:23:32
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local weaponData = require(ReplicatedStorage:WaitForChild("WeaponData"))
local viewportRenderer = require(
	ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ViewportRenderer")
)
local previewWeapons = ReplicatedStorage:WaitForChild("Weapons")

local weaponHUD = script.Parent
local weaponBar = weaponHUD:WaitForChild("WeaponBar")

local MAX_SLOTS = 5
local UPDATE_DELAY = 0.05

local slots = table.create(MAX_SLOTS)
local slotConnections = {}
local characterConnections = {}
local backpackConnections = {}
local updateQueued = false
local backpack
local character

for slotIndex = 1, MAX_SLOTS do
	slots[slotIndex] = weaponBar:WaitForChild("Slot" .. slotIndex)
end

local function disconnectAll(connections)
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	table.clear(connections)
end

local function getSlotButton(slot)
	if slot:IsA("GuiButton") then
		return slot
	end

	return slot:FindFirstChildWhichIsA("GuiButton", true)
end

local function setSelection(slot, selected)
	local selection = slot:FindFirstChild("Selection")
	if selection and selection:IsA("GuiObject") then
		selection.Visible = selected
	end

	local stroke = selection and selection:FindFirstChildWhichIsA("UIStroke", true)
	if stroke then
		stroke.Enabled = selected
	end
end

local function clearViewport(slot)
	local viewport = slot:FindFirstChild("WeaponViewport")
	if viewport and viewport:IsA("ViewportFrame") then
		viewport:ClearAllChildren()
	end
end

local function clearSlot(slot)
	slot.Visible = false
	setSelection(slot, false)
	clearViewport(slot)
	slot:SetAttribute("WeaponName", nil)
	slot:SetAttribute("WeaponSlot", nil)
end

local function getDefinitionsBySlot()
	local definitions = table.create(MAX_SLOTS)

	for weaponName, definition in pairs(weaponData) do
		if type(definition) == "table" then
			local slotIndex = definition.Slot
			if type(slotIndex) == "number" and slotIndex >= 1 and slotIndex <= MAX_SLOTS then
				if definitions[slotIndex] then
					warn(string.format(
						"WeaponHUDController: duplicate WeaponData slot %d (%s and %s)",
						slotIndex,
						definitions[slotIndex].weaponName,
						weaponName
						))
				else
					definitions[slotIndex] = {
						weaponName = weaponName,
						toolName = definition.ToolName or weaponName,
						config = definition,
					}
				end
			end
		end
	end

	return definitions
end

local function findTool(toolName)
	if character then
		local equippedTool = character:FindFirstChild(toolName)
		if equippedTool and equippedTool:IsA("Tool") then
			return equippedTool
		end
	end

	if backpack then
		local storedTool = backpack:FindFirstChild(toolName)
		if storedTool and storedTool:IsA("Tool") then
			return storedTool
		end
	end

	return nil
end

local function equipSlot(slotIndex)
	local definition = getDefinitionsBySlot()[slotIndex]
	if not definition then
		return
	end

	local tool = findTool(definition.toolName)
	if not tool or not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	if tool.Parent == backpack then
		humanoid:EquipTool(tool)
	end
end

local updateHUD

local function scheduleUpdate()
	if updateQueued then
		return
	end

	updateQueued = true
	task.delay(UPDATE_DELAY, function()
		updateQueued = false
		if updateHUD then
			updateHUD()
		end
	end)
end

local function connectSlotButtons()
	disconnectAll(slotConnections)

	for slotIndex, slot in ipairs(slots) do
		local button = getSlotButton(slot)
		if button then
			table.insert(slotConnections, button.Activated:Connect(function()
				equipSlot(slotIndex)
				scheduleUpdate()
			end))
		else
			warn("WeaponHUDController: no GuiButton found in " .. slot.Name)
		end
	end
end

updateHUD = function()
	local definitionsBySlot = getDefinitionsBySlot()

	for slotIndex, slot in ipairs(slots) do
		clearSlot(slot)

		local definition = definitionsBySlot[slotIndex]
		if definition then
			local tool = findTool(definition.toolName)
			if tool then
				local viewport = slot:FindFirstChild("WeaponViewport")
				if not viewport or not viewport:IsA("ViewportFrame") then
					warn("WeaponHUDController: missing ViewportFrame in " .. slot.Name)
				else
					slot.Visible = true
					slot:SetAttribute("WeaponName", definition.toolName)
					slot:SetAttribute("WeaponSlot", slotIndex)

					local ok, renderError = pcall(function()
						-- Render the same preview asset used by DeveloperTools. The
						-- gameplay Tool remains separate and is only used for equipping.
						local previewTool = previewWeapons:FindFirstChild(definition.toolName)
						if not previewTool then
							error("missing preview asset ReplicatedStorage.Weapons." .. definition.toolName)
						end
						viewportRenderer.RenderTool(viewport, previewTool, definition.config)
					end)
					if not ok then
						warn("WeaponHUDController: failed to render " .. definition.toolName .. ": " .. tostring(renderError))
					end

					setSelection(slot, tool.Parent == character)
				end
			end
		end
	end
end

local function watchBackpack(newBackpack)
	disconnectAll(backpackConnections)
	backpack = newBackpack

	if backpack then
		table.insert(backpackConnections, backpack.ChildAdded:Connect(scheduleUpdate))
		table.insert(backpackConnections, backpack.ChildRemoved:Connect(scheduleUpdate))
	end
end

local function watchCharacter(newCharacter)
	disconnectAll(characterConnections)
	character = newCharacter

	if character then
		table.insert(characterConnections, character.ChildAdded:Connect(scheduleUpdate))
		table.insert(characterConnections, character.ChildRemoved:Connect(scheduleUpdate))
	end

	scheduleUpdate()
end

player.CharacterAdded:Connect(function(newCharacter)
	watchCharacter(newCharacter)
	watchBackpack(player:WaitForChild("Backpack"))
end)

player.CharacterRemoving:Connect(function()
	watchCharacter(nil)
	scheduleUpdate()
end)

player.ChildAdded:Connect(function(child)
	if child:IsA("Backpack") then
		watchBackpack(child)
		scheduleUpdate()
	end
end)

backpack = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack")
watchBackpack(backpack)
watchCharacter(player.Character)
connectSlotButtons()
updateHUD()