--!strict
-- Plataforma de lanzamiento procedural: base, barandas y farolas con luz, junto al planeta.
-- Pocas partes y ancladas; solo la base es pisable.
local Workspace = game:GetService("Workspace")

local TerraformService = require(script.Parent.TerraformService)

local SIZE = Vector3.new(48, 1, 24)
local OFFSET = Vector3.new(0, 0.5, -30) -- delante de la primera fila del planeta
local METAL = Color3.fromRGB(70, 75, 90)
local LAMP_COLOR = Color3.fromRGB(255, 220, 150)

local SPAWN_SIZE = Vector3.new(8, 1, 8)
local SPAWN_BACK = 6 -- studs hacia atrás desde el centro (lejos del borde abierto)

local LaunchPlatformService = {}

-- Posición y orientación del punto de aparición: sobre la base, mirando al planeta (+Z).
-- Pura (se prueba): depende solo del origen del planeta.
function LaunchPlatformService.spawnCFrame(origin: Vector3): CFrame
	local center = origin + OFFSET
	local position = center + Vector3.new(0, SIZE.Y / 2 + SPAWN_SIZE.Y / 2, -SPAWN_BACK)
	-- El jugador aparece mirando hacia donde apunta el LookVector del SpawnLocation: +Z = el planeta.
	return CFrame.lookAt(position, position + Vector3.new(0, 0, 1))
end

local function make(
	parent: Instance,
	name: string,
	size: Vector3,
	position: Vector3,
	color: Color3,
	material: Enum.Material,
	solid: boolean
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = solid
	p.CanQuery = solid
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.Position = position
	p.Color = color
	p.Material = material
	p.Parent = parent
	return p
end

function LaunchPlatformService.init()
	local old = Workspace:FindFirstChild("LaunchPlatform")
	if old then
		old:Destroy()
	end
	local model = Instance.new("Model")
	model.Name = "LaunchPlatform"
	local center = TerraformService.getOrigin() + OFFSET

	make(model, "Base", SIZE, center, Color3.fromRGB(55, 58, 70), Enum.Material.Metal, true)

	-- Baranda en tres lados (el frente, hacia el planeta, queda abierto para lanzar).
	local top = center + Vector3.new(0, 2.5, 0)
	local sideSize = Vector3.new(0.6, 0.6, SIZE.Z)
	make(model, "BarandaIzq", sideSize, top + Vector3.new(-SIZE.X / 2 + 0.3, 0, 0), METAL, Enum.Material.Metal, false)
	make(model, "BarandaDer", sideSize, top + Vector3.new(SIZE.X / 2 - 0.3, 0, 0), METAL, Enum.Material.Metal, false)
	local backSize = Vector3.new(SIZE.X, 0.6, 0.6)
	make(model, "BarandaFondo", backSize, top + Vector3.new(0, 0, -SIZE.Z / 2 + 0.3), METAL, Enum.Material.Metal, false)

	-- Farolas en las cuatro esquinas con luz cálida.
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local pos = center + Vector3.new(sx * (SIZE.X / 2 - 1), 0, sz * (SIZE.Z / 2 - 1))
			make(
				model,
				"Poste",
				Vector3.new(0.6, 6, 0.6),
				pos + Vector3.new(0, 3.5, 0),
				METAL,
				Enum.Material.Metal,
				false
			)
			local lamp = make(
				model,
				"Lampara",
				Vector3.new(1.4, 1.4, 1.4),
				pos + Vector3.new(0, 7, 0),
				LAMP_COLOR,
				Enum.Material.Neon,
				false
			)
			lamp.Shape = Enum.PartType.Ball
			local light = Instance.new("PointLight")
			light.Color = LAMP_COLOR
			light.Range = 26
			light.Brightness = 1.5
			light.Shadows = false
			light.Parent = lamp
		end
	end

	-- Punto de aparición invisible sobre la plataforma (Neutral, sin escudo).
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnPlataforma"
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.CanQuery = false
	spawn.CanTouch = false
	spawn.Transparency = 1
	spawn.Size = SPAWN_SIZE
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.CFrame = LaunchPlatformService.spawnCFrame(TerraformService.getOrigin())
	spawn.Parent = model
	-- Cualquier otro SpawnLocation del lugar (p. ej. el de la plantilla en 0,0,0) se desactiva.
	for _, inst in Workspace:GetDescendants() do
		if inst:IsA("SpawnLocation") and inst ~= spawn then
			inst.Enabled = false
		end
	end
	model.Parent = Workspace
end

return LaunchPlatformService
