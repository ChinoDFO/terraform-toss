--!strict
-- Punto de entrada del cliente. Espera a que el juego cargue para que ReplicatedStorage esté completo.
if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Controllers = script.Parent.Controllers
local HudController = require(Controllers.HudController)
local ThrowController = require(Controllers.ThrowController)
local ShopController = require(Controllers.ShopController)

HudController.init()
ThrowController.init()
ShopController.init()
