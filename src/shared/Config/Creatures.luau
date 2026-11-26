--!strict
-- 30 criaturas: 6 zonas x 5 rarezas. Nombres originales (no usar IP de terceros).
local Rarities = require(script.Parent.Rarities)

export type CreatureDef = {
	id: string,
	name: string,
	zone: number,
	rarity: string,
}

-- Un nombre por rareza, en el orden de Rarities.ORDER.
local NAMES_BY_ZONE: { { string } } = {
	{ "Brotín", "Musgolín", "Cactopo", "Liquenzorro", "Rocalirio" },
	{ "Arenuga", "Escarabrote", "Dunalce", "Oxidrago", "Faraonix" },
	{ "Salmorito", "Cristortuga", "Geodín", "Salamandrina", "Halitón Rey" },
	{ "Escarchín", "Pingüiflor", "Morsaurio", "Auroralce", "Gélidra" },
	{ "Ambarín", "Helechoso", "Trilobrote", "Raptor Raíz", "Secuoyón" },
	{ "Brasita", "Magmapo", "Obsidiano", "Fénix Verde", "Corazón de Gaia" },
}

local LIST: { CreatureDef } = {}
local BY_ID: { [string]: CreatureDef } = {}
local BY_ZONE_RARITY: { [string]: CreatureDef } = {}

for zone, names in NAMES_BY_ZONE do
	for i, rarity in Rarities.ORDER do
		local def: CreatureDef = {
			id = string.format("z%d_%s", zone, rarity),
			name = names[i],
			zone = zone,
			rarity = rarity,
		}
		table.insert(LIST, def)
		BY_ID[def.id] = def
		BY_ZONE_RARITY[zone .. ":" .. rarity] = def
	end
end

local function get(zone: number, rarity: string): CreatureDef
	local def = BY_ZONE_RARITY[zone .. ":" .. rarity]
	assert(def, "Criatura inexistente: " .. zone .. ":" .. rarity)
	return def
end

return {
	LIST = LIST,
	BY_ID = BY_ID,
	COUNT = #LIST,
	get = get,
}
