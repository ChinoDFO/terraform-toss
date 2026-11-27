--!strict
-- Ambiente visual según el progreso del planeta (0 % apagado/gris → 100 % cálido/verde).
-- Solo cosmético: lo usa el cliente (AmbienceController) y se prueba en TestRunner.

export type Look = {
	ambient: Color3,
	outdoorAmbient: Color3,
	brightness: number,
	clockTime: number,
	fogColor: Color3,
	atmosphereDensity: number,
	atmosphereHaze: number,
	skyTint: Color3,
	bloomIntensity: number,
	saturation: number,
	tint: Color3,
	contrast: number,
}

-- Planeta muerto: gris, neblinoso, sin brillo.
local DEAD: Look = {
	ambient = Color3.fromRGB(70, 70, 78),
	outdoorAmbient = Color3.fromRGB(95, 95, 105),
	brightness = 1.2,
	clockTime = 16.5,
	fogColor = Color3.fromRGB(120, 120, 128),
	atmosphereDensity = 0.45,
	atmosphereHaze = 2.2,
	skyTint = Color3.fromRGB(150, 150, 160),
	bloomIntensity = 0.1,
	saturation = -0.55,
	tint = Color3.fromRGB(215, 215, 225),
	contrast = 0.05,
}

-- Planeta restaurado: cálido, verde, brillante.
local ALIVE: Look = {
	ambient = Color3.fromRGB(120, 130, 100),
	outdoorAmbient = Color3.fromRGB(150, 175, 120),
	brightness = 2.6,
	clockTime = 14,
	fogColor = Color3.fromRGB(190, 225, 190),
	atmosphereDensity = 0.25,
	atmosphereHaze = 0.8,
	skyTint = Color3.fromRGB(110, 170, 255),
	bloomIntensity = 0.6,
	saturation = 0.25,
	tint = Color3.fromRGB(255, 244, 220),
	contrast = 0.1,
}

local function lerpLook(a: Look, b: Look, t: number): Look
	return {
		ambient = a.ambient:Lerp(b.ambient, t),
		outdoorAmbient = a.outdoorAmbient:Lerp(b.outdoorAmbient, t),
		brightness = a.brightness + (b.brightness - a.brightness) * t,
		clockTime = a.clockTime + (b.clockTime - a.clockTime) * t,
		fogColor = a.fogColor:Lerp(b.fogColor, t),
		atmosphereDensity = a.atmosphereDensity + (b.atmosphereDensity - a.atmosphereDensity) * t,
		atmosphereHaze = a.atmosphereHaze + (b.atmosphereHaze - a.atmosphereHaze) * t,
		skyTint = a.skyTint:Lerp(b.skyTint, t),
		bloomIntensity = a.bloomIntensity + (b.bloomIntensity - a.bloomIntensity) * t,
		saturation = a.saturation + (b.saturation - a.saturation) * t,
		tint = a.tint:Lerp(b.tint, t),
		contrast = a.contrast + (b.contrast - a.contrast) * t,
	}
end

-- percent en [0, 100]; valores fuera de rango o NaN se acotan.
local function at(percent: number): Look
	local p = percent
	if p ~= p then
		p = 0
	end
	local t = math.clamp(p, 0, 100) / 100
	-- Curva suave: el cambio se nota pronto pero llega al máximo solo al final.
	t = t * t * (3 - 2 * t)
	return lerpLook(DEAD, ALIVE, t)
end

return {
	DEAD = DEAD,
	ALIVE = ALIVE,
	at = at,
	-- Segundos que tarda el cliente en transicionar a un nuevo estado.
	TWEEN_SECONDS = 4,
}
