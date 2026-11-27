--!strict
-- Efectos visuales del mundo: partículas al aterrizar la cápsula y celebración al 100 %.
-- Solo cosmético y en el cliente. Usa un pool de partes con emisor para no crear basura.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Net = require(ReplicatedStorage.Shared.Net)
local Rarities = require(ReplicatedStorage.Shared.Config.Rarities)
local UIPool = require(script.Parent.Parent.UI.UIPool)

local player = Players.LocalPlayer
local FLIGHT_TIME = 1.1 -- igual que ThrowController: el efecto aparece al llegar la cápsula
local MAX_ACTIVE = 12 -- tope de emisores simultáneos (rendimiento en móvil)

local EffectsController = {}

local pool: UIPool.Pool<Part>
local active = 0

local function makeEmitter(): Part
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(1, 1, 1)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Enabled = false
	emitter.Lifetime = NumberRange.new(0.6, 1.2)
	emitter.Speed = NumberRange.new(12, 26)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.2),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.LightEmission = 1
	emitter.Acceleration = Vector3.new(0, -20, 0)
	emitter.Parent = anchor
	return anchor
end

-- Lanza una ráfaga de partículas del color dado y devuelve el emisor al pool al terminar.
local function burst(position: Vector3, color: Color3, count: number, upward: boolean)
	if active >= MAX_ACTIVE then
		return
	end
	active += 1
	local anchor = pool.acquire()
	anchor.Position = position
	anchor.Parent = Workspace
	local emitter = anchor:FindFirstChildOfClass("ParticleEmitter")
	if emitter then
		emitter.Color = ColorSequence.new(color, color:Lerp(Color3.new(1, 1, 1), 0.5))
		emitter.SpreadAngle = if upward then Vector2.new(35, 35) else Vector2.new(180, 180)
		emitter.Rotation = NumberRange.new(0, 360)
		emitter:Emit(count)
	end
	task.delay(1.6, function()
		pool.release(anchor)
		active -= 1
	end)
end

local function celebrate()
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not (root and root:IsA("BasePart")) then
		return
	end
	local center = root.Position + Vector3.new(0, 25, 0)
	local colors = {
		Color3.fromRGB(120, 255, 140),
		Color3.fromRGB(255, 220, 110),
		Color3.fromRGB(255, 150, 220),
		Color3.fromRGB(130, 200, 255),
	}
	for i = 1, 8 do
		task.delay((i - 1) * 0.35, function()
			local angle = i * 0.9
			local offset = Vector3.new(math.cos(angle) * 30, (i % 3) * 8, math.sin(angle) * 30)
			burst(center + offset, colors[(i - 1) % #colors + 1], 60, false)
		end)
	end
end

function EffectsController.init()
	pool = UIPool.new(makeEmitter, function(anchor: Part)
		anchor.Parent = nil
	end, 4)

	Net.event("ThrowResult").OnClientEvent:Connect(function(result: any)
		if type(result) ~= "table" or typeof(result.landing) ~= "Vector3" then
			return
		end
		local rarity = Rarities.DEFS[result.rarity]
		local color = if rarity then rarity.color else Color3.new(1, 1, 1)
		local count = if rarity and rarity.cellsPerThrow >= 24 then 50 else 18 -- épico/legendario lucen más
		local position: Vector3 = result.landing
		task.delay(FLIGHT_TIME, function()
			burst(position + Vector3.new(0, 1, 0), color, count, true)
		end)
	end)

	Net.event("Notify").OnClientEvent:Connect(function(kind: any)
		if kind == "PlanetRestored" then
			celebrate()
		end
	end)
end

return EffectsController
