--!strict
-- Punto de entrada del servidor. El orden importa: datos y políticas primero.
local Services = script.Parent.Services

local DataService = require(Services.DataService)
local PolicyGate = require(Services.PolicyGate)
local TerraformService = require(Services.TerraformService)
local PurchaseService = require(Services.PurchaseService)
local EconomyService = require(Services.EconomyService)
local ThrowService = require(Services.ThrowService)
local DailyService = require(Services.DailyService)
local PlusService = require(Services.PlusService)
local GardenVisualService = require(Services.GardenVisualService)

TerraformService.init()
PolicyGate.init()
PurchaseService.init() -- antes de DataService para escuchar Loaded a tiempo
EconomyService.init()
DailyService.init()
ThrowService.init()
PlusService.init()
GardenVisualService.init()
DataService.init() -- al final: empieza a cargar jugadores cuando todos escuchan Loaded

print("[Terraform Toss] Servidor listo")
