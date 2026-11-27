--!strict
-- Escenografía procedural: árboles, cristales, dunas, hielo, helechos y lava que aparecen al
-- restaurar celdas de su franja. Anclada, sin colisión, con tope por franja. Solo cosmético.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Zones = require(ReplicatedStorage.Shared.Config.Zones)
local SceneryConfig = require(ReplicatedStorage.Shared.Config.Scenery)
local TerraformService = require(script.Parent.TerraformService)

local rng = Random.new()
local folder: Folder
local countByBand: { number } = {}

local SceneryService = {}

-- ¿Debe nacer un prop? Pura (se prueba): hay cupo y la tirada (0..1) cae bajo la probabilidad.
function SceneryService.shouldSpawn(currentCount: number, roll: number): boolean
	return currentCount < SceneryConfig.MAX_PER_BAND and roll < SceneryConfig.SPAWN_CHANCE
end

local function part(
	parent: Instance,
	shape: Enum.PartType,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material
): Part
	local p = Instance.new("Part")
	p.Shape = shape
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material
	p.Parent = parent
	return p
end

local function build(kind: SceneryConfig.Kind, pos: Vector3, parent: Instance, accent: Color3)
	local h = SceneryConfig.MAX_HEIGHT * (0.6 + 0.4 * rng:NextNumber())
	local base = CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber() * math.pi * 2, 0)
	local block = Enum.PartType.Block
	local ball = Enum.PartType.Ball
	local white = Color3.new(1, 1, 1)
	if kind == "tree" then
		local trunk = Vector3.new(1.2, h * 0.5, 1.2)
		part(parent, block, trunk, base * CFrame.new(0, h * 0.25, 0), Color3.fromRGB(110, 80, 50), Enum.Material.Wood)
		local crown = Vector3.new(h * 0.7, h * 0.6, h * 0.7)
		part(parent, ball, crown, base * CFrame.new(0, h * 0.7, 0), accent, Enum.Material.Grass)
	elseif kind == "crystal" then
		local big = Vector3.new(h * 0.25, h, h * 0.25)
		part(parent, block, big, base * CFrame.Angles(0, 0, 0.2) * CFrame.new(0, h / 2, 0), accent, Enum.Material.Glass)
		local small = Vector3.new(h * 0.18, h * 0.6, h * 0.18)
		local tint = accent:Lerp(white, 0.3)
		part(
			parent,
			block,
			small,
			base * CFrame.Angles(0.3, 0, -0.25) * CFrame.new(1, h * 0.3, 0),
			tint,
			Enum.Material.Glass
		)
	elseif kind == "dune" then
		local size = Vector3.new(h * 1.6, h * 0.5, h * 1.1)
		part(parent, ball, size, base * CFrame.new(0, h * 0.05, 0), accent, Enum.Material.Sand)
	elseif kind == "ice" then
		local big = Vector3.new(h * 0.4, h * 0.9, h * 0.4)
		part(
			parent,
			block,
			big,
			base * CFrame.Angles(0.1, 0, 0.15) * CFrame.new(0, h * 0.45, 0),
			accent,
			Enum.Material.Ice
		)
		local small = Vector3.new(h * 0.3, h * 0.5, h * 0.3)
		local tint = accent:Lerp(white, 0.4)
		part(
			parent,
			block,
			small,
			base * CFrame.Angles(-0.2, 0, -0.1) * CFrame.new(h * 0.3, h * 0.25, 0),
			tint,
			Enum.Material.Ice
		)
	elseif kind == "fern" then
		for i = 0, 2 do
			local frond = Vector3.new(0.4, h * 0.5, 2.2)
			part(
				parent,
				block,
				frond,
				base * CFrame.Angles(0, i * 2.1, 0.5) * CFrame.new(0, h * 0.2, 0),
				accent,
				Enum.Material.Grass
			)
		end
	else -- lava
		local pool = Vector3.new(h * 0.6, h * 0.25, h * 0.6)
		part(parent, ball, pool, base * CFrame.new(0, 0.2, 0), accent, Enum.Material.Neon)
		local rock = Vector3.new(h * 0.25, h * 0.7, h * 0.25)
		part(parent, block, rock, base * CFrame.new(0, h * 0.35, 0), Color3.fromRGB(50, 35, 35), Enum.Material.Basalt)
	end
end

local function onCellRestored(band: number, position: Vector3)
	if not SceneryService.shouldSpawn(countByBand[band] or 0, rng:NextNumber()) then
		return
	end
	local zone = Zones.ZONES[band]
	local kind = SceneryConfig.KIND_BY_ZONE[band]
	if zone == nil or kind == nil then
		return
	end
	countByBand[band] = (countByBand[band] or 0) + 1
	local model = Instance.new("Model")
	model.Name = kind
	model.Parent = folder
	local jitter = Vector3.new(rng:NextNumber(-3, 3), 0, rng:NextNumber(-3, 3))
	build(kind, position + jitter, model, zone.color)
end

local function clear()
	folder:ClearAllChildren()
	table.clear(countByBand)
end

function SceneryService.init()
	local old = Workspace:FindFirstChild("PlanetScenery")
	if old then
		old:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = "PlanetScenery"
	folder.Parent = Workspace
	TerraformService.onCellRestored(onCellRestored)
	TerraformService.onGridReset(clear)
end

return SceneryService
