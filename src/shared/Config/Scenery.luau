--!strict
-- Escenografía procedural por zona: aparece cuando se restauran celdas de esa franja.
-- Todo se construye con partes simples (sin modelos externos) y con presupuesto estricto.

export type Kind = "tree" | "crystal" | "dune" | "ice" | "fern" | "lava"

-- Tipo de prop por zona (índice = id de zona de Config/Zones).
local KIND_BY_ZONE: { Kind } = { "fern", "dune", "crystal", "ice", "tree", "lava" }

return {
	KIND_BY_ZONE = KIND_BY_ZONE,
	-- Máximo de props vivos por franja (techo de rendimiento: ~3 partes cada uno).
	MAX_PER_BAND = 24,
	-- Probabilidad de que una celda restaurada genere un prop (mientras quede cupo).
	SPAWN_CHANCE = 0.04,
	-- Altura máxima de un prop en studs (se escala aleatoriamente entre 0.6 y 1 de esto).
	MAX_HEIGHT = 14,
}
