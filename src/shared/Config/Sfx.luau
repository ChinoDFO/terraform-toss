--!strict
-- Sonidos TEMPORALES: rutas rbxasset://sounds/ que vienen con el motor de Roblox (gratis, sin
-- licencia, siempre disponibles). Sustituir por audio propio/licenciado antes de publicar.
-- pitch = PlaybackSpeed inicial (Charge lo va subiendo en vivo según el medidor).

export type SfxDef = {
	id: string,
	volume: number,
	pitch: number,
}

local DEFS: { [string]: SfxDef } = {
	Charge = { id = "rbxasset://sounds/electronicpingshort.mp3", volume = 0.45, pitch = 0.6 },
	Release = { id = "rbxasset://sounds/switch.mp3", volume = 0.6, pitch = 1 },
	Land = { id = "rbxasset://sounds/splat.mp3", volume = 0.55, pitch = 1.05 },
	RareReveal = { id = "rbxasset://sounds/snap.mp3", volume = 0.7, pitch = 1 },
	Bloom = { id = "rbxasset://sounds/electronicpingshort.mp3", volume = 0.6, pitch = 0.75 },
	PlanetRestored = { id = "rbxasset://sounds/victory.mp3", volume = 0.8, pitch = 1 },
}

return { DEFS = DEFS }
