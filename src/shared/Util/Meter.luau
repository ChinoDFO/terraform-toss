--!strict
-- Medidor de lanzamiento determinista. El cliente lo DIBUJA, el servidor lo CALCULA
-- con su propio reloj (os.clock entre ThrowStart y ThrowRelease). El cliente nunca envía el valor.

local Meter = {}

Meter.PERIOD = 1.6 -- segundos para ir de 0 a 1 y volver a 0
Meter.MAX_HOLD = 8 -- más de esto se considera lanzamiento débil

function Meter.valueAt(elapsed: number): number
	if elapsed ~= elapsed or elapsed < 0 then
		return 0
	end
	local t = (elapsed % Meter.PERIOD) / Meter.PERIOD
	return if t < 0.5 then t * 2 else (1 - t) * 2
end

function Meter.multiplierFor(value: number): number
	if value >= 0.9 then
		return 2 -- zona verde (perfecto)
	elseif value >= 0.7 then
		return 1.5 -- zona amarilla
	end
	return 1
end

function Meter.multiplierAt(elapsed: number): number
	if elapsed > Meter.MAX_HOLD then
		return 1
	end
	return Meter.multiplierFor(Meter.valueAt(elapsed))
end

return Meter
