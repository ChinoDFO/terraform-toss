--!strict
-- PLACEHOLDER de "jardín 3D" (Semana 2): una criatura procedural (CreatureBuilder) por slot del jardín de cada
-- jugador, en un punto fijo alrededor del origen del planeta. Nada de esto decide ingresos
-- ni nada de juego -- es SOLO la vista de datos que el servidor ya tiene (data.garden).
-- Dev B lo puede rehacer por completo (modelos reales, un terreno propio por jugador, etc.)
-- cuando diseñe el mapa; esto es solo para que exista algo mientras tanto.
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local CreatureBuilder = require(ReplicatedStorage.Shared.Util.CreatureBuilder)
local TerraformService = require(script.Parent.TerraformService)
local TerraformService = require(script.Parent.TerraformService)

type PlayerData = Types.PlayerData

local SLOT_SIZE = 3
local SLOT_GAP = 1.5
local COLUMNS = 4
local RADIUS = 220 -- lejos de la cuadrícula del planeta (centrado en TerraformService.getOrigin)
local MAX_SLOTS_AROUND_CIRCLE = 12 -- si hay más jugadores, se reparten en el mismo círculo

local GardenVisualService = {}
local folders: { [Player]: Folder } = {}
local slotIndex: { [Player]: number } = {}
local nextSlot = 0

local function basePositionFor(player: Player): Vector3
	local index = slotIndex[player] or 0
	local angle = (index % MAX_SLOTS_AROUND_CIRCLE) * (math.pi * 2 / MAX_SLOTS_AROUND_CIRCLE)
	return TerraformService.getOrigin() + Vector3.new(math.cos(angle) * RADIUS, 0, math.sin(angle) * RADIUS)
end

local function rebuild(player: Player, data: PlayerData)
	local folder = folders[player]
	if folder == nil then
		folder = Instance.new("Folder")
		folder.Name = "Jardin_" .. player.Name
		folders[player] = folder
	end
	folder:ClearAllChildren()

	local base = basePositionFor(player)

	local nameTag = Instance.new("Part")
	nameTag.Name = "Etiqueta"
	nameTag.Anchored = true
	nameTag.CanCollide = false
	nameTag.CanQuery = false
	nameTag.CanTouch = false
	nameTag.Transparency = 1
	nameTag.Size = Vector3.new(1, 1, 1)
	nameTag.Position = base + Vector3.new(0, SLOT_SIZE + 3, 0)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(200, 40)
	billboard.AlwaysOnTop = true
	billboard.Parent = nameTag
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = "Jardín de " .. player.Name
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.Parent = billboard
	nameTag.Parent = folder

	for i, slot in data.garden do
		local col = (i - 1) % COLUMNS
		local rowIndex = (i - 1) // COLUMNS
		local position = base
			+ Vector3.new((col - (COLUMNS - 1) / 2) * (SLOT_SIZE + SLOT_GAP), 0, rowIndex * (SLOT_SIZE + SLOT_GAP))
		local model = CreatureBuilder.build(slot.creatureId, slot.mutation, position)
		if model then
			model.Parent = folder
		end
	end

	folder.Parent = Workspace
end

-- Llamar cada vez que data.garden cambia (CreatureService.grant) o al cargar (EconomyService).
function GardenVisualService.sync(player: Player, data: PlayerData)
	rebuild(player, data)
end

function GardenVisualService.init()
	Players.PlayerAdded:Connect(function(player: Player)
		slotIndex[player] = nextSlot
		nextSlot += 1
	end)
	for _, player in Players:GetPlayers() do
		slotIndex[player] = nextSlot
		nextSlot += 1
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		local folder = folders[player]
		if folder then
			folder:Destroy()
		end
		folders[player] = nil
		slotIndex[player] = nil
	end)
end

return GardenVisualService
