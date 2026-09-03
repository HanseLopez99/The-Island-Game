-- ReplicatedStorage/Modules/ViewportRenderer
-- Renders a Tool in a ViewportFrame without running its gameplay scripts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WeaponData = require(ReplicatedStorage:WaitForChild("WeaponData"))

local ViewportRenderer = {}

local function normalizeConfig(source)
	local offset = source.Offset or Vector3.zero
	local rotation = source.Rotation or Vector3.zero
	local function normalizeAngle(value)
		return ((value + 180) % 360) - 180
	end

	return {
		Distance = math.clamp(source.Distance or 2, 0.2, 20),
		Offset = Vector3.new(
			math.clamp(offset.X, -2, 2),
			math.clamp(offset.Y, -2, 2),
			math.clamp(offset.Z, -2, 2)
		),
		Rotation = Vector3.new(
			normalizeAngle(rotation.X),
			normalizeAngle(rotation.Y),
			normalizeAngle(rotation.Z)
		),
		FieldOfView = source.FieldOfView,
	}
end

local function cloneRenderable(source)

	local clone = source:Clone()

	for _, descendant in ipairs(clone:GetDescendants()) do
		if descendant:IsA("Script")
			or descendant:IsA("LocalScript")
			or descendant:IsA("ModuleScript")
			or descendant:IsA("Sound")
			or descendant:IsA("ParticleEmitter")
			or descendant:IsA("Trail") then
			descendant:Destroy()
		end
	end

	return clone
end

function ViewportRenderer.RenderTool(viewportFrame, tool, config)
	assert(viewportFrame and viewportFrame:IsA("ViewportFrame"), "RenderTool requires a ViewportFrame")
	assert(
		tool and (tool:IsA("Tool") or tool:IsA("Model")),
		"RenderTool requires a Tool or Model"
	)

	-- Backwards-compatible with WeaponHUDController calls that pass only
	-- (viewportFrame, tool).
	config = normalizeConfig(config or WeaponData[tool.Name] or {})

	viewportFrame:ClearAllChildren()
	-- Neutral contrast background so dark weapons remain visible.
	viewportFrame.BackgroundColor3 = Color3.fromRGB(92, 104, 122)
	viewportFrame.BackgroundTransparency = 0
	viewportFrame.Ambient = Color3.fromRGB(190, 190, 190)
	viewportFrame.LightColor = Color3.fromRGB(255, 255, 255)
	viewportFrame.LightDirection = Vector3.new(-1, -1, -1)

	local worldModel = Instance.new("WorldModel")
	worldModel.Name = "PreviewWorld"
	worldModel.Parent = viewportFrame

	local clone = cloneRenderable(tool)
	clone.Parent = worldModel
	clone:PivotTo(CFrame.new())

	local camera = Instance.new("Camera")
	camera.Name = "PreviewCamera"
	-- Tighter FOV keeps the weapon proportionally larger in small HUD slots.
	camera.FieldOfView = config.FieldOfView or 19
	camera.Parent = viewportFrame
	viewportFrame.CurrentCamera = camera

	local offset = config.Offset or Vector3.zero
	local distance = math.max(config.Distance or 2, 0.05)
	local rotation = config.Rotation or Vector3.zero

	-- Offset moves the previewed weapon itself. This makes temporary slider
	-- changes immediately visible instead of moving the camera and target
	-- together.
	clone:PivotTo(CFrame.new(offset))

	local target = offset
	local cameraPosition = Vector3.new(0, 0, distance)

	camera.CFrame = CFrame.lookAt(cameraPosition, target)
		* CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))

	local light = Instance.new("SpotLight")
	light.Brightness = 2
	light.Range = 24
	light.Angle = 90
	light.Parent = camera

	return {
		WorldModel = worldModel,
		Model = clone,
		Camera = camera,
	}
end

return ViewportRenderer