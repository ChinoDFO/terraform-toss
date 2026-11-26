--!strict
-- Zonas del planeta por distancia de lanzamiento (en "metros" de juego).
-- Ritmo simulado (juego activo, sin Turbo): zona 2 ~1 min, 3 ~3 min, 4 ~15 min, 5 ~1,5 h, 6 ~12 h.

export type ZoneDef = {
	id: number,
	name: string,
	minDistance: number,
	baseIncome: number,
	color: Color3,
}

local ZONES: { ZoneDef } = {
	{ id = 1, name = "Páramo Gris", minDistance = 0, baseIncome = 1, color = Color3.fromRGB(120, 200, 90) },
	{ id = 2, name = "Dunas de Óxido", minDistance = 200, baseIncome = 6, color = Color3.fromRGB(230, 170, 80) },
	{ id = 3, name = "Cráter Salino", minDistance = 3_000, baseIncome = 36, color = Color3.fromRGB(150, 220, 230) },
	{ id = 4, name = "Glaciar Dormido", minDistance = 50_000, baseIncome = 220, color = Color3.fromRGB(170, 200, 255) },
	{ id = 5, name = "Bosque Fósil", minDistance = 900_000, baseIncome = 1_300, color = Color3.fromRGB(60, 160, 80) },
	{
		id = 6,
		name = "Núcleo Volcánico",
		minDistance = 20_000_000,
		baseIncome = 8_000,
		color = Color3.fromRGB(255, 110, 60),
	},
}

local function forDistance(distance: number): number
	local zone = 1
	for _, def in ZONES do
		if distance >= def.minDistance then
			zone = def.id
		end
	end
	return zone
end

return {
	ZONES = ZONES,
	COUNT = #ZONES,
	forDistance = forDistance,
}
