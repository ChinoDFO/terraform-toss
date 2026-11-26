--!strict
-- Ventaja de Roblox Plus: +1 hueco de jardín. Se verifica SIEMPRE en el servidor con
-- Player.HasRobloxSubscription (y su señal de cambio), nunca con lo que diga el cliente.
-- El aviso de suscripción lo abre el cliente con PromptRobloxSubscriptionPurchase.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)

local PlusService = {}

local function apply(player: Player)
	local subscribed = player.HasRobloxSubscription == true
	local had = player:GetAttribute("PlusPerk") == true
	player:SetAttribute("PlusPerk", subscribed)
	if subscribed and not had then
		Net.event("Notify")
			:FireClient(player, "PlusPerk", { text = "¡Gracias por apoyar! +1 hueco de jardín activado." })
	end
end

local function watch(player: Player)
	apply(player)
	player:GetPropertyChangedSignal("HasRobloxSubscription"):Connect(function()
		apply(player)
	end)
end

function PlusService.init()
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		task.spawn(watch, player)
	end
end

return PlusService
