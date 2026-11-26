--!strict
-- Mutaciones: se tiran aparte de la rareza. weight en %, suman 100.

export type MutationDef = {
	id: string,
	name: string,
	weight: number,
	incomeMult: number,
}

local ORDER: { string } = { "Ninguna", "Neon", "Dorado", "Gigante", "Cristal", "Bioluminiscente", "Arcoiris" }

local DEFS: { [string]: MutationDef } = {
	Ninguna = { id = "Ninguna", name = "Sin mutación", weight = 90, incomeMult = 1 },
	Neon = { id = "Neon", name = "Neón", weight = 4, incomeMult = 1.5 },
	Dorado = { id = "Dorado", name = "Dorado", weight = 3, incomeMult = 2 },
	Gigante = { id = "Gigante", name = "Gigante", weight = 1.5, incomeMult = 2.5 },
	Cristal = { id = "Cristal", name = "Cristal", weight = 1, incomeMult = 3 },
	Bioluminiscente = { id = "Bioluminiscente", name = "Bioluminiscente", weight = 0.4, incomeMult = 4 },
	Arcoiris = { id = "Arcoiris", name = "Arcoíris", weight = 0.1, incomeMult = 5 },
}

local function weights(): { [string]: number }
	local result: { [string]: number } = {}
	for _, id in ORDER do
		result[id] = DEFS[id].weight
	end
	return result
end

return {
	ORDER = ORDER,
	DEFS = DEFS,
	weights = weights,
}
