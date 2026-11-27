--!strict
-- Tipos compartidos entre servidor y cliente.
-- Los IDs de rareza y mutación son strings definidos en Config/Rarities y Config/Mutations.

export type GardenSlot = {
	creatureId: string,
	mutation: string,
}

export type QuestCounters = {
	throws: number,
	upgrades: number,
	cells: number,
}

export type PlayerData = {
	version: number,
	cash: number,
	power: number,
	trainingLevel: number,
	capsuleLevel: number,
	bestZone: number,
	garden: { GardenSlot },
	index: { [string]: boolean },
	totalThrows: number,
	cellsRestored: number,
	paidEggPity: number,
	freeEggs: number,
	dailyStreak: number,
	lastDailyDay: number,
	turboUnlocked: boolean,
	starterPackOwned: boolean,
	lastOnline: number,
	receipts: { string },
	tutorialStep: number,
	questDay: number,
	questBase: QuestCounters,
	questClaimed: { boolean },
}

export type ThrowResult = {
	userId: number,
	distance: number,
	zone: number,
	creatureId: string,
	rarity: string,
	mutation: string,
	cellsChanged: number,
	combo: boolean,
	kept: boolean,
	cashFromSale: number,
	landing: Vector3,
}

return {}
