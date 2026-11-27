--!strict
-- Índice de criaturas: lista las 30 (6 zonas x 5 rarezas), bloqueadas hasta descubrirlas.
-- Solo LEE: decodifica el atributo "DiscoveredMask" (un bit por criatura) que ya calcula
-- el servidor en CreatureService.syncDiscovered. Nada de esto decide nada, solo muestra.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Creatures = require(ReplicatedStorage.Shared.Config.Creatures)
local Rarities = require(ReplicatedStorage.Shared.Config.Rarities)
local Zones = require(ReplicatedStorage.Shared.Config.Zones)
local Ui = require(script.Parent.Parent.UI.Ui)

type CreatureDef = Creatures.CreatureDef
type Row = { frame: Frame, label: TextLabel, creature: CreatureDef }

local player = Players.LocalPlayer
local IndexController = {}

local panel: Frame
local counter: TextLabel
local rows: { Row } = {}

local function isDiscovered(mask: number, slot: number): boolean
	return bit32.band(mask, bit32.lshift(1, slot - 1)) ~= 0
end

local function refresh()
	local mask = tonumber(player:GetAttribute("DiscoveredMask")) or 0
	local discoveredCount = 0
	for i, row in rows do
		local creature = row.creature
		if isDiscovered(mask, i) then
			discoveredCount += 1
			local rarity = Rarities.DEFS[creature.rarity]
			row.label.Text = string.format("%s (%s)", creature.name, rarity.name)
			row.label.TextColor3 = rarity.color
			row.frame.BackgroundTransparency = 0.4
		else
			row.label.Text = "???"
			row.label.TextColor3 = Color3.fromRGB(130, 130, 130)
			row.frame.BackgroundTransparency = 0.75
		end
	end
	counter.Text = string.format("%d / %d", discoveredCount, Creatures.COUNT)
end

local function build()
	local gui =
		Ui.make("ScreenGui", { Name = "Index", ResetOnSpawn = false }, player:WaitForChild("PlayerGui")) :: ScreenGui
	local open = Ui.button(
		gui,
		"OpenIndex",
		UDim2.fromScale(0.02, 0.41),
		UDim2.fromScale(0.14, 0.06),
		"Índice",
		Color3.fromRGB(90, 90, 160)
	)

	panel = Ui.make("Frame", {
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.62, 0.72),
		BackgroundColor3 = Color3.fromRGB(22, 24, 30),
		Visible = false,
	}, gui) :: Frame
	Ui.make("UICorner", { CornerRadius = UDim.new(0, 14) }, panel)

	local title =
		Ui.label(panel, "Title", UDim2.fromScale(0.03, 0.015), UDim2.fromScale(0.5, 0.07), "Índice de criaturas")
	title.TextXAlignment = Enum.TextXAlignment.Left

	counter = Ui.label(panel, "Counter", UDim2.fromScale(0.58, 0.015), UDim2.fromScale(0.26, 0.07), "0 / 30")

	local close = Ui.button(
		panel,
		"Close",
		UDim2.fromScale(0.86, 0.015),
		UDim2.fromScale(0.12, 0.06),
		"✕",
		Color3.fromRGB(120, 60, 60)
	)
	close.Activated:Connect(function()
		panel.Visible = false
	end)

	local list = Ui.make("ScrollingFrame", {
		Name = "List",
		Position = UDim2.fromScale(0.02, 0.1),
		Size = UDim2.fromScale(0.96, 0.88),
		BackgroundTransparency = 1,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 8,
	}, panel) :: ScrollingFrame
	Ui.make("UIGridLayout", {
		CellSize = UDim2.new(0.31, 0, 0, 36),
		CellPadding = UDim2.fromOffset(6, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, list)

	for i, creature in Creatures.LIST do
		local zone = Zones.ZONES[creature.zone]
		local row = Ui.make("Frame", {
			Name = creature.id,
			LayoutOrder = i,
			BackgroundColor3 = zone.color,
			BackgroundTransparency = 0.75,
		}, list) :: Frame
		Ui.make("UICorner", { CornerRadius = UDim.new(0, 8) }, row)
		local label = Ui.label(row, "Name", UDim2.fromScale(0.06, 0.1), UDim2.fromScale(0.88, 0.8), "???")
		label.TextXAlignment = Enum.TextXAlignment.Left
		table.insert(rows, { frame = row, label = label, creature = creature })
	end

	open.Activated:Connect(function()
		panel.Visible = not panel.Visible
		if panel.Visible then
			refresh()
		end
	end)

	player:GetAttributeChangedSignal("DiscoveredMask"):Connect(refresh)
end

function IndexController.init()
	build()
	refresh()
end

return IndexController
