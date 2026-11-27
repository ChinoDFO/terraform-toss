--!strict
-- Criaturas procedurales: cuerpo + ojos + rasgos según rareza, con brillo/partículas por rareza
-- y aspecto por mutación. Sin modelos externos. `describe` es puro (se prueba); `build` crea el
-- Model (anclado, sin colisión) y lo etiqueta "Creature" para que el cliente lo anime.
local Creatures = require(script.Parent.Parent.Config.Creatures)
local Rarities = require(script.Parent.Parent.Config.Rarities)
local Zones = require(script.Parent.Parent.Config.Zones)

export type Look = {
	bodySize: number,
	scale: number,
	color: Color3,
	material: Enum.Material,
	transparency: number,
	traits: { string },
	glow: boolean, -- luz + partículas
	rainbow: boolean, -- el cliente rota el tono
}

-- Rasgos acumulativos por rareza: cada nivel añade uno.
local TRAITS_BY_RARITY: { [string]: { string } } = {
	Comun = {},
	PocoComun = { "ears" },
	Raro = { "ears", "horns" },
	Epico = { "ears", "horns", "wings" },
	Legendario = { "ears", "horns", "wings", "halo" },
}

local BODY_SIZE: { [string]: number } = {
	Comun = 2.2,
	PocoComun = 2.5,
	Raro = 2.8,
	Epico = 3.1,
	Legendario = 3.4,
}

local MUTATION_SCALE: { [string]: number } = { Gigante = 1.35 }

local CreatureBuilder = {}

function CreatureBuilder.describe(creatureId: string, mutation: string): Look?
	local creature = Creatures.BY_ID[creatureId]
	if creature == nil then
		return nil
	end
	local rarity = Rarities.DEFS[creature.rarity]
	local zone = Zones.ZONES[creature.zone]
	if rarity == nil or zone == nil then
		return nil
	end
	-- Color base: color de la zona mezclado con el de la rareza (reconocible a simple vista).
	local color = zone.color:Lerp(rarity.color, 0.35)
	local material = Enum.Material.SmoothPlastic
	local transparency = 0
	local glow = creature.rarity == "Epico" or creature.rarity == "Legendario"
	local rainbow = false
	if mutation == "Neon" then
		material = Enum.Material.Neon
	elseif mutation == "Dorado" then
		color = Color3.fromRGB(255, 205, 70)
		material = Enum.Material.Metal
	elseif mutation == "Cristal" then
		material = Enum.Material.Glass
		transparency = 0.35
	elseif mutation == "Bioluminiscente" then
		color = Color3.fromRGB(90, 255, 220)
		material = Enum.Material.Neon
		glow = true
	elseif mutation == "Arcoiris" then
		material = Enum.Material.Neon
		glow = true
		rainbow = true
	end
	return {
		bodySize = BODY_SIZE[creature.rarity] or 2.2,
		scale = MUTATION_SCALE[mutation] or 1,
		color = color,
		material = material,
		transparency = transparency,
		traits = TRAITS_BY_RARITY[creature.rarity] or {},
		glow = glow,
		rainbow = rainbow,
	}
end

local function newPart(
	model: Model,
	shape: Enum.PartType,
	size: Vector3,
	cframe: CFrame,
	look: Look?,
	color: Color3?
): Part
	local p = Instance.new("Part")
	p.Shape = shape
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.CFrame = cframe
	if look then
		p.Color = look.color
		p.Material = look.material
		p.Transparency = look.transparency
	else
		p.Color = color or Color3.new(1, 1, 1)
		p.Material = Enum.Material.SmoothPlastic
	end
	p.Parent = model
	return p
end

-- Crea el Model en `position` (apoyado en el suelo). El llamador lo parenta donde quiera.
function CreatureBuilder.build(creatureId: string, mutation: string, position: Vector3): Model?
	local look = CreatureBuilder.describe(creatureId, mutation)
	if look == nil then
		return nil
	end
	local s = look.bodySize * look.scale
	local model = Instance.new("Model")
	model.Name = creatureId
	local base = CFrame.new(position + Vector3.new(0, s / 2, 0))
	local ball = Enum.PartType.Ball
	local block = Enum.PartType.Block

	local body = newPart(model, ball, Vector3.new(s, s * 0.9, s), base, look, nil)
	body.Name = "Cuerpo"

	-- Ojos (dos esferas blancas con pupila negra, mirando al frente -Z).
	for _, side in { -1, 1 } do
		local eyePos = base * CFrame.new(side * s * 0.22, s * 0.12, -s * 0.42)
		newPart(model, ball, Vector3.new(s * 0.2, s * 0.2, s * 0.2), eyePos, nil, Color3.new(1, 1, 1)).Name = "Ojo"
		local pupil = eyePos * CFrame.new(0, 0, -s * 0.06)
		newPart(model, ball, Vector3.new(s * 0.1, s * 0.1, s * 0.1), pupil, nil, Color3.fromRGB(20, 20, 25)).Name =
			"Pupila"
	end

	for _, trait in look.traits do
		if trait == "ears" then
			for _, side in { -1, 1 } do
				local ear = Vector3.new(s * 0.18, s * 0.3, s * 0.12)
				newPart(
					model,
					block,
					ear,
					base * CFrame.new(side * s * 0.3, s * 0.5, 0) * CFrame.Angles(0, 0, -side * 0.3),
					look,
					nil
				).Name =
					"Oreja"
			end
		elseif trait == "horns" then
			for _, side in { -1, 1 } do
				local horn = Vector3.new(s * 0.1, s * 0.34, s * 0.1)
				local tint = look.color:Lerp(Color3.new(1, 1, 1), 0.6)
				newPart(
					model,
					block,
					horn,
					base * CFrame.new(side * s * 0.14, s * 0.55, -s * 0.05) * CFrame.Angles(0.2, 0, side * 0.25),
					nil,
					tint
				).Name =
					"Cuerno"
			end
		elseif trait == "wings" then
			for _, side in { -1, 1 } do
				local wing = Vector3.new(s * 0.6, s * 0.05, s * 0.4)
				newPart(
					model,
					block,
					wing,
					base * CFrame.new(side * s * 0.55, s * 0.05, s * 0.2) * CFrame.Angles(0, side * 0.5, side * 0.5),
					look,
					nil
				).Name =
					"Ala"
			end
		elseif trait == "halo" then
			local halo = newPart(
				model,
				Enum.PartType.Cylinder,
				Vector3.new(s * 0.06, s * 0.7, s * 0.7),
				base * CFrame.new(0, s * 0.85, 0) * CFrame.Angles(0, 0, math.pi / 2),
				nil,
				Color3.fromRGB(255, 235, 140)
			)
			halo.Material = Enum.Material.Neon
			halo.Name = "Aureola"
		end
	end

	if look.glow then
		local light = Instance.new("PointLight")
		light.Color = look.color
		light.Range = 12
		light.Brightness = 1
		light.Shadows = false
		light.Parent = body
		local sparks = Instance.new("ParticleEmitter")
		sparks.Rate = 3
		sparks.Lifetime = NumberRange.new(1, 1.8)
		sparks.Speed = NumberRange.new(1, 3)
		sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
		sparks.LightEmission = 1
		sparks.Color = ColorSequence.new(look.color)
		sparks.Parent = body
	end

	model.WorldPivot = base
	model:SetAttribute("Rainbow", look.rainbow)
	model:AddTag("Creature")
	return model
end

return CreatureBuilder
