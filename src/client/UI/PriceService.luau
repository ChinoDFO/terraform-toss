--!strict
-- Precios en vivo para la interfaz. NUNCA hay precios escritos a mano en el cliente:
-- GetProductInfoAsync devuelve el precio de ESTE jugador (regional + descuento Roblox Plus).
local MarketplaceService = game:GetService("MarketplaceService")

export type PriceInfo = {
	price: number, -- lo que paga este jugador
	basePrice: number, -- precio antes de descuentos personales
	discountLabel: string?,
}

local CACHE_SECONDS = 60
local cache: { [string]: { info: PriceInfo, at: number } } = {}

local PriceService = {}

function PriceService.get(id: number, isPass: boolean): PriceInfo?
	if id == 0 then
		return nil
	end
	local key = (if isPass then "pass:" else "prod:") .. tostring(id)
	local hit = cache[key]
	if hit and os.clock() - hit.at < CACHE_SECONDS then
		return hit.info
	end
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfoAsync(
			id,
			if isPass then Enum.InfoType.GamePass else Enum.InfoType.Product
		)
	end)
	if not ok or type(info) ~= "table" then
		return nil
	end
	local price = tonumber(info.PriceInRobux) or 0
	local base = tonumber(info.UserBasePriceInRobux) or price
	local label: string? = nil
	if type(info.PriceDiscountDetails) == "table" then
		for _, detail in info.PriceDiscountDetails do
			if type(detail) == "table" and detail.Type == "RobloxPlusSubscription" then
				label = "Descuento Roblox Plus"
			end
		end
	end
	local result: PriceInfo = { price = price, basePrice = base, discountLabel = label }
	cache[key] = { info = result, at = os.clock() }
	return result
end

return PriceService
