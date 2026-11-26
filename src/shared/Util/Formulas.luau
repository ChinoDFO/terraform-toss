--!strict
-- Fórmulas de economía en un solo lugar (balance). Cámbialas aquí, no en los servicios.
local Types = require(script.Parent.Parent.Types)
local Zones = require(script.Parent.Parent.Config.Zones)
local Rarities = require(script.Parent.Parent.Config.Rarities)
local Mutations = require(script.Parent.Parent.Config.Mutations)
local Creatures = require(script.Parent.Parent.Config.Creatures)

local Formulas = {}

Formulas.BASE_GARDEN_SLOTS = 8
Formulas.EXTRA_SLOTS_PASS = 4
Formulas.PLUS_EXTRA_SLOTS = 1
Formulas.OFFLINE_CAP_SECONDS = 8 * 3600
Formulas.OFFLINE_RATE = 0.5
Formulas.SELL_SECONDS = 30 -- vender una criatura = 30 s de su ingreso

function Formulas.trainingCost(level: number): number
	return math.floor(30 * 1.85 ^ level)
end

function Formulas.capsuleCost(level: number): number
	return math.floor(300 * 4 ^ level)
end

function Formulas.capsuleMultiplier(level: number): number
	return 1.2 ^ level
end

function Formulas.trainingRate(level: number, turbo: boolean): number
	return (1 + level) * (if turbo then 2 else 1)
end

function Formulas.slotIncome(slot: Types.GardenSlot): number
	local creature = Creatures.BY_ID[slot.creatureId]
	if not creature then
		return 0
	end
	local zone = Zones.ZONES[creature.zone]
	local rarity = Rarities.DEFS[creature.rarity]
	local mutation = Mutations.DEFS[slot.mutation] or Mutations.DEFS.Ninguna
	return zone.baseIncome * rarity.incomeMult * mutation.incomeMult
end

function Formulas.gardenIncome(garden: { Types.GardenSlot }): number
	local total = 0
	for _, slot in garden do
		total += Formulas.slotIncome(slot)
	end
	return total
end

function Formulas.gardenCapacity(hasExtraSlotsPass: boolean, hasPlus: boolean): number
	return Formulas.BASE_GARDEN_SLOTS
		+ (if hasExtraSlotsPass then Formulas.EXTRA_SLOTS_PASS else 0)
		+ (if hasPlus then Formulas.PLUS_EXTRA_SLOTS else 0)
end

-- Suerte gratuita: +2 % por cada criatura distinta descubierta + bonos de evento. Tope 5 (diseño).
Formulas.MAX_LUCK = 5

function Formulas.luck(discovered: number, bloomActive: boolean, adBoostActive: boolean): number
	local raw = 1 + 0.02 * discovered + (if bloomActive then 0.5 else 0) + (if adBoostActive then 0.25 else 0)
	return math.min(raw, Formulas.MAX_LUCK)
end

return Formulas
