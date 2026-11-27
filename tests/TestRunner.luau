--!strict
-- Pruebas de las reglas críticas (probabilidades, medidor, formato, balance).
-- Ejecútalas desde Claude con la herramienta MCP `execute_luau` (modo Edit):
--   return require(game:GetService("ServerStorage").Tests.TestRunner).run()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Odds = require(ReplicatedStorage.Shared.Util.Odds)
local Meter = require(ReplicatedStorage.Shared.Util.Meter)
local NumberFormat = require(ReplicatedStorage.Shared.Util.NumberFormat)
local WeightedRandom = require(ReplicatedStorage.Shared.Util.WeightedRandom)
local Formulas = require(ReplicatedStorage.Shared.Util.Formulas)
local Rarities = require(ReplicatedStorage.Shared.Config.Rarities)
local Mutations = require(ReplicatedStorage.Shared.Config.Mutations)
local Creatures = require(ReplicatedStorage.Shared.Config.Creatures)
local Zones = require(ReplicatedStorage.Shared.Config.Zones)
local Validate = require(ServerScriptService.Server.Util.Validate)
local RateLimiter = require(ServerScriptService.Server.Util.RateLimiter)
local CreatureService = require(ServerScriptService.Server.Services.CreatureService)

local TestRunner = {}

type Case = { name: string, fn: () -> () }
local cases: { Case } = {}

local function test(name: string, fn: () -> ())
	table.insert(cases, { name = name, fn = fn })
end

local function near(a: number, b: number, eps: number?): boolean
	return math.abs(a - b) <= (eps or 1e-6)
end

test("Las rarezas base suman 100 %", function()
	local sum = 0
	for _, id in Rarities.ORDER do
		sum += Rarities.DEFS[id].baseWeight
	end
	assert(near(sum, 100), "suma = " .. sum)
end)

test("Odds.forLuck suma 100 % para toda suerte posible", function()
	for luck = 1, 6, 0.25 do
		local total = Odds.total(Odds.forLuck(luck))
		assert(near(total, 100, 1e-6), string.format("suerte %.2f -> %.6f", luck, total))
	end
end)

test("Más suerte nunca baja la probabilidad de Legendario", function()
	local prev = -1
	for luck = 1, 5, 0.5 do
		local p = Odds.forLuck(luck).Legendario
		assert(p >= prev, "bajó con suerte " .. luck)
		prev = p
	end
end)

test("Huevo Estelar: suma 100 %, mínimo Raro, pity a Legendario", function()
	assert(near(Odds.total(Odds.forEgg(0)), 100), "huevo no suma 100")
	assert((Odds.forEgg(0).Comun or 0) == 0, "el huevo no puede dar Común")
	assert(near(Odds.forEgg(Rarities.EGG_PITY_THRESHOLD - 1).Legendario, 100), "pity no garantiza Legendario")
end)

test("Mutaciones suman 100 %", function()
	local sum = 0
	for _, id in Mutations.ORDER do
		sum += Mutations.DEFS[id].weight
	end
	assert(near(sum, 100), "suma = " .. sum)
end)

test("WeightedRandom respeta los pesos (10.000 tiradas, ±1,5 %)", function()
	local rng = Random.new(42)
	local counts: { [string]: number } = {}
	local odds = Odds.forLuck(1)
	local n = 10000
	for _ = 1, n do
		local id = WeightedRandom.pick(odds, Rarities.ORDER, rng)
		counts[id] = (counts[id] or 0) + 1
	end
	local common = (counts.Comun or 0) / n * 100
	assert(math.abs(common - odds.Comun) < 1.5, "Común observado " .. common)
end)

test("Medidor: valores en [0,1] y multiplicador correcto", function()
	for t = 0, 10, 0.05 do
		local v = Meter.valueAt(t)
		assert(v >= 0 and v <= 1, "fuera de rango en t=" .. t)
	end
	assert(Meter.multiplierAt(Meter.PERIOD / 2) == 2, "el pico debe dar x2")
	assert(Meter.multiplierAt(0) == 1, "soltar al instante da x1")
	assert(Meter.multiplierAt(Meter.MAX_HOLD + 1) == 1, "mantener demasiado da x1")
	assert(Meter.valueAt(0 / 0) == 0, "NaN debe dar 0")
end)

test("NumberFormat", function()
	assert(NumberFormat.short(999) == "999", NumberFormat.short(999))
	assert(NumberFormat.short(1234) == "1.23K", NumberFormat.short(1234))
	assert(NumberFormat.short(999999) == "1.00M", NumberFormat.short(999999))
	assert(NumberFormat.short(5.6e15) == "5.60Qa", NumberFormat.short(5.6e15))
end)

test("30 criaturas, todas con zona y rareza válidas", function()
	assert(Creatures.COUNT == 30, "hay " .. Creatures.COUNT)
	for _, c in Creatures.LIST do
		assert(Zones.ZONES[c.zone] ~= nil, "zona inválida " .. c.id)
		assert(Rarities.DEFS[c.rarity] ~= nil, "rareza inválida " .. c.id)
	end
end)

test("Zonas ordenadas por distancia", function()
	assert(Zones.forDistance(0) == 1, "distancia 0 debe ser zona 1")
	assert(Zones.forDistance(199) == 1, "justo antes del umbral sigue siendo zona 1")
	assert(Zones.forDistance(200) == 2, "en el umbral ya es zona 2")
	assert(Zones.forDistance(1e12) == Zones.COUNT, "una distancia enorme debe dar la última zona")
end)

test("Formulas: costes base y monotonía de nivel", function()
	assert(Formulas.trainingCost(0) == 30, "coste entreno nivel 0 = " .. Formulas.trainingCost(0))
	assert(Formulas.capsuleCost(0) == 300, "coste cápsula nivel 0 = " .. Formulas.capsuleCost(0))
	assert(Formulas.trainingCost(1) > Formulas.trainingCost(0), "el coste debe subir con el nivel")
	assert(Formulas.capsuleCost(1) > Formulas.capsuleCost(0), "el coste debe subir con el nivel")
	assert(Formulas.trainingRate(0, true) == Formulas.trainingRate(0, false) * 2, "turbo debe duplicar")
	assert(
		Formulas.gardenCapacity(true, true)
			== Formulas.BASE_GARDEN_SLOTS + Formulas.EXTRA_SLOTS_PASS + Formulas.PLUS_EXTRA_SLOTS,
		"capacidad con pase + Plus"
	)
end)

test("Formulas.luck respeta el tope de diseño (Rarities.MAX_LUCK)", function()
	assert(Formulas.luck(0, false, false) == 1, "base sin bonos debe ser 1")
	assert(near(Formulas.luck(30, true, true), 2.35), "con el roster actual no debería acercarse al tope")
	assert(Formulas.luck(1000, true, true) == Rarities.MAX_LUCK, "debe recortar a " .. Rarities.MAX_LUCK)
end)

test("Validate.number rechaza NaN/infinito/fuera de rango/tipo erróneo", function()
	assert(Validate.number(0 / 0, 0, 100) == nil, "NaN debe rechazarse")
	assert(Validate.number(math.huge, 0, 100) == nil, "infinito debe rechazarse")
	assert(Validate.number(-math.huge, 0, 100) == nil, "-infinito debe rechazarse")
	assert(Validate.number(999, 0, 100) == nil, "fuera de rango debe rechazarse")
	assert(Validate.number("5", 0, 100) == nil, "un string nunca es un number válido")
	assert(Validate.number(42, 0, 100) == 42, "un valor válido debe pasar")
end)

test("Validate.oneOf rechaza fuera de lista blanca/tipo erróneo/demasiado largo", function()
	local whitelist = { training = true, capsule = true }
	assert(Validate.oneOf("hack", whitelist) == nil, "fuera de la lista blanca debe rechazarse")
	assert(Validate.oneOf(123, whitelist) == nil, "un número nunca es un oneOf válido")
	assert(Validate.oneOf(string.rep("a", 41), whitelist) == nil, "más de 40 caracteres debe rechazarse")
	assert(Validate.oneOf("", whitelist) == nil, "string vacío debe rechazarse")
	assert(Validate.oneOf("training", whitelist) == "training", "un valor de la lista debe pasar")
end)

test("CreatureService.discoveredMask: un bit por criatura, sin cruzarse", function()
	local index = {}
	index[Creatures.LIST[1].id] = true
	index[Creatures.LIST[15].id] = true
	index[Creatures.LIST[Creatures.COUNT].id] = true
	local data = { index = index } :: any
	local mask = CreatureService.discoveredMask(data)
	assert(CreatureService.discoveredCount(data) == 3, "deberían ser 3 descubiertas")
	assert(bit32.band(mask, bit32.lshift(1, 0)) ~= 0, "la 1ª debe estar marcada")
	assert(bit32.band(mask, bit32.lshift(1, 14)) ~= 0, "la 15ª debe estar marcada")
	assert(bit32.band(mask, bit32.lshift(1, Creatures.COUNT - 1)) ~= 0, "la última debe estar marcada")
	assert(bit32.band(mask, bit32.lshift(1, 1)) == 0, "la 2ª NO debe estar marcada")
	assert(bit32.band(mask, bit32.lshift(1, Creatures.COUNT - 2)) == 0, "la penúltima NO debe estar marcada")
end)

test("RateLimiter permite N por ventana y bloquea el resto", function()
	local allow = RateLimiter.new(3, 1)
	local key = {} -- RateLimiter solo usa la clave para indexar la tabla, sirve cualquier valor no nulo
	local allowed = 0
	for _ = 1, 5 do
		if allow(key) then
			allowed += 1
		end
	end
	assert(allowed == 3, "debería permitir exactamente 3 de 5, permitió " .. allowed)
end)

test("Terraform: getOrigin devuelve un Vector3 (los servicios no fijan 0,0,120 a mano)", function()
	local TerraformService = require(ServerScriptService.Server.Services.TerraformService)
	assert(typeof(TerraformService.getOrigin()) == "Vector3")
end)

test("Escenografía: respeta el tope por franja y la probabilidad", function()
	local SceneryService = require(ServerScriptService.Server.Services.SceneryService)
	local Scenery = require(ReplicatedStorage.Shared.Config.Scenery)
	assert(SceneryService.shouldSpawn(0, 0), "con cupo y tirada baja nace")
	assert(not SceneryService.shouldSpawn(0, 0.99), "tirada alta no nace")
	assert(not SceneryService.shouldSpawn(Scenery.MAX_PER_BAND, 0), "sin cupo nunca nace")
	assert(#Scenery.KIND_BY_ZONE == Zones.COUNT, "un tipo de prop por zona")
end)

test("Plataforma: el spawn queda sobre la base y mira al planeta", function()
	local LaunchPlatformService = require(ServerScriptService.Server.Services.LaunchPlatformService)
	local origin = Vector3.new(10, 5, 200)
	local cf = LaunchPlatformService.spawnCFrame(origin)
	assert(near(cf.Position.X, origin.X), "centrado en X respecto al origen")
	assert(cf.Position.Z < origin.Z, "detrás de la primera fila del planeta")
	assert(cf.Position.Y > origin.Y, "encima de la base")
	assert(cf.LookVector:Dot(Vector3.new(0, 0, 1)) > 0.99, "mira hacia el planeta (+Z)")
	local moved = LaunchPlatformService.spawnCFrame(origin + Vector3.new(0, 0, 50))
	assert(near(moved.Position.Z - cf.Position.Z, 50), "sigue al origen del planeta")
end)

function TestRunner.run(): string
	local passed, failed = 0, 0
	local lines: { string } = {}
	for _, case in cases do
		local ok, err = pcall(case.fn)
		if ok then
			passed += 1
			table.insert(lines, "  ✔ " .. case.name)
		else
			failed += 1
			table.insert(lines, "  ✘ " .. case.name .. " -> " .. tostring(err))
		end
	end
	table.insert(lines, string.format("Resultado: %d OK, %d fallos", passed, failed))
	local report = table.concat(lines, "\n")
	print(report)
	return report
end

return TestRunner
