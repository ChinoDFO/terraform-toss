--!strict
-- Consulta PolicyService por jugador. Si la consulta falla, usamos el modo MÁS restrictivo.
-- La lista de países la gestiona Roblox: nunca programes países a mano.
local PolicyService = game:GetService("PolicyService")
local Players = game:GetService("Players")

export type Policy = {
	paidRandomRestricted: boolean,
	paidTradingAllowed: boolean,
	fetched: boolean,
}

local cache: { [Player]: Policy } = {}

local PolicyGate = {}

local SAFE_DEFAULT: Policy = { paidRandomRestricted = true, paidTradingAllowed = false, fetched = false }

function PolicyGate.get(player: Player): Policy
	local cached = cache[player]
	if cached and cached.fetched then
		return cached
	end
	local ok, info = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)
	local policy: Policy
	if ok and type(info) == "table" then
		policy = {
			paidRandomRestricted = info.ArePaidRandomItemsRestricted == true,
			paidTradingAllowed = info.IsPaidItemTradingAllowed == true,
			fetched = true,
		}
	else
		warn("[PolicyGate] Falló GetPolicyInfoForPlayerAsync; se aplica modo restrictivo:", info)
		policy = SAFE_DEFAULT -- no se cachea como definitivo: se reintenta en la próxima llamada
	end
	cache[player] = policy
	-- El cliente lo usa SOLO para ocultar la tienda aleatoria; el servidor vuelve a comprobar al comprar.
	player:SetAttribute("PaidRandomRestricted", policy.paidRandomRestricted)
	return policy
end

function PolicyGate.init()
	Players.PlayerAdded:Connect(function(player: Player)
		PolicyGate.get(player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(PolicyGate.get, player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		cache[player] = nil
	end)
end

return PolicyGate
