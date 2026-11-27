--!strict
-- Ambiente visual: Lighting, Atmosphere, Sky, Bloom y ColorCorrection pasan de gris/apagado a
-- cálido/verde según Workspace.ServerState.PlanetPercent. Solo cosmético y en el cliente:
-- no decide nada de juego ni envía nada al servidor.
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Net = require(game:GetService("ReplicatedStorage").Shared.Net)
local Ambience = require(game:GetService("ReplicatedStorage").Shared.Config.Ambience)

local AmbienceController = {}

local atmosphere: Atmosphere
local bloom: BloomEffect
local color: ColorCorrectionEffect
local sky: Sky
local tweens: { Tween } = {}

local function getOrCreate<T>(className: string, name: string): T
	local existing = Lighting:FindFirstChild(name)
	if existing and existing.ClassName == className then
		return existing :: any
	end
	local inst = Instance.new(className)
	inst.Name = name
	inst.Parent = Lighting
	return inst :: any
end

local function apply(percent: number, instant: boolean)
	local look = Ambience.at(percent)
	local info =
		TweenInfo.new(instant and 0 or Ambience.TWEEN_SECONDS, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	for _, tween in tweens do
		tween:Cancel()
	end
	table.clear(tweens)

	local function go(target: Instance, props: { [string]: any })
		local tween = TweenService:Create(target, info, props)
		table.insert(tweens, tween)
		tween:Play()
	end

	go(Lighting, {
		Ambient = look.ambient,
		OutdoorAmbient = look.outdoorAmbient,
		Brightness = look.brightness,
		ClockTime = look.clockTime,
	})
	go(atmosphere, { Color = look.fogColor, Density = look.atmosphereDensity, Haze = look.atmosphereHaze })
	go(bloom, { Intensity = look.bloomIntensity })
	go(color, { Saturation = look.saturation, TintColor = look.tint, Contrast = look.contrast })
	sky.StarCount = math.floor(3000 * (1 - percent / 100)) -- planeta muerto: cielo cargado de estrellas
	Lighting.ColorShift_Top = look.skyTint
end

function AmbienceController.init()
	atmosphere = getOrCreate("Atmosphere", "TerraformAtmosphere")
	bloom = getOrCreate("BloomEffect", "TerraformBloom")
	color = getOrCreate("ColorCorrectionEffect", "TerraformColor")
	sky = getOrCreate("Sky", "TerraformSky")
	bloom.Size = 24
	bloom.Threshold = 1.5

	local state = Net.serverState()
	local function read(): number
		return tonumber(state:GetAttribute("PlanetPercent")) or 0
	end
	apply(read(), true)
	state:GetAttributeChangedSignal("PlanetPercent"):Connect(function()
		apply(read(), false)
	end)
end

return AmbienceController
