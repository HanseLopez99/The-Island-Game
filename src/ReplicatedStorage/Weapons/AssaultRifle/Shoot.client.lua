--[[
    Shoot (LocalScript)
    Path: ReplicatedStorage → Weapons → AssaultRifle
    Parent: AssaultRifle
    Properties:
        Disabled: false
    Exported: 2026-09-02 16:23:32
]]
print("[Shoot] Script starting, parent:", script.Parent.Name, "location:", script:GetFullName())

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
print("[Shoot] Got playerGui")
local camera = workspace.CurrentCamera

local tool = script.Parent
local remote = tool:WaitForChild("FireEvent")
print("[Shoot] Got FireEvent")
local CombatState = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CombatState"))
print("[Shoot] Got CombatState")

-- 🔥 recoil + muzzle
local recoilEvent = ReplicatedStorage:WaitForChild("RecoilEvent")
print("[Shoot] Got RecoilEvent")

--------------------------------------------------
-- 🔄 RELOAD
--------------------------------------------------

local reloadEvent =
	ReplicatedStorage:WaitForChild("ReloadEvent")
print("[Shoot] Got ReloadEvent")

local reloadSound =
	tool:WaitForChild("AssaultRifleReloadSound")
print("[Shoot] Got reloadSound")

--------------------------------------------------
-- 🔫 AMMO UI
--------------------------------------------------

local ammoGui =
	playerGui:WaitForChild("AmmoGui")
print("[Shoot] Got AmmoGui")

local container =
	ammoGui:WaitForChild("WeaponInfoContainer")

local ammoContainer =
	container:WaitForChild("AmmoContainer")

local ammoLabel =
	ammoContainer:WaitForChild("AmmoLabel")

local dividerLabel =
	ammoContainer:WaitForChild("DividerLabel")

local reserveLabel =
	ammoContainer:WaitForChild("ReserveLabel")

local weaponName =
	container:WaitForChild("WeaponName")
print("[Shoot] Got all UI elements")

--------------------------------------------------
-- 🔫 CONFIG
--------------------------------------------------

local FIRE_RATE = 0.08
local RELOAD_ANIMATION_TIME = 1.1

local firing = false
local equipped = false

--------------------------------------------------
-- 🔫 AMMO
--------------------------------------------------

local MAG_SIZE = 30

local currentAmmo = MAG_SIZE
local reserveAmmo = 120

local reloading = false
local reloadVersion = 0

--------------------------------------------------
-- 🔫 UPDATE UI
--------------------------------------------------

local function updateAmmoUI()

	ammoLabel.Text = tostring(currentAmmo)

	dividerLabel.Text = "/"

	reserveLabel.Text = tostring(reserveAmmo)

	weaponName.Text = "ASSAULT RIFLE"
end

--------------------------------------------------
-- 🔫 DISPARAR
--------------------------------------------------

local function shoot()

	--------------------------------------------------
	-- 🔫 CHECK AMMO
	--------------------------------------------------

	if currentAmmo <= 0 then
		return
	end

	if reloading then
		return
	end

	local viewport = camera.ViewportSize

	local centerX = viewport.X / 2
	local centerY = viewport.Y / 2

	local ray = camera:ViewportPointToRay(
		centerX,
		centerY
	)

	local origin = ray.Origin
	local direction = ray.Direction * 1000

	--------------------------------------------------
	-- 🔥 DAÑO
	--------------------------------------------------

	remote:FireServer(origin, direction)

	--------------------------------------------------
	-- 🔫 RESTAR BALAS
	--------------------------------------------------

	currentAmmo -= 1

	updateAmmoUI()

	--------------------------------------------------
	-- 🔥 RECOIL + MUZZLE
	--------------------------------------------------

	recoilEvent:Fire()
end

--------------------------------------------------
-- 🔥 START FIRING
--------------------------------------------------

local function startFiring()
	if reloading then
		reloadVersion += 1
		reloading = false
		CombatState.SetReloading(false)
		if reloadSound.IsPlaying then
			reloadSound:Stop()
		end
		updateAmmoUI()
	end

	if firing then
		return
	end

	firing = true

	task.spawn(function()

		while firing and equipped do

			shoot()

			task.wait(FIRE_RATE)
		end
	end)
end

--------------------------------------------------
-- 🔥 STOP FIRING
--------------------------------------------------

local function stopFiring()

	firing = false
end

--------------------------------------------------
-- 🔄 RELOAD
--------------------------------------------------

local function reload()
	if reloading then
		return
	end

	if currentAmmo >= MAG_SIZE then
		return
	end

	if reserveAmmo <= 0 then
		return
	end

	reloading = true
	reloadVersion += 1
	local thisReload = reloadVersion
	CombatState.SetReloading(true)

	--------------------------------------------------
	-- 🔫 DETENER DISPARO
	--------------------------------------------------

	stopFiring()
	CombatState.SetFiring(false)

	--------------------------------------------------
	-- 🔫 TEXTO RELOAD
	--------------------------------------------------

	weaponName.Text = "RELOADING..."

	--------------------------------------------------
	-- 🔊 SONIDO RELOAD
	--------------------------------------------------

	reloadSound:Play()

	--------------------------------------------------
	-- 🔄 ANIMACIÓN RELOAD
	--------------------------------------------------

	reloadEvent:Fire()

	--------------------------------------------------
	-- 🔥 TIEMPO RELOAD
	--------------------------------------------------

	-- Keep the shared reload state alive long enough for the viewmodel
	-- animation, even when the sound has no loaded TimeLength yet.
	task.wait(math.max(reloadSound.TimeLength, RELOAD_ANIMATION_TIME))
	if thisReload ~= reloadVersion or not reloading then
		return
	end

	--------------------------------------------------
	-- 🔫 CALCULAR BALAS NECESARIAS
	--------------------------------------------------

	local neededAmmo =
		MAG_SIZE - currentAmmo

	local ammoToLoad =
		math.min(neededAmmo, reserveAmmo)

	currentAmmo += ammoToLoad

	reserveAmmo -= ammoToLoad

	reloading = false
	CombatState.SetReloading(false)

	updateAmmoUI()
end

--------------------------------------------------
-- 💻 PC MOUSE
--------------------------------------------------

UserInputService.InputBegan:Connect(function(input, gameProcessed)

	if gameProcessed then
		return
	end

	if not equipped then
		return
	end

	--------------------------------------------------
	-- 🔄 RELOAD
	--------------------------------------------------

	if input.KeyCode == Enum.KeyCode.R then
		CombatState.RequestReload()

		return
	end

	--------------------------------------------------
	-- 🔫 DISPARAR
	--------------------------------------------------

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		CombatState.SetFiring(true)
	end
end)

UserInputService.InputEnded:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		CombatState.SetFiring(false)
	end
end)

--------------------------------------------------
-- COMBAT STATE COMMANDS (PC + MOBILE)
--------------------------------------------------

print("[Shoot] About to connect ReloadRequested, tool:", tool.Name, "equipped:", equipped)

CombatState.Changed:Connect(function(name, value)
	if not equipped then
		return
	end
	if name == "Firing" then
		if value then
			startFiring()
		else
			stopFiring()
		end
	end
end)

CombatState.ReloadRequested:Connect(function()
	if equipped then
		reload()
	end
end)

--------------------------------------------------
-- 🟢 EQUIPAR
--------------------------------------------------

tool.Equipped:Connect(function()
	print("[Shoot] Tool equipped!")
	equipped = true

	ammoGui.Enabled = true

	updateAmmoUI()

end)

tool.Unequipped:Connect(function()
	print("[Shoot] Tool unequipped!")
	equipped = false
	CombatState.SetFiring(false)
	firing = false

	ammoGui.Enabled = false
end)

--------------------------------------------------
-- 🔥 INICIO
--------------------------------------------------

ammoGui.Enabled = false
print("[Shoot] Script fully initialized, ready to use")
