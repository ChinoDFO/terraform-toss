--!strict
-- Elige una clave según pesos. `order` fija el orden para que sea determinista con la misma semilla.

local WeightedRandom = {}

function WeightedRandom.pick(weights: { [string]: number }, order: { string }, rng: Random): string
	local total = 0
	for _, id in order do
		total += math.max(weights[id] or 0, 0)
	end
	assert(total > 0, "WeightedRandom: la suma de pesos es 0")

	local roll = rng:NextNumber() * total
	local acc = 0
	local lastNonZero = order[1]
	for _, id in order do
		local w = math.max(weights[id] or 0, 0)
		if w > 0 then
			acc += w
			lastNonZero = id
			if roll < acc then
				return id
			end
		end
	end
	return lastNonZero -- solo por redondeo de coma flotante
end

return WeightedRandom
