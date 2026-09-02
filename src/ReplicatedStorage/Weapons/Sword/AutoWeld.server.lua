--[[
    AutoWeld (Script)
    Path: ReplicatedStorage → Weapons → Sword
    Parent: Sword
    Properties:
        Disabled: false
        RunContext: Enum.RunContext.Legacy
    Exported: 2026-09-02 16:23:32
]]
local tool = script.Parent
local handle = tool:WaitForChild("Handle")
local hitbox = tool:WaitForChild("Hitbox")

-- Función para soldar todo al Handle
local function setupWelds()
	for _, obj in ipairs(tool:GetDescendants()) do
		if obj:IsA("BasePart") then
			-- Configuración física estilo pro
			obj.Anchored = false
			obj.CanCollide = false
			obj.Massless = true

			-- Evitar duplicar welds
			if obj ~= handle then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = handle
				weld.Part1 = obj
				weld.Parent = handle
			end
		end
	end
end

-- Configurar hitbox separado (opcional pero recomendado)
local function setupHitbox()
	hitbox.Transparency = 1
	hitbox.CanCollide = false
	hitbox.Massless = true
	hitbox.CanTouch = false -- desactivado hasta atacar
end

setupWelds()
setupHitbox()