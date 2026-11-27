--!strict
-- Tienda ética:
--  * Precios en vivo (PriceService). Nunca escritos a mano.
--  * Artículos aleatorios: probabilidades visibles en la tarjeta ANTES de comprar + panel detallado
--    con botón que dice "Ver probabilidades" (un icono suelto no basta). Ocultos si la política lo exige.
--  * Botones de compra habilitados 1 s después de abrir (evita toques accidentales de niños).
--  * Compras >= 400 R$: confirmación propia en dos pasos antes del aviso oficial de Roblox.
--  * Sin temporizadores falsos, sin "¡solo hoy!", sin botones de cerrar escondidos.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Products = require(ReplicatedStorage.Shared.Config.Products)
local Rarities = require(ReplicatedStorage.Shared.Config.Rarities)
local Mutations = require(ReplicatedStorage.Shared.Config.Mutations)
local Odds = require(ReplicatedStorage.Shared.Util.Odds)
local Ui = require(script.Parent.Parent.UI.Ui)
local PriceService = require(script.Parent.Parent.UI.PriceService)

local player = Players.LocalPlayer
local ENABLE_DELAY = 1
local PLUS_PROMPT_COOLDOWN = 5

local ShopController = {}

local gui: ScreenGui
local panel: Frame
local oddsPanel: Frame
local oddsText: TextLabel
local list: ScrollingFrame
local openedAt = 0
local lastPlusPrompt = 0

-- Texto completo de probabilidades del Huevo Estelar (rareza + mutación), actualizado con el pity.
local function eggOddsText(): string
	local pity = tonumber(player:GetAttribute("EggPity")) or 0
	local odds = Odds.forEgg(pity)
	local lines = { "PROBABILIDADES — Huevo Estelar (mínimo garantizado: Raro)" }
	for _, id in Rarities.ORDER do
		local p = odds[id]
		if p ~= nil then
			table.insert(lines, string.format("  %s: %s", Rarities.DEFS[id].name, Odds.format(p)))
		end
	end
	table.insert(
		lines,
		string.format(
			"Garantía: si %d huevos pagados seguidos no dan Legendario, el siguiente es Legendario. Llevas %d.",
			Rarities.EGG_PITY_THRESHOLD,
			pity
		)
	)
	table.insert(lines, "MUTACIÓN (se tira aparte, misma tabla que al lanzar):")
	for _, id in Mutations.ORDER do
		table.insert(lines, string.format("  %s: %s", Mutations.DEFS[id].name, Odds.format(Mutations.DEFS[id].weight)))
	end
	table.insert(lines, Odds.ROUNDING_DISCLAIMER)
	return table.concat(lines, "\n")
end

local function shortEggOdds(): string
	local odds = Odds.forEgg(tonumber(player:GetAttribute("EggPity")) or 0)
	return string.format(
		"Raro %s · Épico %s · Legendario %s",
		Odds.format(odds.Raro),
		Odds.format(odds.Epico),
		Odds.format(odds.Legendario)
	)
end

local function requestPurchase(def: Products.ProductDef, buyButton: TextButton, price: number)
	if os.clock() - openedAt < ENABLE_DELAY then
		return
	end
	if price >= Products.CONFIRM_THRESHOLD_ROBUX and buyButton:GetAttribute("Confirming") ~= true then
		buyButton:SetAttribute("Confirming", true)
		buyButton.Text = string.format("¿Seguro? %d R$ — toca otra vez", price)
		task.delay(4, function()
			buyButton:SetAttribute("Confirming", false)
			buyButton.Text = "Comprar"
		end)
		return
	end
	buyButton:SetAttribute("Confirming", false)
	Net.event("RequestPurchase"):FireServer(def.key)
end

local function addCard(def: Products.ProductDef, order: number)
	local card = Ui.make("Frame", {
		Name = def.key,
		LayoutOrder = order,
		Size = UDim2.new(1, -8, 0, 120),
		BackgroundColor3 = Color3.fromRGB(35, 38, 48),
	}, list) :: Frame
	Ui.make("UICorner", { CornerRadius = UDim.new(0, 10) }, card)
	Ui.label(card, "Title", UDim2.fromScale(0.03, 0.04), UDim2.fromScale(0.6, 0.28), def.title)
	local desc = Ui.label(card, "Desc", UDim2.fromScale(0.03, 0.34), UDim2.fromScale(0.62, 0.3), def.description)
	desc.Font = Enum.Font.Gotham
	desc.TextXAlignment = Enum.TextXAlignment.Left
	local priceLabel = Ui.label(card, "Price", UDim2.fromScale(0.68, 0.06), UDim2.fromScale(0.3, 0.26), "…")
	local buy = Ui.button(
		card,
		"Buy",
		UDim2.fromScale(0.68, 0.38),
		UDim2.fromScale(0.3, 0.28),
		"Comprar",
		Color3.fromRGB(60, 170, 90)
	)

	if def.isRandom then
		local inline =
			Ui.label(card, "OddsInline", UDim2.fromScale(0.03, 0.68), UDim2.fromScale(0.62, 0.28), shortEggOdds())
		inline.Font = Enum.Font.Gotham
		local seeOdds = Ui.button(
			card,
			"SeeOdds",
			UDim2.fromScale(0.68, 0.7),
			UDim2.fromScale(0.3, 0.26),
			"Ver probabilidades",
			Color3.fromRGB(80, 90, 120)
		)
		seeOdds.Activated:Connect(function()
			oddsText.Text = eggOddsText()
			oddsPanel.Visible = true
		end)
		player:GetAttributeChangedSignal("EggPity"):Connect(function()
			inline.Text = shortEggOdds()
		end)
	end

	local currentPrice = 0
	task.spawn(function()
		local info = PriceService.get(def.id, def.isPass)
		if info then
			currentPrice = info.price
			priceLabel.Text = if info.price < info.basePrice
				then string.format("%d R$ (antes %d) %s", info.price, info.basePrice, info.discountLabel or "")
				else string.format("%d R$", info.price)
		else
			priceLabel.Text = if def.id == 0 then "Próximamente" else "No disponible"
			buy.Visible = false
		end
	end)

	buy.Activated:Connect(function()
		requestPurchase(def, buy, currentPrice)
	end)
end

local function refreshRestrictions()
	-- Si la política del jugador prohíbe artículos aleatorios pagados, ni siquiera se muestran.
	local restricted = player:GetAttribute("PaidRandomRestricted") ~= false
	for _, def in Products.LIST do
		local card = list:FindFirstChild(def.key)
		if card and card:IsA("Frame") then
			local ownedPass = def.isPass and player:GetAttribute("Pass_" .. def.key) == true
			local ownedPack = def.key == "PackArranque" and player:GetAttribute("StarterPackOwned") == true
			card.Visible = not (def.isRandom and restricted) and not ownedPass and not ownedPack
		end
	end
end

local function build()
	gui = Ui.make("ScreenGui", { Name = "Shop", ResetOnSpawn = false }, player:WaitForChild("PlayerGui")) :: ScreenGui
	local open = Ui.button(
		gui,
		"OpenShop",
		UDim2.fromScale(0.02, 0.34),
		UDim2.fromScale(0.14, 0.06),
		"Tienda",
		Color3.fromRGB(60, 120, 230)
	)
	open.Visible = false

	-- FTUE: la tienda aparece recién a los pocos minutos (docs §2), nunca antes.
	local function revealWhenAvailable()
		local availableAt = tonumber(player:GetAttribute("ShopAvailableAt"))
		if availableAt == nil then
			return
		end
		local remaining = availableAt - os.time()
		if remaining <= 0 then
			open.Visible = true
		else
			task.delay(remaining, function()
				open.Visible = true
			end)
		end
	end
	revealWhenAvailable()
	player:GetAttributeChangedSignal("ShopAvailableAt"):Connect(revealWhenAvailable)

	panel = Ui.make("Frame", {
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.6, 0.7),
		BackgroundColor3 = Color3.fromRGB(22, 24, 30),
		Visible = false,
	}, gui) :: Frame
	Ui.make("UICorner", { CornerRadius = UDim.new(0, 14) }, panel)
	-- Botón de cerrar grande, visible y con texto claro.
	local close = Ui.button(
		panel,
		"Close",
		UDim2.fromScale(0.8, 0.02),
		UDim2.fromScale(0.18, 0.08),
		"Cerrar ✕",
		Color3.fromRGB(120, 60, 60)
	)
	close.Activated:Connect(function()
		panel.Visible = false
		oddsPanel.Visible = false
	end)

	list = Ui.make("ScrollingFrame", {
		Name = "List",
		Position = UDim2.fromScale(0.02, 0.12),
		Size = UDim2.fromScale(0.96, 0.74),
		BackgroundTransparency = 1,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 8,
	}, panel) :: ScrollingFrame
	Ui.make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }, list)

	-- Roblox Plus: ventaja visible pero no abusiva; el aviso solo se abre si el jugador lo pide.
	local plus = Ui.button(
		panel,
		"Plus",
		UDim2.fromScale(0.02, 0.88),
		UDim2.fromScale(0.46, 0.1),
		"Roblox Plus: +1 hueco de jardín",
		Color3.fromRGB(40, 140, 200)
	)
	plus.Activated:Connect(function()
		if player.HasRobloxSubscription or os.clock() - lastPlusPrompt < PLUS_PROMPT_COOLDOWN then
			return
		end
		lastPlusPrompt = os.clock()
		MarketplaceService:PromptRobloxSubscriptionPurchase(player)
	end)

	local auto = Ui.button(
		panel,
		"AutoLaunch",
		UDim2.fromScale(0.52, 0.88),
		UDim2.fromScale(0.46, 0.1),
		"Auto-Lanzar: OFF",
		Color3.fromRGB(90, 90, 110)
	)
	local autoOn = false
	auto.Activated:Connect(function()
		autoOn = not autoOn
		auto.Text = if autoOn then "Auto-Lanzar: ON" else "Auto-Lanzar: OFF"
		Net.event("SetAutoLaunch"):FireServer(autoOn)
	end)

	oddsPanel = Ui.make("Frame", {
		Name = "Odds",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.5, 0.6),
		BackgroundColor3 = Color3.fromRGB(15, 15, 20),
		Visible = false,
		ZIndex = 5,
	}, gui) :: Frame
	oddsText = Ui.label(oddsPanel, "Text", UDim2.fromScale(0.04, 0.04), UDim2.fromScale(0.92, 0.78), "")
	oddsText.TextXAlignment = Enum.TextXAlignment.Left
	oddsText.TextYAlignment = Enum.TextYAlignment.Top
	oddsText.Font = Enum.Font.Gotham
	oddsText.ZIndex = 6
	local closeOdds = Ui.button(
		oddsPanel,
		"Close",
		UDim2.fromScale(0.3, 0.85),
		UDim2.fromScale(0.4, 0.11),
		"Entendido",
		Color3.fromRGB(70, 90, 140)
	)
	closeOdds.ZIndex = 6
	closeOdds.Activated:Connect(function()
		oddsPanel.Visible = false
	end)

	for i, def in Products.LIST do
		addCard(def, i)
	end

	open.Activated:Connect(function()
		panel.Visible = not panel.Visible
		openedAt = os.clock()
		auto.Visible = player:GetAttribute("Pass_AutoLanzar") == true
		plus.Visible = not player.HasRobloxSubscription
		refreshRestrictions()
	end)
end

function ShopController.init()
	build()
	player:GetAttributeChangedSignal("PaidRandomRestricted"):Connect(refreshRestrictions)
end

return ShopController
