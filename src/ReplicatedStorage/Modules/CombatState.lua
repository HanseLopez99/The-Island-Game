-- Shared client-side combat state. All input owners write here; gameplay
-- scripts react to the signals instead of reading mobile UI directly.
local CombatState = {
	Aiming = false,
	ADSLocked = false,
	ADSReady = false,
	Firing = false,
	Reloading = false,
}

local changed = Instance.new("BindableEvent")
local reloadRequested = Instance.new("BindableEvent")

CombatState.Changed = changed.Event
CombatState.ReloadRequested = reloadRequested.Event

local function set(name, value)
	if CombatState[name] == value then
		return
	end
	CombatState[name] = value
	changed:Fire(name, value)
end

function CombatState.SetAiming(value)
	set("Aiming", value == true)
	if not value then
		set("ADSReady", false)
	end
end

function CombatState.SetADSLocked(value)
	set("ADSLocked", value == true)
	CombatState.SetAiming(value == true)
end

function CombatState.SetADSReady(value)
	set("ADSReady", value == true)
end

function CombatState.SetFiring(value)
	set("Firing", value == true)
end

function CombatState.SetReloading(value)
	set("Reloading", value == true)
end

function CombatState.RequestReload()
	reloadRequested:Fire()
end

function CombatState.Reset()
	CombatState.SetFiring(false)
	CombatState.SetADSLocked(false)
	CombatState.SetAiming(false)
	CombatState.SetReloading(false)
	CombatState.SetADSReady(false)
end

return CombatState
