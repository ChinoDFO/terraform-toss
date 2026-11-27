--!strict
-- Botón LANZAR (mantener y soltar) + barra del medidor + vuelo de cápsulas de TODOS los jugadores.
-- PC: barra espaciadora o clic en el botón. Móvil: botón grande abajo a la derecha.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Net = require(ReplicatedStorage.Shared.Net)
local Meter = require(ReplicatedStorage.Shared.Util.Meter)
local Rarities = require(ReplicatedStorage.Shared.Config.Rarities)
local Ui = require(script.Parent.Parent.UI.Ui)
local UIPool = require(script.Parent.Parent.UI.UIPool)
local Sfx = require(script.Parent.Parent.UI.Sfx)
local Vfx = require(script.Parent.Parent.UI.Vfx)

local player = Players.LocalPlayer
local FLIGHT_TIME = 1.1
local ARC_HEIGHT = 60

local ThrowController = {}

local charging = false
local chargeStart = 0
local chargeSound: Sound?
local meterFill: Frame
local meterFrame: Frame
local projectilePool: UIPool.Pool<BasePart>

local function beginCharge()
	if charging then
		return
	end
	charging = true
	chargeStart = os.clock()
	meterFrame.Visible = true
	chargeSound = Sfx.startLoop("Charge")
	Net.event("ThrowStart"):FireServer()
end

local function endCharge()
	if not charging then
		return
	end
	charging = false
	meterFrame.Visible = false
	Sfx.stopLoop(chargeSound)
	chargeSound = nil
	Sfx.play("Release")
	Net.event("ThrowRelease"):FireServer()
end

local function animateProjectile(from: Vector3, to: Vector3, color: Color3)
	local part = projectilePool.acquire()
	part.Color = color
	part.Position = from
	part.Parent = Workspace
	local start = os.clock()
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		local t = math.clamp((os.clock() - start) / FLIGHT_TIME, 0, 1)
		local flat = from:Lerp(to, t)
		part.Position = flat + Vector3.new(0, math.sin(t * math.pi) * ARC_HEIGHT, 0)
		if t >= 1 then
			connection:Disconnect()
			projectilePool.release(part)
			Sfx.play("Land")
			Vfx.burst(to, color)
		end
	end)
end

local function build()
	local gui =
		Ui.make("ScreenGui", { Name = "ThrowUi", ResetOnSpawn = false }, player:WaitForChild("PlayerGui")) :: ScreenGui
	local button = Ui.button(
		gui,
		"Throw",
		UDim2.fromScale(0.8, 0.72),
		UDim2.fromScale(0.18, 0.16),
		"LANZAR",
		Color3.fromRGB(235, 90, 60)
	)

	meterFrame = Ui.make("Frame", {
		Name = "Meter",
		Position = UDim2.fromScale(0.8, 0.66),
		Size = UDim2.fromScale(0.18, 0.04),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		Visible = false,
	}, gui) :: Frame
	-- Zona verde (>= 0,9) dibujada para que el jugador sepa dónde soltar.
	Ui.make("Frame", {
		Position = UDim2.fromScale(0.9, 0),
		Size = UDim2.fromScale(0.1, 1),
		BackgroundColor3 = Color3.fromRGB(60, 200, 90),
		BorderSizePixel = 0,
	}, meterFrame)
	Ui.make("Frame", {
		Position = UDim2.fromScale(0.7, 0),
		Size = UDim2.fromScale(0.2, 1),
		BackgroundColor3 = Color3.fromRGB(220, 200, 60),
		BorderSizePixel = 0,
	}, meterFrame)
	meterFill = Ui.make("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
	}, meterFrame) :: Frame

	button.InputBegan:Connect(function(input: InputObject)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			beginCharge()
		end
	end)
	button.InputEnded:Connect(function(input: InputObject)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			endCharge()
		end
	end)
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if not processed and input.KeyCode == Enum.KeyCode.Space then
			beginCharge()
		end
	end)
	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.KeyCode == Enum.KeyCode.Space then
			endCharge()
		end
	end)

	RunService.RenderStepped:Connect(function()
		if charging then
			local value = Meter.valueAt(os.clock() - chargeStart)
			meterFill.Size = UDim2.fromScale(value, 1)
			if chargeSound then
				chargeSound.PlaybackSpeed = 0.6 + value * 0.8 -- el tono sube con el medidor
			end
		end
	end)
end

function ThrowController.init()
	build()
	projectilePool = UIPool.new(function(): BasePart
		local part = Instance.new("Part")
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(2, 2, 2)
		part.Material = Enum.Material.Neon
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		return part
	end, function(part: BasePart)
		part.Parent = nil
	end, 10)

	Net.event("ThrowResult").OnClientEvent:Connect(function(result: any)
		if type(result) ~= "table" or typeof(result.landing) ~= "Vector3" then
			return
		end
		local thrower = Players:GetPlayerByUserId(result.userId)
		local character = if thrower then thrower.Character else nil
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if root and root:IsA("BasePart") then
			local rarity = Rarities.DEFS[result.rarity]
			animateProjectile(root.Position, result.landing, rarity and rarity.color or Color3.new(1, 1, 1))
		end
	end)
end

return ThrowController
