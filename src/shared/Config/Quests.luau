--!strict
-- Misiones diarias simples + tutorial + ventana de combo. Balance SOLO aquí.
-- Las misiones miden la diferencia de contadores que el servidor ya lleva (no hay hooks ni confianza
-- en el cliente) y se reinician cada día UTC. No hay penalizaciones por perder un día.

export type QuestDef = {
	id: string,
	text: string,
	target: number,
}

local QUESTS: { QuestDef } = {
	{ id = "throws", text = "Lanza 10 cápsulas", target = 10 },
	{ id = "upgrades", text = "Compra 2 mejoras", target = 2 },
	{ id = "cells", text = "Restaura 40 celdas del planeta", target = 40 },
}

return {
	QUESTS = QUESTS,
	-- Recompensa (solo dinero PERSONAL): segundos de ingreso del jardín, con un mínimo.
	REWARD_SECONDS = 120,
	REWARD_MIN = 100,
	-- Tutorial: 1 lanza, 2 mejora, 3 mira tu jardín, 4 completado.
	TUTORIAL_DONE = 4,
	-- Jugadores con tantos lanzamientos ya conocen el juego: se salta el tutorial.
	TUTORIAL_SKIP_THROWS = 5,
	-- Combo cooperativo: otro jugador a <= RADIUS studs que lanzó hace <= WINDOW s (ver ThrowService).
	COMBO_WINDOW = 1.0,
	COMBO_RADIUS = 30,
}
