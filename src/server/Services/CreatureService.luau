--!strict
-- Dar criaturas al jugador: índice, jardín (con venta automática si está lleno) y huevos.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Creatures = require(ReplicatedStorage.Shared.Config.Creatures)
local Mutations = require(ReplicatedStorage.Shared.Config.Mutations)
local Rarities = require(ReplicatedStorage.Shared.Config.Rarities)
local Formulas = require(ReplicatedStorage.Shared.Util.Formulas)
local Odds = require(ReplicatedStorage.Shared.Util.Odds)
local WeightedRandom = require(ReplicatedStorage.Shared.Util.WeightedRandom)
local Perks = require(script.Parent.Parent.Util.Perks)
local GardenVisualService = require(script.Parent.GardenVisualService)

type PlayerData = Types.PlayerData

export type GrantResult = {
	creatureId: string,
	rarity: string,
	mutation: string,
	kept: boolean,
	cashFromSale: number,
	isNew: boolean,
}

local rng = Random.new()
local CreatureService = {}

function CreatureService.rollMutation(): string
	return WeightedRandom.pick(Mutations.weights(), Mutations.ORDER, rng)
end

function CreatureService.discoveredCount(data: PlayerData): number
	local n = 0
	for _ in data.index do
		n += 1
	end
	return n
end

-- Un bit por criatura (según el orden de Creatures.LIST) para que el cliente pinte el índice
-- sin necesitar un RemoteEvent nuevo: cabe en un solo atributo numérico (30 criaturas <= 32 bits).
function CreatureService.discoveredMask(data: PlayerData): number
	local mask = 0
	for i, creature in Creatures.LIST do
		if data.index[creature.id] == true then
			mask = bit32.bor(mask, bit32.lshift(1, i - 1))
		end
	end
	return mask
end

local function syncDiscovered(player: Player, data: PlayerData)
	player:SetAttribute("Discovered", CreatureService.discoveredCount(data))
	player:SetAttribute("DiscoveredMask", CreatureService.discoveredMask(data))
end
CreatureService.syncDiscovered = syncDiscovered

function CreatureService.grant(
	player: Player,
	data: PlayerData,
	zone: number,
	rarity: string,
	mutation: string
): GrantResult
	local creature = Creatures.get(zone, rarity)
	local isNew = data.index[creature.id] ~= true
	data.index[creature.id] = true
	syncDiscovered(player, data)

	local slot: Types.GardenSlot = { creatureId = creature.id, mutation = mutation }
	local newIncome = Formulas.slotIncome(slot)
	local capacity = Formulas.gardenCapacity(Perks.hasPass(player, "HuecosExtra"), Perks.hasPlus(player))

	if #data.garden < capacity then
		table.insert(data.garden, slot)
		GardenVisualService.sync(player, data)
		return {
			creatureId = creature.id,
			rarity = rarity,
			mutation = mutation,
			kept = true,
			cashFromSale = 0,
			isNew = isNew,
		}
	end

	-- Jardín lleno: si la nueva vale más que la peor, la reemplaza (y se vende la peor).
	local worstIndex, worstIncome = 1, math.huge
	for i, existing in data.garden do
		local income = Formulas.slotIncome(existing)
		if income < worstIncome then
			worstIndex, worstIncome = i, income
		end
	end
	if newIncome > worstIncome then
		data.garden[worstIndex] = slot
		GardenVisualService.sync(player, data)
		local sale = worstIncome * Formulas.SELL_SECONDS
		data.cash += sale
		return {
			creatureId = creature.id,
			rarity = rarity,
			mutation = mutation,
			kept = true,
			cashFromSale = sale,
			isNew = isNew,
		}
	end
	local sale = newIncome * Formulas.SELL_SECONDS
	data.cash += sale
	return {
		creatureId = creature.id,
		rarity = rarity,
		mutation = mutation,
		kept = false,
		cashFromSale = sale,
		isNew = isNew,
	}
end

-- Abre un Huevo Estelar. paid=true actualiza el contador de pity (divulgado en la tienda).
function CreatureService.openEgg(player: Player, data: PlayerData, paid: boolean): GrantResult
	local pity = if paid then data.paidEggPity else 0
	local odds = Odds.forEgg(pity)
	local rarity = WeightedRandom.pick(odds, Rarities.ORDER, rng)
	if paid then
		data.paidEggPity = if rarity == "Legendario" then 0 else data.paidEggPity + 1
		player:SetAttribute("EggPity", data.paidEggPity)
	end
	return CreatureService.grant(player, data, data.bestZone, rarity, CreatureService.rollMutation())
end

-- Alternativa NO aleatoria para jugadores con ArePaidRandomItemsRestricted (por si acaso llegara un recibo):
-- criatura Rara fija de su mejor zona, sin mutación.
function CreatureService.grantFixedEggValue(player: Player, data: PlayerData): GrantResult
	return CreatureService.grant(player, data, data.bestZone, "Raro", "Ninguna")
end

return CreatureService
