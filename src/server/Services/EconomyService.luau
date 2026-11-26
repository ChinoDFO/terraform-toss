--!strict
-- Bucle de 1 segundo: entrenamiento (+N poder/s), ingresos del jardín, sincronización con el cliente.
-- También: toques de entrenamiento, mejoras con dinero del juego e ingresos offline.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Formulas = require(ReplicatedStorage.Shared.Util.Formulas)
local Net = require(ReplicatedStorage.Shared.Net)
local DataService = require(script.Parent.DataService)
local TerraformService = require(script.Parent.TerraformService)
local CreatureService = require(script.Parent.CreatureService)
local RateLimiter = require(script.Parent.Parent.Util.RateLimiter)
local Validate = require(script.Parent.Parent.Util.Validate)
local Perks = require(script.Parent.Parent.Util.Perks)

type PlayerData = Types.PlayerData

local UPGRADE_KINDS: { [string]: boolean } = { training = true, capsule = true }
local TAP_FRACTION = 0.5 -- cada toque da 50 % de un segundo de entrenamiento

local EconomyService = {}

local allowTap = RateLimiter.new(8, 1)
local allowUpgrade = RateLimiter.new(5, 1)
local notify: RemoteEvent

local function hasTurbo(player: Player, data: PlayerData): boolean
	return data.turboUnlocked or Perks.hasPass(player, "TurboArranque")
end

function EconomyService.trainRate(player: Player, data: PlayerData): number
	return Formulas.trainingRate(data.trainingLevel, hasTurbo(player, data))
end

function EconomyService.cashMultiplier(player: Player): number
	local mult = TerraformService.planetMultiplier()
	if Perks.hasPass(player, "DobleDinero") then
		mult *= 2
	end
	if Perks.boostActive(player) then
		mult *= 2
	end
	if TerraformService.isBloom() then
		mult *= 2
	end
	return mult
end

function EconomyService.luck(player: Player, data: PlayerData): number
	return Formulas.luck(CreatureService.discoveredCount(data), TerraformService.isBloom(), Perks.adLuckActive(player))
end

local function sync(player: Player, data: PlayerData, incomePerSec: number)
	player:SetAttribute("Cash", data.cash)
	player:SetAttribute("Power", data.power)
	player:SetAttribute("IncomePerSec", incomePerSec)
	player:SetAttribute("TrainRate", EconomyService.trainRate(player, data))
	player:SetAttribute("Luck", EconomyService.luck(player, data))
	player:SetAttribute("TrainingLevel", data.trainingLevel)
	player:SetAttribute("CapsuleLevel", data.capsuleLevel)
	player:SetAttribute("BestZone", data.bestZone)
end

local function tick()
	for player, data in DataService.all() do
		data.power += EconomyService.trainRate(player, data)
		local income = Formulas.gardenIncome(data.garden) * EconomyService.cashMultiplier(player)
		data.cash += income
		sync(player, data, income)
	end
end

local function onTrainTap(player: Player)
	if not allowTap(player) then
		return
	end
	local data = DataService.get(player)
	if data then
		data.power += EconomyService.trainRate(player, data) * TAP_FRACTION
	end
end

local function onBuyUpgrade(player: Player, rawKind: unknown)
	if not allowUpgrade(player) then
		return
	end
	local kind = Validate.oneOf(rawKind, UPGRADE_KINDS)
	local data = DataService.get(player)
	if kind == nil or data == nil then
		return
	end
	local cost = if kind == "training"
		then Formulas.trainingCost(data.trainingLevel)
		else Formulas.capsuleCost(data.capsuleLevel)
	if data.cash < cost then
		notify:FireClient(player, "Info", { text = "Te falta dinero para esta mejora." })
		return
	end
	data.cash -= cost
	if kind == "training" then
		data.trainingLevel += 1
	else
		data.capsuleLevel += 1
	end
	notify:FireClient(player, "Upgraded", { kind = kind })
end

local function grantOffline(player: Player, data: PlayerData)
	local seconds = math.clamp(os.time() - data.lastOnline, 0, Formulas.OFFLINE_CAP_SECONDS)
	if seconds < 60 then
		return
	end
	local amount = Formulas.gardenIncome(data.garden) * seconds * Formulas.OFFLINE_RATE
	if amount > 0 then
		data.cash += amount
		notify:FireClient(player, "Offline", { amount = amount, seconds = seconds })
	end
end

function EconomyService.init()
	notify = Net.event("Notify")
	Net.event("TrainTap").OnServerEvent:Connect(onTrainTap)
	Net.event("BuyUpgrade").OnServerEvent:Connect(onBuyUpgrade)

	DataService.Loaded:Connect(function(player: Player, data: PlayerData)
		grantOffline(player, data)
		player:SetAttribute("Discovered", CreatureService.discoveredCount(data))
		sync(player, data, 0)
	end)

	TerraformService.onPlanetRestored(function(_planet: number)
		-- Recompensa cooperativa para TODOS los presentes: 5 min de ingresos + 1 Huevo Estelar gratis.
		for player, data in DataService.all() do
			data.cash += Formulas.gardenIncome(data.garden) * 300
			data.freeEggs += 1
			player:SetAttribute("FreeEggs", data.freeEggs)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(1)
			tick()
		end
	end)
end

return EconomyService
