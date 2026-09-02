--[[
    RadialProgressHandle (LocalScript)
    Path: StarterGui → ZoneHUD → ZoneContainer → ZoneC → RadialHolder
    Parent: RadialHolder
    Properties:
        Disabled: false
    Exported: 2026-09-02 16:23:32
]]
local Config = require(script.Parent.Config)

--------------------------------------------------
-- CREAR CAPAS
--------------------------------------------------

for i, layer in ipairs(Config.Layers) do

	for index, side in ipairs({
		script.Parent.Right,
		script.Parent.Left
		}) do

		local obj = script.Template:Clone()

		obj.Name = tostring(i)

		--------------------------------------------------
		-- GROSOR
		--------------------------------------------------

		obj.UIStroke.Thickness = layer.Stroke

		--------------------------------------------------
		-- TAMAÑO (ORIGINAL)
		--------------------------------------------------

		obj.Size = UDim2.new(
			2,
			-layer.Stroke * 2,
			1,
			-layer.Stroke * 2
		)

		obj.Position = UDim2.new(
			index - 1,
			0,
			0.5,
			0
		)

		obj.UIStroke.UIGradient.Color =
			ColorSequence.new(layer.Color)

		obj.RatioOffset.Value = layer.Offset

		obj.Parent = side

	end
end

--------------------------------------------------
-- ACTUALIZAR PROGRESO
--------------------------------------------------

local function updateProgress()

	local ratio = script.Parent.FillRatio.Value

	--------------------------------------------------
	-- DERECHA
	--------------------------------------------------

	for _, frame in ipairs(script.Parent.Right:GetChildren()) do

		if frame:IsA("Frame") then

			frame.UIStroke.UIGradient.Rotation =
				math.min(
					math.clamp(
						ratio + frame.RatioOffset.Value,
						0,
						1
					) * 360,
					180
				)

		end
	end

	--------------------------------------------------
	-- IZQUIERDA
	--------------------------------------------------

	for _, frame in ipairs(script.Parent.Left:GetChildren()) do

		if frame:IsA("Frame") then

			frame.UIStroke.UIGradient.Rotation =
				math.max(
					math.clamp(
						ratio + frame.RatioOffset.Value,
						0,
						1
					) * 360,
					180
				)

		end
	end

end

--------------------------------------------------
-- INICIO
--------------------------------------------------

script.Parent.FillRatio:GetPropertyChangedSignal("Value"):Connect(updateProgress)

updateProgress()

--------------------------------------------------
-- LIMPIEZA
--------------------------------------------------

script.Template:Destroy()