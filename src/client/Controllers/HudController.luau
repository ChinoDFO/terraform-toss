--!strict
-- HUD: dinero, poder, barra compartida del planeta, botones de entrenamiento/mejoras/diario
-- y avisos emergentes (con pool). Solo MUESTRA: toda la lógica vive en el servidor.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Net = require(ReplicatedStorage.Shared.Net)
local Formulas = require(ReplicatedStorage.Shared.Util.Formulas)
local NumberFormat = require(ReplicatedStorage.Shared.Util.NumberFormat)
local Creatures = require(ReplicatedStorage.Shared.Config.Creatures)
local Rarities = require(ReplicatedStorage.Shared.Config.Rarities)
local Mutations = require(ReplicatedStorage.Shared.Config.Mutations)
local Zones = require(ReplicatedStorage.Shared.Config.Zones)
local Ui = require(script.Parent.Parent.UI.Ui)
local UIPool = require(script.Parent.Parent.UI.UIPool)
local Sfx = require(script.Parent.Parent.UI.Sfx)

local player = Players.LocalPlayer
local HudController = {}

local gui: ScreenGui
local toastPool: UIPool.Pool<TextLabel>
local toastHolder: Frame

local function attrNumber(name: string): number
	return tonumber(player:GetAttribute(name)) or 0
end

function HudController.toast(text: string, color: Color3?)
	local label = toastPool.acquire()
	label.Text = text
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextTransparency = 0
	label.Visible = true
	label.LayoutOrder = -os.clock() * 1000 // 1 -- lo más nuevo arriba
	label.Parent = toastHolder
	task.delay(2.5, function()
		local tween = TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1 })
		tween:Play()
		tween.Completed:Wait()
		toastPool.release(label)
	end)
end

local function build()
	gui = Ui.make("ScreenGui", { Name = "Hud", ResetOnSpawn = false }, player:WaitForChild("PlayerGui")) :: ScreenGui

	local cash = Ui.label(gui, "Cash", UDim2.fromScale(0.02, 0.02), UDim2.fromScale(0.3, 0.06), "$0")
	local income = Ui.label(gui, "Income", UDim2.fromScale(0.02, 0.08), UDim2.fromScale(0.3, 0.04), "+$0/s")
	local power = Ui.label(gui, "Power", UDim2.fromScale(0.02, 0.12), UDim2.fromScale(0.3, 0.04), "Poder 0")

	-- Barra del planeta (compartida por todo el servidor)
	local bar = Ui.make("Frame", {
		Name = "PlanetBar",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.02),
		Size = UDim2.fromScale(0.36, 0.035),
		BackgroundColor3 = Color3.fromRGB(40, 40, 45),
	}, gui) :: Frame
	Ui.make("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)
	local fill = Ui.make(
		"Frame",
		{ Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(90, 220, 110) },
		bar
	) :: Frame
	Ui.make("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
	local planetText =
		Ui.label(gui, "PlanetText", UDim2.fromScale(0.32, 0.06), UDim2.fromScale(0.36, 0.035), "Planeta 1 · 0 %")

	-- Botones (tamaño grande para pulgares en móvil)
	local train = Ui.button(
		gui,
		"Train",
		UDim2.fromScale(0.02, 0.78),
		UDim2.fromScale(0.16, 0.08),
		"ENTRENAR",
		Color3.fromRGB(60, 120, 230)
	)
	local upTrain = Ui.button(
		gui,
		"UpTrain",
		UDim2.fromScale(0.02, 0.68),
		UDim2.fromScale(0.16, 0.08),
		"+Entreno",
		Color3.fromRGB(70, 170, 90)
	)
	local upCapsule = Ui.button(
		gui,
		"UpCapsule",
		UDim2.fromScale(0.19, 0.68),
		UDim2.fromScale(0.16, 0.08),
		"+Cápsula",
		Color3.fromRGB(70, 170, 90)
	)
	local daily = Ui.button(
		gui,
		"Daily",
		UDim2.fromScale(0.02, 0.2),
		UDim2.fromScale(0.14, 0.06),
		"Diario",
		Color3.fromRGB(230, 160, 40)
	)
	local eggs = Ui.button(
		gui,
		"FreeEggs",
		UDim2.fromScale(0.02, 0.27),
		UDim2.fromScale(0.14, 0.06),
		"Huevos",
		Color3.fromRGB(160, 90, 230)
	)

	toastHolder = Ui.make("Frame", {
		Name = "Toasts",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.12),
		Size = UDim2.fromScale(0.5, 0.3),
		BackgroundTransparency = 1,
	}, gui) :: Frame
	Ui.make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, toastHolder)

	toastPool = UIPool.new(function(): TextLabel
		local label = Ui.label(toastHolder, "Toast", UDim2.new(), UDim2.fromScale(1, 0.15), "")
		label.Visible = false
		return label
	end, function(label: TextLabel)
		label.Visible = false
		label.Parent = nil
	end, 6)

	local trainTap = Net.event("TrainTap")
	local buyUpgrade = Net.event("BuyUpgrade")
	train.Activated:Connect(function()
		trainTap:FireServer()
	end)
	upTrain.Activated:Connect(function()
		buyUpgrade:FireServer("training")
	end)
	upCapsule.Activated:Connect(function()
		buyUpgrade:FireServer("capsule")
	end)
	daily.Activated:Connect(function()
		Net.event("ClaimDaily"):FireServer()
	end)
	eggs.Activated:Connect(function()
		Net.event("OpenFreeEgg"):FireServer()
	end)

	local state = Net.serverState()
	local function refresh()
		cash.Text = "$" .. NumberFormat.short(attrNumber("Cash"))
		income.Text = "+$" .. NumberFormat.short(attrNumber("IncomePerSec")) .. "/s"
		power.Text = string.format(
			"Poder %s (+%s/s)",
			NumberFormat.short(attrNumber("Power")),
			NumberFormat.short(attrNumber("TrainRate"))
		)
		upTrain.Text = "+Entreno $" .. NumberFormat.short(Formulas.trainingCost(attrNumber("TrainingLevel")))
		upCapsule.Text = "+Cápsula $" .. NumberFormat.short(Formulas.capsuleCost(attrNumber("CapsuleLevel")))
		daily.Visible = player:GetAttribute("DailyAvailable") == true
		local freeEggs = attrNumber("FreeEggs")
		eggs.Visible = freeEggs > 0
		eggs.Text = string.format("Huevos (%d)", freeEggs)

		local pct = tonumber(state:GetAttribute("PlanetPercent")) or 0
		local planet = tonumber(state:GetAttribute("Planet")) or 1
		local bloomLeft = (tonumber(state:GetAttribute("BloomUntil")) or 0) - os.time()
		-- 9.216 celdas lógicas (96x96): un lanzamiento Común sube ~0,01 %. Un ancho mínimo visible y
		-- más decimales evitan que el jugador sienta que "no sirvió de nada".
		local fillFraction = if pct > 0 then math.max(pct / 100, 0.01) else 0
		fill.Size = UDim2.fromScale(math.clamp(fillFraction, 0, 1), 1)
		local pctText = if pct < 1 then string.format("%.2f", pct) else string.format("%.1f", pct)
		planetText.Text = string.format("Planeta %d · %s %%", planet, pctText)
			.. (if bloomLeft > 0 then " · BLOOM " .. NumberFormat.duration(bloomLeft) else "")
	end

	-- Refresco ligero 4 veces por segundo (más barato que conectar 15 señales distintas)
	task.spawn(function()
		while gui.Parent do
			refresh()
			task.wait(0.25)
		end
	end)
end

local function describe(creatureId: string, rarity: string, mutation: string): string
	local creature = Creatures.BY_ID[creatureId]
	local name = if creature then creature.name else creatureId
	local rarityName = Rarities.DEFS[rarity] and Rarities.DEFS[rarity].name or rarity
	local mutationDef = Mutations.DEFS[mutation]
	local prefix = if mutationDef and mutation ~= "Ninguna" then mutationDef.name .. " " else ""
	return string.format("%s%s (%s)", prefix, name, rarityName)
end

function HudController.init()
	build()

	Net.event("ThrowResult").OnClientEvent:Connect(function(result: any)
		if type(result) ~= "table" or result.userId ~= player.UserId then
			return
		end
		local rarity = Rarities.DEFS[result.rarity]
		local zone = Zones.ZONES[result.zone]
		local text = describe(result.creatureId, result.rarity, result.mutation)
			.. string.format(" · %s · +%d celdas", zone and zone.name or "?", result.cellsChanged)
		if result.combo then
			text = "¡COMBO! " .. text
		end
		HudController.toast(text, rarity and rarity.color or nil)
		if result.rarity == "Epico" or result.rarity == "Legendario" then
			Sfx.play("RareReveal")
		end
	end)

	Net.event("Notify").OnClientEvent:Connect(function(kind: any, data: any)
		if type(data) ~= "table" then
			return
		end
		if kind == "Bloom" then
			HudController.toast(
				string.format("🌸 ¡BLOOM al %d %%! x2 dinero y +suerte para todos", data.percent),
				Color3.fromRGB(255, 150, 220)
			)
			Sfx.play("Bloom")
		elseif kind == "PlanetRestored" then
			HudController.toast("🌍 ¡PLANETA RESTAURADO! Recompensa para todos", Color3.fromRGB(120, 255, 140))
			Sfx.play("PlanetRestored")
		elseif kind == "Offline" then
			HudController.toast("Mientras no estabas tu jardín generó $" .. NumberFormat.short(data.amount))
		elseif kind == "Daily" then
			HudController.toast(string.format("Racha día %d: +$%s", data.streak, NumberFormat.short(data.cash)))
		elseif kind == "EggOpened" then
			HudController.toast(
				"Huevo: " .. describe(data.creatureId, data.rarity, data.mutation),
				Color3.fromRGB(200, 160, 255)
			)
		elseif type(data.text) == "string" then
			HudController.toast(data.text)
		end
	end)
end

return HudController
