--!strict
-- Rarezas de criaturas. baseWeight = probabilidad base en % (deben sumar 100).
-- luckExponent: cuánto amplifica la suerte esa rareza (0 = nada).

export type RarityDef = {
	id: string,
	name: string,
	baseWeight: number,
	luckExponent: number,
	incomeMult: number,
	cellsPerThrow: number,
	color: Color3,
}

local ORDER: { string } = { "Comun", "PocoComun", "Raro", "Epico", "Legendario" }

local DEFS: { [string]: RarityDef } = {
	Comun = {
		id = "Comun",
		name = "Común",
		baseWeight = 62,
		luckExponent = 0,
		incomeMult = 1,
		cellsPerThrow = 3,
		color = Color3.fromRGB(190, 190, 190),
	},
	PocoComun = {
		id = "PocoComun",
		name = "Poco común",
		baseWeight = 25,
		luckExponent = 0.35,
		incomeMult = 2,
		cellsPerThrow = 6,
		color = Color3.fromRGB(110, 210, 110),
	},
	Raro = {
		id = "Raro",
		name = "Raro",
		baseWeight = 10,
		luckExponent = 0.6,
		incomeMult = 5,
		cellsPerThrow = 12,
		color = Color3.fromRGB(80, 150, 255),
	},
	Epico = {
		id = "Epico",
		name = "Épico",
		baseWeight = 2.7,
		luckExponent = 0.85,
		incomeMult = 15,
		cellsPerThrow = 24,
		color = Color3.fromRGB(190, 90, 255),
	},
	Legendario = {
		id = "Legendario",
		name = "Legendario",
		baseWeight = 0.3,
		luckExponent = 1,
		incomeMult = 60,
		cellsPerThrow = 60,
		color = Color3.fromRGB(255, 190, 40),
	},
}

-- Huevo Estelar (pagado o gratuito): mínimo garantizado = Raro. Suma 100.
local EGG_WEIGHTS: { [string]: number } = {
	Raro = 75,
	Epico = 22,
	Legendario = 3,
}

-- Cada 10 huevos estelares PAGADOS sin Legendario, el siguiente es Legendario (pity, se divulga).
local EGG_PITY_THRESHOLD = 10

local MAX_LUCK = 5

return {
	ORDER = ORDER,
	DEFS = DEFS,
	EGG_WEIGHTS = EGG_WEIGHTS,
	EGG_PITY_THRESHOLD = EGG_PITY_THRESHOLD,
	MAX_LUCK = MAX_LUCK,
}
