--!strict
-- Reproduce los sonidos cortos y bucles de Config/Sfx. Solo cliente, cosmético: ninguna
-- decisión de juego depende de esto.
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SfxConfig = require(ReplicatedStorage.Shared.Config.Sfx)

local Sfx = {}

local function newSound(key: string): Sound?
	local def = SfxConfig.DEFS[key]
	if def == nil then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.SoundId = def.id
	sound.Volume = def.volume
	sound.PlaybackSpeed = def.pitch
	sound.Parent = SoundService
	return sound
end

-- Sonido de un solo disparo; se destruye solo cuando termina.
function Sfx.play(key: string)
	local sound = newSound(key)
	if sound == nil then
		return
	end
	sound:Play()
	Debris:AddItem(sound, 5)
end

-- Bucle (p. ej. la carga del medidor). Detener con Sfx.stopLoop.
function Sfx.startLoop(key: string): Sound?
	local sound = newSound(key)
	if sound == nil then
		return nil
	end
	sound.Looped = true
	sound:Play()
	return sound
end

function Sfx.stopLoop(sound: Sound?)
	if sound == nil then
		return
	end
	sound:Stop()
	sound:Destroy()
end

return Sfx
