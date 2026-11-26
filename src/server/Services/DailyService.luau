--!strict
-- Recompensa diaria con racha (ciclo de 7 días) y Huevos Estelares GRATUITOS.
--  * Día 3 de racha: desbloquea el Turbo x2 de entrenamiento gratis y para siempre.
--  * Día 7: 1 Huevo Estelar gratis (la alternativa gratuita a la compra aleatoria).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Formulas = require(ReplicatedStorage.Shared.Util.Formulas)
local Net = require(ReplicatedStorage.Shared.Net)
local DataService = require(script.Parent.DataService)
local CreatureService = require(script.Parent.CreatureService)
local RateLimiter = require(script.Parent.Parent.Util.RateLimiter)

type PlayerData = Types.PlayerData

local DAY = 86400
local TURBO_STREAK = 3
local EGG_STREAK = 7

local DailyService = {}
local notify: RemoteEvent
local allowClaim = RateLimiter.new(1, 1)
local allowEgg = RateLimiter.new(2, 1)

local function today(): number
	return os.time() // DAY -- día UTC
end

local function syncDaily(player: Player, data: PlayerData)
	player:SetAttribute("DailyStreak", data.dailyStreak)
	player:SetAttribute("DailyAvailable", data.lastDailyDay ~= today())
	player:SetAttribute("TurboUnlocked", data.turboUnlocked)
	player:SetAttribute("FreeEggs", data.freeEggs)
end

local function onClaim(player: Player)
	if not allowClaim(player) then
		return
	end
	local data = DataService.get(player)
	if data == nil then
		return
	end
	local day = today()
	if data.lastDailyDay == day then
		return
	end
	data.dailyStreak = if data.lastDailyDay == day - 1 then data.dailyStreak + 1 else 1
	data.lastDailyDay = day

	local cycleDay = (data.dailyStreak - 1) % EGG_STREAK + 1
	-- Dinero: 60 s de ingreso del jardín por día de racha (mínimo 50).
	local cash = math.max(50, Formulas.gardenIncome(data.garden) * 60 * cycleDay)
	data.cash += cash
	if data.dailyStreak >= TURBO_STREAK and not data.turboUnlocked then
		data.turboUnlocked = true
	end
	if cycleDay == EGG_STREAK then
		data.freeEggs += 1
	end
	syncDaily(player, data)
	notify:FireClient(player, "Daily", { streak = data.dailyStreak, cycleDay = cycleDay, cash = cash })
end

local function onOpenFreeEgg(player: Player)
	if not allowEgg(player) then
		return
	end
	local data = DataService.get(player)
	if data == nil or data.freeEggs <= 0 then
		return
	end
	data.freeEggs -= 1
	local result = CreatureService.openEgg(player, data, false)
	syncDaily(player, data)
	notify:FireClient(player, "EggOpened", result)
end

function DailyService.init()
	notify = Net.event("Notify")
	Net.event("ClaimDaily").OnServerEvent:Connect(onClaim)
	Net.event("OpenFreeEgg").OnServerEvent:Connect(onOpenFreeEgg)
	DataService.Loaded:Connect(function(player: Player, data: PlayerData)
		syncDaily(player, data)
	end)
end

return DailyService
