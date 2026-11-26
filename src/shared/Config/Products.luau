--!strict
-- Catálogo de monetización. Los IDs se rellenan DESPUÉS de crear cada pase/producto
-- en Creator Hub (Monetization > Passes / Developer Products). id = 0 = desactivado.
-- NUNCA escribas precios aquí: el precio se lee en vivo con GetProductInfoAsync
-- (precios regionales + descuento de Roblox Plus).

export type ProductDef = {
	key: string,
	id: number,
	isPass: boolean,
	isRandom: boolean, -- true = artículo aleatorio pagado (requiere PolicyService + probabilidades)
	title: string,
	description: string,
}

local LIST: { ProductDef } = {
	-- Pases (permanentes)
	{
		key = "TurboArranque",
		id = 0,
		isPass = true,
		isRandom = false,
		title = "Turbo de Arranque",
		description = "x2 velocidad de entrenamiento, para siempre. También se desbloquea gratis con una racha de 3 días.",
	},
	{
		key = "DobleDinero",
		id = 0,
		isPass = true,
		isRandom = false,
		title = "Doble Dinero",
		description = "x2 a todo el dinero que generan tus criaturas.",
	},
	{
		key = "AutoLanzar",
		id = 0,
		isPass = true,
		isRandom = false,
		title = "Auto-Lanzamiento",
		description = "Lanza automáticamente con medidor estándar (x1,5) mientras juegas.",
	},
	{
		key = "HuecosExtra",
		id = 0,
		isPass = true,
		isRandom = false,
		title = "+4 Huecos de Jardín",
		description = "Tu jardín pasa de 8 a 12 criaturas.",
	},
	{
		key = "CatapultaDorada",
		id = 0,
		isPass = true,
		isRandom = false,
		title = "Catapulta Dorada",
		description = "Cosmético: catapulta y estela doradas. No da ventaja.",
	},

	-- Productos de desarrollador (consumibles)
	{
		key = "PackArranque",
		id = 0,
		isPass = false,
		isRandom = false,
		title = "Pack de Arranque",
		description = "Contenido FIJO: 3 niveles de entrenamiento + 1 Huevo Estelar gratuito + skin de cápsula. Una sola vez.",
	},
	{
		key = "HuevoEstelar",
		id = 0,
		isPass = false,
		isRandom = true,
		title = "Huevo Estelar",
		description = "Una criatura Rara o mejor de tu mejor zona. Ver probabilidades antes de comprar.",
	},
	{
		key = "Boost30",
		id = 0,
		isPass = false,
		isRandom = false,
		title = "x2 Dinero 30 min",
		description = "Duplica tu dinero durante 30 minutos de juego.",
	},
}

local BY_KEY: { [string]: ProductDef } = {}
local BY_ID: { [number]: ProductDef } = {}
for _, def in LIST do
	BY_KEY[def.key] = def
	if def.id ~= 0 then
		BY_ID[def.id] = def
	end
end

return {
	LIST = LIST,
	BY_KEY = BY_KEY,
	BY_ID = BY_ID,
	CONFIRM_THRESHOLD_ROBUX = 400, -- compras >= esto piden confirmación en dos pasos
}
