--!strict
-- Persistencia segura de datos del jugador.
--  * UpdateAsync (nunca SetAsync) para no pisar datos.
--  * Bloqueo de sesión: un registro solo puede estar abierto en UN servidor a la vez
--    (evita duplicar ítems al cambiar de servidor rápido).
--  * Reintentos con backoff exponencial, autoguardado, PlayerRemoving y BindToClose.
-- En Studio: Game Settings > Security > "Enable Studio Access to API Services".
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Retry = require(script.Parent.Parent.Util.Retry)

type PlayerData = Types.PlayerData

local STORE_NAME = "PlayerData_v1" -- cambiar el nombre = empezar de cero (no lo toques en producción)
local LOCK_TTL = 300 -- s: un bloqueo más viejo que esto se considera de un servidor caído
local AUTOSAVE_INTERVAL = 120
local MAX_RECEIPTS = 50
local LOAD_ATTEMPTS = 6
local LOAD_WAIT = 5

-- Lo único que usamos del DataStore. Permite un sustituto en memoria para pruebas locales.
type StoreLike = {
	UpdateAsync: (self: any, key: string, transform: (any) -> any) -> any,
}

-- Copia local sin publicar (game.GameId == 0): los DataStores no existen ahí.
-- Usamos memoria para poder probar ramas sin tocar datos reales. Nada se guarda al cerrar.
local function memoryStore(): StoreLike
	local memory: { [string]: any } = {}
	return {
		UpdateAsync = function(_self: any, key: string, transform: (any) -> any): any
			local new = transform(memory[key])
			if new ~= nil then
				memory[key] = new
			end
			return new
		end,
	}
end

local store: StoreLike
if game.GameId == 0 then
	warn("[DataService] Place sin publicar: datos EN MEMORIA (no se guardan). Solo para pruebas.")
	store = memoryStore()
else
	store = DataStoreService:GetDataStore(STORE_NAME) :: any
end
local profiles: { [Player]: PlayerData } = {}
local saving: { [Player]: boolean } = {}
local loadedEvent = Instance.new("BindableEvent")

local DataService = {}
DataService.Loaded = loadedEvent.Event -- (player: Player, data: PlayerData)

local function defaultData(): PlayerData
	return {
		version = 1,
		cash = 0,
		power = 0,
		trainingLevel = 0,
		capsuleLevel = 0,
		bestZone = 1,
		garden = {},
		index = {},
		totalThrows = 0,
		cellsRestored = 0,
		paidEggPity = 0,
		freeEggs = 0,
		dailyStreak = 0,
		lastDailyDay = 0,
		turboUnlocked = false,
		starterPackOwned = false,
		lastOnline = os.time(),
		receipts = {},
		tutorialStep = 1,
		questDay = 0,
		questBase = { throws = 0, upgrades = 0, cells = 0 },
		questClaimed = { false, false, false },
	}
end

-- Rellena campos nuevos sin borrar los existentes (migración simple).
local function reconcile(raw: any): PlayerData
	local base = defaultData()
	if type(raw) ~= "table" then
		return base
	end
	for key, value in pairs(base :: any) do
		if raw[key] == nil then
			raw[key] = value
		end
	end
	return raw :: PlayerData
end

local function keyFor(userId: number): string
	return "u_" .. tostring(userId)
end

local function lockIsForeign(old: any, now: number): boolean
	if type(old) ~= "table" or type(old.lock) ~= "table" then
		return false
	end
	local sameServer = old.lock.jobId == game.JobId
	local fresh = now - (tonumber(old.lock.time) or 0) < LOCK_TTL
	return (not sameServer) and fresh
end

-- Intenta abrir la sesión. Devuelve (true, datos) o (false, nil) si otro servidor la tiene.
local function tryAcquire(userId: number): (boolean, PlayerData?)
	local acquired = false
	local loaded: PlayerData? = nil
	local ok = Retry.withBackoff("load " .. userId, 5, function()
		store:UpdateAsync(keyFor(userId), function(old: any): any
			local now = os.time()
			if lockIsForeign(old, now) then
				acquired = false
				return nil -- devolver nil cancela la escritura
			end
			local data = reconcile(if type(old) == "table" then old.data else nil)
			acquired = true
			loaded = data
			return { data = data, lock = { jobId = game.JobId, time = now } }
		end)
		return true
	end)
	return ok and acquired, loaded
end

local function saveAsync(player: Player, release: boolean): boolean
	local data = profiles[player]
	if not data then
		return true
	end
	-- Evita dos guardados simultáneos del mismo jugador.
	local waited = 0
	while saving[player] and waited < 15 do
		task.wait(0.5)
		waited += 0.5
	end
	saving[player] = true
	data.lastOnline = os.time()

	local lostLock = false
	local ok = Retry.withBackoff("save " .. player.UserId, 4, function()
		store:UpdateAsync(keyFor(player.UserId), function(old: any): any
			local now = os.time()
			if lockIsForeign(old, now) then
				lostLock = true
				return nil -- otra sesión tomó el registro: NO sobrescribimos
			end
			return {
				data = data,
				lock = if release then nil else { jobId = game.JobId, time = now },
			}
		end)
		return true
	end)
	saving[player] = nil
	if lostLock then
		warn("[DataService] Bloqueo perdido para", player.UserId, "- no se guardó para evitar duplicados")
		return false
	end
	return ok
end

local function onPlayerAdded(player: Player)
	for _ = 1, LOAD_ATTEMPTS do
		local ok, data = tryAcquire(player.UserId)
		if player.Parent == nil then
			-- Se fue mientras cargábamos: si llegamos a bloquear, liberamos.
			if ok and data then
				profiles[player] = data
				saveAsync(player, true)
				profiles[player] = nil
			end
			return
		end
		if ok and data then
			profiles[player] = data
			loadedEvent:Fire(player, data)
			return
		end
		task.wait(LOAD_WAIT) -- probablemente su servidor anterior aún está guardando
	end
	player:Kick("No pudimos cargar tus datos de forma segura. Vuelve a entrar en 1 minuto; tu progreso está a salvo.")
end

local function onPlayerRemoving(player: Player)
	saveAsync(player, true)
	profiles[player] = nil
end

function DataService.get(player: Player): PlayerData?
	return profiles[player]
end

function DataService.all(): { [Player]: PlayerData }
	return profiles
end

-- Guardado inmediato (lo usa ProcessReceipt antes de confirmar una compra).
function DataService.saveNow(player: Player): boolean
	return saveAsync(player, false)
end

function DataService.hasReceipt(data: PlayerData, purchaseId: string): boolean
	return table.find(data.receipts, purchaseId) ~= nil
end

function DataService.addReceipt(data: PlayerData, purchaseId: string)
	table.insert(data.receipts, purchaseId)
	while #data.receipts > MAX_RECEIPTS do
		table.remove(data.receipts, 1)
	end
end

function DataService.init()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for player in profiles do
				task.spawn(saveAsync, player, false)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player in profiles do
			pending += 1
			task.spawn(function()
				saveAsync(player, true)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25 -- Roblox da ~30 s al cerrar
		while pending > 0 and os.clock() < deadline do
			task.wait(0.25)
		end
	end)
end

return DataService
