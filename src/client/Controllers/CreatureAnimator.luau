--!strict
-- Animación suave de las criaturas del jardín, hecha SOLO en el cliente: balanceo y "respiración"
-- con PivotTo sobre los modelos etiquetados "Creature" (anclados en el servidor), y ciclo de
-- tono para la mutación Arcoíris. Se limita a las criaturas cercanas a la cámara y a ~30 Hz.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local MAX_DISTANCE = 160 -- más lejos no se anima (rendimiento)
local STEP = 1 / 30

local CreatureAnimator = {}

type Tracked = { base: CFrame, phase: number, rainbow: boolean }
local tracked: { [Model]: Tracked } = {}
local accumulator = 0

local function track(inst: Instance)
	if not inst:IsA("Model") then
		return
	end
	tracked[inst] = {
		base = inst:GetPivot(),
		-- Fase distinta por criatura para que no se muevan todas a la vez.
		phase = (inst.Name:len() * 1.7 + inst:GetPivot().Position.X * 0.37) % (math.pi * 2),
		rainbow = inst:GetAttribute("Rainbow") == true,
	}
end

local function untrack(inst: Instance)
	if inst:IsA("Model") then
		tracked[inst] = nil
	end
end

function CreatureAnimator.init()
	CollectionService:GetInstanceAddedSignal("Creature"):Connect(track)
	CollectionService:GetInstanceRemovedSignal("Creature"):Connect(untrack)
	for _, inst in CollectionService:GetTagged("Creature") do
		track(inst)
	end

	RunService.RenderStepped:Connect(function(dt: number)
		accumulator += dt
		if accumulator < STEP then
			return
		end
		accumulator = 0
		local camera = Workspace.CurrentCamera
		if camera == nil then
			return
		end
		local camPos = camera.CFrame.Position
		local now = os.clock()
		for model, info in tracked do
			if model.Parent == nil then
				tracked[model] = nil
				continue
			end
			if (info.base.Position - camPos).Magnitude > MAX_DISTANCE then
				continue
			end
			local t = now * 2 + info.phase
			local bob = math.sin(t) * 0.25
			local rock = math.sin(t * 0.5) * 0.08
			model:PivotTo(info.base * CFrame.new(0, bob, 0) * CFrame.Angles(0, rock, rock * 0.6))
			if info.rainbow then
				local color = Color3.fromHSV((now * 0.25 + info.phase) % 1, 0.8, 1)
				local body = model:FindFirstChild("Cuerpo")
				if body and body:IsA("BasePart") then
					body.Color = color
				end
			end
		end
	end)
end

return CreatureAnimator
