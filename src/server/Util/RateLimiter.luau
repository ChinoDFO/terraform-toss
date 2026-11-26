--!strict
-- Límite de llamadas por jugador. Uso:
--   local allow = RateLimiter.new(5, 1) -- 5 por segundo
--   if not allow(player) then return end
local Players = game:GetService("Players")

local RateLimiter = {}

type Bucket = { count: number, windowStart: number }

function RateLimiter.new(maxPerWindow: number, windowSeconds: number): (Player) -> boolean
	local buckets: { [Player]: Bucket } = {}

	Players.PlayerRemoving:Connect(function(player: Player)
		buckets[player] = nil
	end)

	return function(player: Player): boolean
		local now = os.clock()
		local bucket = buckets[player]
		if bucket == nil or now - bucket.windowStart >= windowSeconds then
			buckets[player] = { count = 1, windowStart = now }
			return true
		end
		if bucket.count >= maxPerWindow then
			return false
		end
		bucket.count += 1
		return true
	end
end

return RateLimiter
