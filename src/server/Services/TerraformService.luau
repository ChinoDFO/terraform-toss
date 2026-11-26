--!strict
-- Progreso COMPARTIDO del servidor: el planeta pasa de 0 % a 100 % con los lanzamientos de todos.
-- Lógica: cuadrícula 96x96 (9.216 celdas) dividida en 6 franjas (una por zona).
-- Visual: 32x32 partes; cada parte representa 3x3 celdas y su color mezcla gris -> color de zona.
-- Hitos 25/50/75 % = "Bloom Event" (10 min: x2 dinero y +0,5 suerte para todos).
-- 100 % = planeta restaurado: recompensa a todos y se pasa al siguiente planeta (multiplicador).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Zones = require(ReplicatedStorage.Shared.Config.Zones)
local Net = require(ReplicatedStorage.Shared.Net)

local LOGICAL = 96
local VISUAL = 32
local SCALE = LOGICAL // VISUAL -- 3
local CELL_STUDS = 8
local ROWS_PER_ZONE = LOGICAL // Zones.COUNT -- 16
local BLOOM_SECONDS = 600
local MILESTONES = { 25, 50, 75, 100 }
local DEAD_COLOR = Color3.fromRGB(95, 95, 100)

local alive: { boolean } = {}
local deadByBand: { { number } } = {} -- índices de celdas muertas por franja (para elegir en O(1))
local aliveCount = 0
local nextMilestone = 1
local visualParts: { BasePart } = {}
local origin = Vector3.new(0, 0, 120)
local rng = Random.new()
local onRestored: { (number) -> () } = {}

local TerraformService = {}

local function indexOf(row: number, col: number): number
	return (row - 1) * LOGICAL + col
end

local function rowColOf(index: number): (number, number)
	local row = (index - 1) // LOGICAL + 1
	local col = (index - 1) % LOGICAL + 1
	return row, col
end

local function bandOfRow(row: number): number
	return math.clamp((row - 1) // ROWS_PER_ZONE + 1, 1, Zones.COUNT)
end

local function visualIndexOf(row: number, col: number): number
	local vr = (row - 1) // SCALE + 1
	local vc = (col - 1) // SCALE + 1
	return (vr - 1) * VISUAL + vc
end

local function worldPositionOf(row: number, col: number): Vector3
	local vr = (row - 1) // SCALE
	local vc = (col - 1) // SCALE
	return origin + Vector3.new((vc - VISUAL / 2) * CELL_STUDS, 0.5, vr * CELL_STUDS)
end

local function refreshVisual(vIndex: number)
	local part = visualParts[vIndex]
	if not part then
		return
	end
	local vr = (vIndex - 1) // VISUAL
	local vc = (vIndex - 1) % VISUAL
	local count = 0
	for dr = 1, SCALE do
		for dc = 1, SCALE do
			if alive[indexOf(vr * SCALE + dr, vc * SCALE + dc)] then
				count += 1
			end
		end
	end
	local zone = Zones.ZONES[bandOfRow(vr * SCALE + 1)]
	part.Color = DEAD_COLOR:Lerp(zone.color, count / (SCALE * SCALE))
end

local function buildVisual()
	local folder = Workspace:FindFirstChild("PlanetCells")
	if folder then
		folder:Destroy()
	end
	local newFolder = Instance.new("Folder")
	newFolder.Name = "PlanetCells"
	for vr = 0, VISUAL - 1 do
		for vc = 0, VISUAL - 1 do
			local part = Instance.new("Part")
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.CastShadow = false
			part.Material = Enum.Material.SmoothPlastic
			part.Size = Vector3.new(CELL_STUDS, 1, CELL_STUDS)
			part.Position = origin + Vector3.new((vc - VISUAL / 2) * CELL_STUDS, 0, vr * CELL_STUDS)
			part.Color = DEAD_COLOR
			part.Parent = newFolder
			table.insert(visualParts, part)
		end
	end
	newFolder.Parent = Workspace
end

-- PLACEHOLDER de "zonas visibles" (Semana 2): un letrero flotante con el nombre de cada zona,
-- para que se distingan mientras Dev B diseña el mapa/arte real en Studio.
local function buildZoneLabels()
	local existing = Workspace:FindFirstChild("ZoneLabels")
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "ZoneLabels"
	for _, zone in Zones.ZONES do
		local centerRow = (zone.id - 1) * ROWS_PER_ZONE + ROWS_PER_ZONE / 2
		local marker = Instance.new("Part")
		marker.Name = zone.name
		marker.Anchored = true
		marker.CanCollide = false
		marker.CanQuery = false
		marker.CanTouch = false
		marker.Transparency = 1
		marker.Size = Vector3.new(1, 1, 1)
		marker.Position = worldPositionOf(centerRow, LOGICAL / 2) + Vector3.new(0, 15, 0)
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.fromOffset(240, 50)
		billboard.AlwaysOnTop = true
		billboard.Parent = marker
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBlack
		label.Text = zone.name
		label.TextScaled = true
		label.TextColor3 = zone.color
		label.TextStrokeTransparency = 0.4
		label.Parent = billboard
		marker.Parent = folder
	end
	folder.Parent = Workspace
end

local function resetGrid()
	aliveCount = 0
	nextMilestone = 1
	table.clear(alive)
	table.clear(deadByBand)
	for band = 1, Zones.COUNT do
		deadByBand[band] = {}
	end
	for i = 1, LOGICAL * LOGICAL do
		alive[i] = false
		local row = rowColOf(i)
		table.insert(deadByBand[bandOfRow(row)], i)
	end
	for _, part in visualParts do
		part.Color = DEAD_COLOR
	end
end

local function percent(): number
	return aliveCount / (LOGICAL * LOGICAL) * 100
end

-- Franja con celdas muertas más cercana a la pedida (desbordamiento).
local function bandWithRoom(preferred: number): number?
	for offset = 0, Zones.COUNT do
		for _, band in { preferred - offset, preferred + offset } do
			if band >= 1 and band <= Zones.COUNT and #deadByBand[band] > 0 then
				return band
			end
		end
	end
	return nil
end

local function checkMilestones()
	local state = Net.serverState()
	local notify = Net.event("Notify")
	state:SetAttribute("PlanetPercent", percent())
	while nextMilestone <= #MILESTONES and percent() >= MILESTONES[nextMilestone] do
		local milestone = MILESTONES[nextMilestone]
		nextMilestone += 1
		if milestone < 100 then
			state:SetAttribute("BloomUntil", os.time() + BLOOM_SECONDS)
			notify:FireAllClients("Bloom", { percent = milestone, seconds = BLOOM_SECONDS })
		else
			local planet = (tonumber(state:GetAttribute("Planet")) or 1) + 1
			notify:FireAllClients("PlanetRestored", { planet = planet })
			for _, callback in onRestored do
				task.spawn(callback, planet)
			end
			state:SetAttribute("Planet", planet)
			task.delay(8, function()
				resetGrid()
				state:SetAttribute("PlanetPercent", 0)
			end)
			return
		end
	end
end

-- Aplica un lanzamiento. Devuelve (celdas nuevas, posición de aterrizaje para el efecto visual).
function TerraformService.applyThrow(zone: number, cells: number): (number, Vector3)
	local band = bandWithRoom(zone)
	if band == nil then
		return 0, worldPositionOf(1, LOGICAL // 2)
	end
	local list = deadByBand[band]
	local changed = 0
	local landing: Vector3? = nil
	local touched: { [number]: boolean } = {}
	for _ = 1, cells do
		if #list == 0 then
			break
		end
		local pick = rng:NextInteger(1, #list)
		local index = list[pick]
		list[pick] = list[#list] -- swap-remove
		list[#list] = nil
		alive[index] = true
		aliveCount += 1
		changed += 1
		local row, col = rowColOf(index)
		touched[visualIndexOf(row, col)] = true
		if landing == nil then
			landing = worldPositionOf(row, col)
		end
	end
	for vIndex in touched do
		refreshVisual(vIndex)
	end
	checkMilestones()
	return changed, landing or worldPositionOf(1, LOGICAL // 2)
end

function TerraformService.isBloom(): boolean
	local untilTime = tonumber(Net.serverState():GetAttribute("BloomUntil")) or 0
	return os.time() < untilTime
end

function TerraformService.planetMultiplier(): number
	local planet = tonumber(Net.serverState():GetAttribute("Planet")) or 1
	return 1 + 0.1 * (planet - 1)
end

function TerraformService.onPlanetRestored(callback: (number) -> ())
	table.insert(onRestored, callback)
end

function TerraformService.init()
	local marker = Workspace:FindFirstChild("PlanetOrigin")
	if marker and marker:IsA("BasePart") then
		origin = marker.Position
	end
	local state = Net.serverState()
	state:SetAttribute("Planet", 1)
	state:SetAttribute("PlanetPercent", 0)
	state:SetAttribute("BloomUntil", 0)
	buildVisual()
	buildZoneLabels()
	resetGrid()
end

return TerraformService
