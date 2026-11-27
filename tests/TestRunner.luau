--!strict
-- Pruebas de las reglas críticas (probabilidades, medidor, formato, balance).
-- Ejecútalas desde Claude con la herramienta MCP `execute_luau` (modo Edit):
--   return require(game:GetService("ServerStorage").Tests.TestRunner).run()
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Odds = require(ReplicatedStorage.Shared.Util.Odds)
local Meter = require(ReplicatedStorage.Shared.Util.Meter)
local NumberFormat = require(ReplicatedStorage.Shared.Util.NumberFormat)
local WeightedRandom = require(ReplicatedStorage.Shared.Util.WeightedRandom)
local Rarities = require(ReplicatedStorage.Shared.Config.Rarities)
local Mutations = require(ReplicatedStorage.Shared.Config.Mutations)
local Creatures = require(ReplicatedStorage.Shared.Config.Creatures)
local Zones = require(ReplicatedStorage.Shared.Config.Zones)
local Ambience = require(ReplicatedStorage.Shared.Config.Ambience)

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
	assert(Zones.forDistance(0) == 1)
	assert(Zones.forDistance(199) == 1)
	assert(Zones.forDistance(200) == 2)
	assert(Zones.forDistance(1e12) == Zones.COUNT)
end)

test("Ambiente: 0 % gris apagado, 100 % cálido y brillante, sin NaN", function()
	local dead = Ambience.at(0)
	local alive = Ambience.at(100)
	assert(dead.saturation < alive.saturation and dead.brightness < alive.brightness)
	assert(Ambience.at(-50).brightness == dead.brightness, "valores bajo 0 se acotan")
	assert(Ambience.at(1e9).brightness == alive.brightness, "valores sobre 100 se acotan")
	assert(Ambience.at(0 / 0).brightness == dead.brightness, "NaN se trata como 0")
	local mid = Ambience.at(50).brightness
	assert(mid > dead.brightness and mid < alive.brightness)
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
