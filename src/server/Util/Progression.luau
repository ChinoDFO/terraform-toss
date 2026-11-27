--!strict
-- Lógica PURA de progresión (tutorial, misiones diarias, meta siguiente). Sin Roblox services,
-- para poder probarla en TestRunner. El servidor es quien la aplica y decide.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Quests = require(ReplicatedStorage.Shared.Config.Quests)
local Creatures = require(ReplicatedStorage.Shared.Config.Creatures)
local Rarities = require(ReplicatedStorage.Shared.Config.Rarities)
local Zones = require(ReplicatedStorage.Shared.Config.Zones)
local Formulas = require(ReplicatedStorage.Shared.Util.Formulas)
local NumberFormat = require(ReplicatedStorage.Shared.Util.NumberFormat)

type PlayerData = Types.PlayerData

local Progression = {}

local function counters(data: PlayerData): Types.QuestCounters
	return {
		throws = data.totalThrows,
		upgrades = data.trainingLevel + data.capsuleLevel,
		cells = data.cellsRestored,
	}
end

-- Si cambió el día UTC, reinicia las misiones (toma los contadores actuales como base).
function Progression.rollQuests(data: PlayerData, day: number): boolean
	if data.questDay == day then
		return false
	end
	data.questDay = day
	data.questBase = counters(data)
	data.questClaimed = { false, false, false }
	return true
end

function Progression.questProgress(data: PlayerData, index: number): number
	local quest = Quests.QUESTS[index]
	if quest == nil then
		return 0
	end
	local now = (counters(data) :: any)[quest.id] or 0
	local base = (data.questBase :: any)[quest.id] or 0
	return math.clamp(now - base, 0, quest.target)
end

function Progression.questComplete(data: PlayerData, index: number): boolean
	local quest = Quests.QUESTS[index]
	return quest ~= nil and Progression.questProgress(data, index) >= quest.target
end

function Progression.questReward(data: PlayerData): number
	return math.max(Quests.REWARD_MIN, Formulas.gardenIncome(data.garden) * Quests.REWARD_SECONDS)
end

-- Avanza los pasos automáticos del tutorial (1 → 2 → 3). El paso 3 -> 4 solo con el "Entendido"
-- del jugador (validado aparte). Devuelve el paso resultante.
function Progression.advanceTutorial(data: PlayerData): number
	local step = data.tutorialStep
	if step >= Quests.TUTORIAL_DONE then
		return step
	end
	if step == 1 and data.totalThrows >= Quests.TUTORIAL_SKIP_THROWS then
		return Quests.TUTORIAL_DONE -- jugador veterano
	end
	if step == 1 and data.totalThrows >= 1 then
		step = 2
	end
	if step == 2 and data.trainingLevel + data.capsuleLevel >= 1 then
		step = 3
	end
	return step
end

-- Texto de la meta visible: siguiente criatura sin descubrir (de las zonas ya alcanzadas) y siguiente zona.
function Progression.nextGoal(data: PlayerData): string
	local parts: { string } = {}
	for _, creature in Creatures.LIST do
		if creature.zone <= data.bestZone and data.index[creature.id] ~= true then
			local rarity = Rarities.DEFS[creature.rarity]
			table.insert(parts, string.format("Próxima criatura: %s (%s)", creature.name, rarity.name))
			break
		end
	end
	local nextZone = Zones.ZONES[data.bestZone + 1]
	if nextZone then
		table.insert(
			parts,
			string.format("Próxima zona: %s a %s m", nextZone.name, NumberFormat.short(nextZone.minDistance))
		)
	end
	if #parts == 0 then
		return "¡Colección completa y todas las zonas alcanzadas!"
	end
	return table.concat(parts, " · ")
end

return Progression
