--!strict
-- Reintentos con backoff exponencial + jitter para llamadas que pueden fallar (DataStore, Marketplace...).

local Retry = {}

function Retry.withBackoff<T>(label: string, attempts: number, fn: () -> T): (boolean, T?)
	local lastErr: any = nil
	for attempt = 1, attempts do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastErr = result
		if attempt < attempts then
			-- 2, 4, 8, 16 s (máx.) + hasta 1 s aleatorio para no saturar a la vez
			task.wait(math.min(2 ^ attempt, 16) + math.random())
		end
	end
	warn(string.format("[Retry] %s falló tras %d intentos: %s", label, attempts, tostring(lastErr)))
	return false, nil
end

return Retry
