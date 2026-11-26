--!strict
-- 1234 -> "1.23K", 5.6e15 -> "5.60Qa". Pensado para números de juego incremental.

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

local NumberFormat = {}

function NumberFormat.short(n: number): string
	if n ~= n then
		return "0"
	end
	local sign = if n < 0 then "-" else ""
	local x = math.abs(n)
	if x == math.huge then
		return sign .. "∞"
	end
	if x < 1000 then
		if x == math.floor(x) then
			return sign .. tostring(math.floor(x))
		end
		return sign .. string.format("%.1f", x)
	end

	local tier = math.min(math.floor(math.log10(x) / 3), #SUFFIXES - 1)
	local scaled = x / 10 ^ (tier * 3)
	-- Evita "1000K": si el redondeo llega a 1000, sube de sufijo.
	if scaled >= 999.5 and tier < #SUFFIXES - 1 then
		tier += 1
		scaled /= 1000
	end
	local pattern = if scaled < 10 then "%.2f" elseif scaled < 100 then "%.1f" else "%.0f"
	return sign .. string.format(pattern, scaled) .. SUFFIXES[tier + 1]
end

function NumberFormat.duration(seconds: number): string
	local s = math.max(0, math.floor(seconds))
	local m = s // 60
	return string.format("%d:%02d", m, s % 60)
end

return NumberFormat
