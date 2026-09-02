--[[
    Shoot (LocalScript)
    Path: ReplicatedStorage → Weapons → AssaultRifle
    Parent: AssaultRifle
    Properties:
        Disabled: false
    Exported: 2026-09-02 16:23:32
]]
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local tool = script.Parent
local remote = tool:WaitForChild("FireEvent")

-- 🔥 recoil + muzzle
local recoilEvent = ReplicatedStorage:WaitForChild("RecoilEvent")

--------------------------------------------------
-- 🔄 RELOAD
--------------------------------------------------

local reloadEvent =
	ReplicatedStorage:WaitForChild("ReloadEvent")

local reloadSound =
	tool:WaitForChild("AssaultRifleReloadSound")

--------------------------------------------------
-- 📱 MOBILE BUTTON
--------------------------------------------------

local playerGui = player:WaitForChild("PlayerGui")

local mobileGui =
	playerGui:WaitForChild("MobileFireGui")

local fireButton =
	mobileGui:WaitForChild("FireButton")

--------------------------------------------------
-- 🔫 AMMO UI
--------------------------------------------------

local ammoGui =
	playerGui:WaitForChild("AmmoGui")

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

--------------------------------------------------
-- 🔫 CONFIG
--------------------------------------------------

local FIRE_RATE = 0.08

local firing = false
local equipped = false

--------------------------------------------------
-- 🔫 AMMO
--------------------------------------------------

local MAG_SIZE = 30

local currentAmmo = MAG_SIZE
local reserveAmmo = 120

local reloading = false

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

	--------------------------------------------------
	-- 🔫 DETENER DISPARO
	--------------------------------------------------

	stopFiring()

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

	task.wait(reloadSound.TimeLength)

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

		reload()

		return
	end

	--------------------------------------------------
	-- 🔫 DISPARAR
	--------------------------------------------------

	if input.UserInputType == Enum.UserInputType.MouseButton1 then

		startFiring()
	end
end)

UserInputService.InputEnded:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1 then

		stopFiring()
	end
end)

--------------------------------------------------
-- 📱 MOBILE FIRE BUTTON
--------------------------------------------------

fireButton.MouseButton1Down:Connect(function()

	if equipped then
		startFiring()
	end
end)

fireButton.MouseButton1Up:Connect(function()

	stopFiring()
end)

--------------------------------------------------
-- 🟢 EQUIPAR
--------------------------------------------------

tool.Equipped:Connect(function()

	equipped = true

	ammoGui.Enabled = true

	updateAmmoUI()

	--------------------------------------------------
	-- 📱 SOLO MÓVIL/TABLET
	--------------------------------------------------

	if UserInputService.TouchEnabled
		and not UserInputService.KeyboardEnabled then

		fireButton.Visible = true
	end
end)

tool.Unequipped:Connect(function()

	equipped = false
	firing = false

	fireButton.Visible = false

	ammoGui.Enabled = false
end)

--------------------------------------------------
-- 🔥 INICIO
--------------------------------------------------

fireButton.Visible = false

ammoGui.Enabled = false