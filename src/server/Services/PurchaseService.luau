--!strict
-- Compras con Robux. Principios:
--  * El cliente PIDE comprar (RequestPurchase); el servidor valida y abre el aviso de Roblox.
--  * Los artículos aleatorios pagados se bloquean si PolicyService lo exige.
--  * ProcessReceipt es idempotente: guarda el PurchaseId y confirma SOLO tras guardar.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Products = require(ReplicatedStorage.Shared.Config.Products)
local Net = require(ReplicatedStorage.Shared.Net)
local DataService = require(script.Parent.DataService)
local PolicyGate = require(script.Parent.PolicyGate)
local CreatureService = require(script.Parent.CreatureService)
local RateLimiter = require(script.Parent.Parent.Util.RateLimiter)
local Validate = require(script.Parent.Parent.Util.Validate)
local Perks = require(script.Parent.Parent.Util.Perks)

type PlayerData = Types.PlayerData
type Handler = (player: Player, data: PlayerData) -> ()

local PurchaseService = {}

local notify: RemoteEvent
local allowRequest = RateLimiter.new(2, 1)

-- FTUE: "sin ventanas de compra los primeros 3 minutos" (docs/CONTEXTO_PROYECTO.md §2).
local FTUE_SHOP_DELAY = 180
local shopAvailableAt: { [Player]: number } = {}

-- Qué hace cada producto consumible. (Los pases se aplican vía atributo Pass_<key>.)
local HANDLERS: { [string]: Handler } = {
	PackArranque = function(player: Player, data: PlayerData)
		data.trainingLevel += 3
		data.freeEggs += 1
		data.starterPackOwned = true
		player:SetAttribute("StarterPackOwned", true)
		player:SetAttribute("FreeEggs", data.freeEggs)
	end,
	HuevoEstelar = function(player: Player, data: PlayerData)
		local result
		if PolicyGate.get(player).paidRandomRestricted then
			result = CreatureService.grantFixedEggValue(player, data) -- nunca dejar un pago sin valor
		else
			result = CreatureService.openEgg(player, data, true)
		end
		notify:FireClient(player, "EggOpened", result)
	end,
	Boost30 = function(player: Player, _data: PlayerData)
		local now = os.time()
		local current = tonumber(player:GetAttribute("BoostUntil")) or 0
		player:SetAttribute("BoostUntil", math.max(current, now) + 30 * 60)
	end,
}

local function refreshPasses(player: Player)
	for _, def in Products.LIST do
		if def.isPass and def.id ~= 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, def.id)
			end)
			if ok then
				Perks.setPass(player, def.key, owns == true)
			end
		end
	end
end

local function onRequestPurchase(player: Player, rawKey: unknown)
	if not allowRequest(player) then
		return
	end
	local key = Validate.oneOf(rawKey, Products.BY_KEY)
	if key == nil then
		return
	end
	local availableAt = shopAvailableAt[player]
	if availableAt and os.time() < availableAt then
		notify:FireClient(player, "Info", { text = "La tienda se desbloquea a los pocos minutos de empezar a jugar." })
		return
	end
	local def = Products.BY_KEY[key]
	if def.id == 0 then
		notify:FireClient(player, "Info", { text = "Este artículo aún no está disponible." })
		return
	end
	if def.isRandom and PolicyGate.get(player).paidRandomRestricted then
		notify:FireClient(player, "Info", {
			text = "Este artículo no está disponible en tu región. Consigue Huevos Estelares gratis con la racha diaria y los eventos.",
		})
		return
	end
	if def.key == "PackArranque" and player:GetAttribute("StarterPackOwned") == true then
		return
	end
	if def.isPass then
		if Perks.hasPass(player, def.key) then
			return
		end
		MarketplaceService:PromptGamePassPurchase(player, def.id)
	else
		MarketplaceService:PromptProductPurchase(player, def.id)
	end
end

local function processReceipt(receipt: { [string]: any }): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if player == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- Roblox lo reintentará cuando vuelva
	end
	local data = DataService.get(player)
	if data == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local purchaseId = tostring(receipt.PurchaseId)
	if DataService.hasReceipt(data, purchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted -- ya entregado antes
	end
	local def = Products.BY_ID[receipt.ProductId]
	local handler = if def then HANDLERS[def.key] else nil
	if handler == nil then
		warn("[PurchaseService] Producto sin handler:", receipt.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local ok, err = pcall(handler, player, data)
	if not ok then
		warn("[PurchaseService] Error entregando", receipt.ProductId, err)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	DataService.addReceipt(data, purchaseId)
	if not DataService.saveNow(player) then
		-- Lo entregado queda en memoria con el recibo anotado: el reintento no lo duplicará.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function PurchaseService.init()
	notify = Net.event("Notify")
	Net.event("RequestPurchase").OnServerEvent:Connect(onRequestPurchase)

	DataService.Loaded:Connect(function(player: Player, data: PlayerData)
		local availableAt = os.time() + FTUE_SHOP_DELAY
		shopAvailableAt[player] = availableAt
		player:SetAttribute("ShopAvailableAt", availableAt)
		refreshPasses(player)
		player:SetAttribute("EggPity", data.paidEggPity)
		player:SetAttribute("FreeEggs", data.freeEggs)
		player:SetAttribute("StarterPackOwned", data.starterPackOwned)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		shopAvailableAt[player] = nil
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(
		function(player: Player, passId: number, purchased: boolean)
			if not purchased then
				return
			end
			for _, def in Products.LIST do
				if def.isPass and def.id == passId then
					Perks.setPass(player, def.key, true)
					notify:FireClient(player, "PassGranted", { key = def.key })
				end
			end
		end
	)

	MarketplaceService.ProcessReceipt = processReceipt
end

return PurchaseService
