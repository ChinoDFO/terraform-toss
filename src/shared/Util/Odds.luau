--!strict
-- Probabilidades en % (suman 100). Es la MISMA función para mostrar (cliente) y tirar (servidor),
-- así lo que ve el jugador es exactamente lo que se usa.
local Rarities = require(script.Parent.Parent.Config.Rarities)

export type OddsTable = { [string]: number }

local Odds = {}

-- Tirada normal (gratis, al lanzar). La suerte nunca se vende: viene del índice y de eventos.
function Odds.forLuck(luck: number): OddsTable
	local l = math.clamp(luck, 1, Rarities.MAX_LUCK)
	local result: OddsTable = {}
	local others = 0
	for i, id in Rarities.ORDER do
		if i > 1 then
			local def = Rarities.DEFS[id]
			local w = def.baseWeight * (l ^ def.luckExponent)
			result[id] = w
			others += w
		end
	end
	local commonId = Rarities.ORDER[1]
	if others > 100 then
		local scale = 100 / others
		for id, w in result do
			result[id] = w * scale
		end
		result[commonId] = 0
	else
		result[commonId] = 100 - others
	end
	return result
end

-- Huevo Estelar. pityCount = huevos pagados seguidos sin Legendario.
function Odds.forEgg(pityCount: number): OddsTable
	if pityCount >= Rarities.EGG_PITY_THRESHOLD - 1 then
		return { Raro = 0, Epico = 0, Legendario = 100 }
	end
	local result: OddsTable = {}
	for id, w in Rarities.EGG_WEIGHTS do
		result[id] = w
	end
	return result
end

function Odds.total(odds: OddsTable): number
	local sum = 0
	for _, p in odds do
		sum += p
	end
	return sum
end

-- Formato de visualización: 2 decimales, o 4 si es menor que 0,01 %.
function Odds.format(percent: number): string
	if percent > 0 and percent < 0.01 then
		return string.format("%.4f %%", percent)
	end
	return string.format("%.2f %%", percent)
end

Odds.ROUNDING_DISCLAIMER = "Probabilidades redondeadas: la suma mostrada puede no ser exactamente 100 %."

return Odds
