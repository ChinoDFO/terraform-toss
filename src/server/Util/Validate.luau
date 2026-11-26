--!strict
-- Validación de argumentos que llegan del cliente. TODO lo que llega de un RemoteEvent es sospechoso.

local Validate = {}

-- String corto y de una lista blanca.
function Validate.oneOf(value: unknown, allowed: { [string]: any }): string?
	if typeof(value) ~= "string" then
		return nil
	end
	local s = value :: string
	if #s == 0 or #s > 40 then
		return nil
	end
	if allowed[s] == nil then
		return nil
	end
	return s
end

-- Número finito dentro de un rango (rechaza NaN e infinito).
function Validate.number(value: unknown, min: number, max: number): number?
	if typeof(value) ~= "number" then
		return nil
	end
	local n = value :: number
	if n ~= n or n == math.huge or n == -math.huge then
		return nil
	end
	if n < min or n > max then
		return nil
	end
	return n
end

return Validate
