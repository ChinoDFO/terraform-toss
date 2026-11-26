--!strict
-- Lanzamiento autoritativo:
--  1) Cliente: ThrowStart (sin datos). Servidor anota os.clock().
--  2) Cliente: ThrowRelease (sin datos). Servidor calcula el medidor con SU reloj.
--  3) Servidor decide distancia, zona, rareza, mutación y celdas; avisa a todos con ThrowResult.
-- El cliente nunca envía distancia, rareza ni posición.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Zones = require(ReplicatedStorage.Shared.Config.Zones)
local Rarities = require(ReplicatedStorage.Shared.Config.Rarities)
local Formulas = require(ReplicatedStorage.Shared.Util.Formulas)
local Meter = require(ReplicatedStorage.Shared.Util.Meter)
local Odds = require(ReplicatedStorage.Shared.Util.Odds)
local WeightedRandom = require(ReplicatedStorage.Shared.Util.WeightedRandom)
local Net = require(ReplicatedStorage.Shared.Net)
local DataService = require(script.Parent.DataService)
local CreatureService = require(script.Parent.CreatureService)
local TerraformService = require(script.Parent.TerraformService)
local EconomyService = require(script.Parent.EconomyService)
local RateLimiter = require(script.Parent.Parent.Util.RateLimiter)
local Perks = require(script.Parent.Parent.Util.Perks)

type PlayerData = Types.PlayerData

local COOLDOWN = 1.2
local COMBO_WINDOW = 1.0
local COMBO_RADIUS = 30
local COMBO_DISTANCE_BONUS = 1.25
local COMBO_LUCK_BONUS = 0.1
local AUTO_INTERVAL = 4
local AUTO_METER = 1.5

type ThrowState = { chargeStart: number?, lastThrow: number, lastRelease: number }

local states: { [Player]: ThrowState } = {}
local rng = Random.new()
local resultEvent: RemoteEvent
local allowStart = RateLimiter.new(3, 1)
local allowRelease = RateLimiter.new(3, 1)

local ThrowService = {}

local function stateOf(player: Player): ThrowState
	local s = states[player]
	if s == nil then
		s = { chargeStart = nil, lastThrow = 0, lastRelease = 0 }
		states[player] = s
	end
	return s
end

local function rootPosition(player: Player): Vector3?
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if root and root:IsA("BasePart") then
		return root.Position
	end
	return nil
end

-- ¿Otro jugador cercano lanzó hace menos de COMBO_WINDOW s?
local function findComboPartner(player: Player, now: number): boolean
	local myPos = rootPosition(player)
	if myPos == nil then
		return false
	end
	for other, s in states do
		if other ~= player and now - s.lastRelease <= COMBO_WINDOW then
			local pos = rootPosition(other)
			if pos and (pos - myPos).Magnitude <= COMBO_RADIUS then
				return true
			end
		end
	end
	return false
end

local function resolveThrow(player: Player, data: PlayerData, meterMult: number)
	local s = stateOf(player)
	local now = os.clock()
	local combo = findComboPartner(player, now)
	s.lastRelease = now
	s.lastThrow = now

	local distance = data.power
		* meterMult
		* Formulas.capsuleMultiplier(data.capsuleLevel)
		* (if combo then COMBO_DISTANCE_BONUS else 1)
	local zone = Zones.forDistance(distance)
	data.bestZone = math.max(data.bestZone, zone)

	local rarity: string
	if data.totalThrows == 0 then
		rarity = "PocoComun" -- FTUE: el primer lanzamiento siempre emociona (acción gratuita, no pagada)
	else
		local luck = EconomyService.luck(player, data) + (if combo then COMBO_LUCK_BONUS else 0)
		rarity = WeightedRandom.pick(Odds.forLuck(luck), Rarities.ORDER, rng)
	end
	data.totalThrows += 1

	local grant = CreatureService.grant(player, data, zone, rarity, CreatureService.rollMutation())
	local cells, landing = TerraformService.applyThrow(zone, Rarities.DEFS[rarity].cellsPerThrow)
	data.cellsRestored += cells

	local result: Types.ThrowResult = {
		userId = player.UserId,
		distance = distance,
		zone = zone,
		creatureId = grant.creatureId,
		rarity = grant.rarity,
		mutation = grant.mutation,
		cellsChanged = cells,
		combo = combo,
		kept = grant.kept,
		cashFromSale = grant.cashFromSale,
		landing = landing,
	}
	resultEvent:FireAllClients(result) -- todos ven volar las cápsulas: espectáculo social
end

local function onThrowStart(player: Player)
	if not allowStart(player) then
		return
	end
	local s = stateOf(player)
	if os.clock() - s.lastThrow < COOLDOWN then
		return
	end
	s.chargeStart = os.clock()
end

local function onThrowRelease(player: Player)
	if not allowRelease(player) then
		return
	end
	local s = stateOf(player)
	local start = s.chargeStart
	local data = DataService.get(player)
	if start == nil or data == nil then
		return
	end
	s.chargeStart = nil
	resolveThrow(player, data, Meter.multiplierAt(os.clock() - start))
end

function ThrowService.init()
	resultEvent = Net.event("ThrowResult")
	Net.event("ThrowStart").OnServerEvent:Connect(onThrowStart)
	Net.event("ThrowRelease").OnServerEvent:Connect(onThrowRelease)
	Net.event("SetAutoLaunch").OnServerEvent:Connect(function(player: Player, enabled: unknown)
		if typeof(enabled) == "boolean" and allowStart(player) then
			player:SetAttribute("AutoLaunchOn", enabled and Perks.hasPass(player, "AutoLanzar"))
		end
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		states[player] = nil
	end)

	-- Pase Auto-Lanzamiento: lanza cada AUTO_INTERVAL s con medidor x1,5 si el jugador lo activó.
	task.spawn(function()
		while true do
			task.wait(AUTO_INTERVAL)
			for player, data in DataService.all() do
				if Perks.hasPass(player, "AutoLanzar") and player:GetAttribute("AutoLaunchOn") == true then
					local s = stateOf(player)
					if s.chargeStart == nil and os.clock() - s.lastThrow >= COOLDOWN then
						resolveThrow(player, data, AUTO_METER)
					end
				end
			end
		end
	end)
end

return ThrowService
