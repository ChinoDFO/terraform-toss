--!strict
-- FTUE y retención (solo interfaz): tutorial de 3 pasos con flecha, panel de misiones diarias,
-- meta "siguiente criatura/zona" y aviso de combo. El servidor decide y envía atributos; aquí solo
-- se muestra y se pide ("reclamar misión", "entendido"). Textos en español.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = require(ReplicatedStorage.Shared.Net)
local Quests = require(ReplicatedStorage.Shared.Config.Quests)
local Ui = require(script.Parent.Parent.UI.Ui)
local NumberFormat = require(ReplicatedStorage.Shared.Util.NumberFormat)
local HudController = require(script.Parent.HudController)

local player = Players.LocalPlayer

local ProgressController = {}

local TUTORIAL_TEXT: { [number]: string } = {
	[1] = "Paso 1/3 · ¡Lanza! Mantén pulsado LANZAR y suelta cuando el medidor esté alto.",
	[2] = "Paso 2/3 · ¡Mejora! Compra una mejora con tu dinero (botones verdes).",
	[3] = "Paso 3/3 · Mira tu jardín: tus criaturas aparecen en tu parcela y generan dinero.",
}

local gui: ScreenGui
local banner: TextLabel
local okButton: TextButton
local arrow: TextLabel
local goalLabel: TextLabel
local questPanel: Frame
local questRows: { { label: TextLabel, button: TextButton } } = {}
local comboFrame: Frame
local comboFill: Frame
local comboToken = 0

local function attrNumber(name: string): number
	return tonumber(player:GetAttribute(name)) or 0
end

-- Botón sobre el que apunta la flecha en cada paso (se busca por nombre en la interfaz existente).
local function arrowTarget(step: number): GuiObject?
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if playerGui == nil then
		return nil
	end
	local name, gname = nil, nil
	if step == 1 then
		name, gname = "Throw", "ThrowUi"
	elseif step == 2 then
		name, gname = "UpTrain", "Hud"
	end
	if name == nil or gname == nil then
		return nil
	end
	local root = playerGui:FindFirstChild(gname)
	local target = if root then root:FindFirstChild(name) else nil
	if target and target:IsA("GuiObject") then
		return target
	end
	return nil
end

local function refreshTutorial()
	local step = attrNumber("TutorialStep")
	local active = step >= 1 and step < Quests.TUTORIAL_DONE
	banner.Visible = active
	okButton.Visible = step == 3
	if active then
		banner.Text = TUTORIAL_TEXT[step] or ""
	end
	arrow.Visible = active and arrowTarget(step) ~= nil
end

local function refreshQuests()
	for i, row in questRows do
		local quest = Quests.QUESTS[i]
		local progress = attrNumber("QuestProgress" .. i)
		local claimed = player:GetAttribute("QuestClaimed" .. i) == true
		row.label.Text = string.format("%s  (%d/%d)", quest.text, progress, quest.target)
		row.button.Visible = true
		if claimed then
			row.button.Text = "✔ Listo"
			row.button.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
		elseif progress >= quest.target then
			row.button.Text = "RECLAMAR"
			row.button.BackgroundColor3 = Color3.fromRGB(70, 170, 90)
		else
			row.button.Text = "…"
			row.button.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
		end
	end
	local goal = player:GetAttribute("GoalText")
	goalLabel.Text = if typeof(goal) == "string" then goal else ""
end

local function build()
	gui =
		Ui.make("ScreenGui", { Name = "ProgressUi", ResetOnSpawn = false }, player:WaitForChild("PlayerGui")) :: ScreenGui

	-- Meta visible (siempre).
	goalLabel = Ui.label(gui, "Goal", UDim2.fromScale(0.28, 0.095), UDim2.fromScale(0.44, 0.03), "")
	goalLabel.TextColor3 = Color3.fromRGB(255, 235, 160)

	-- Tutorial: banner + botón "Entendido" (paso 3) + flecha.
	banner = Ui.label(gui, "TutorialBanner", UDim2.fromScale(0.25, 0.14), UDim2.fromScale(0.5, 0.07), "")
	banner.BackgroundTransparency = 0.35
	banner.BackgroundColor3 = Color3.fromRGB(25, 30, 45)
	Ui.make("UICorner", { CornerRadius = UDim.new(0, 12) }, banner)
	okButton = Ui.button(
		gui,
		"TutorialOk",
		UDim2.fromScale(0.42, 0.22),
		UDim2.fromScale(0.16, 0.06),
		"¡Entendido!",
		Color3.fromRGB(70, 170, 90)
	)
	okButton.Activated:Connect(function()
		Net.event("TutorialAck"):FireServer()
	end)
	arrow = Ui.label(gui, "TutorialArrow", UDim2.new(), UDim2.fromOffset(48, 48), "▼")
	arrow.AnchorPoint = Vector2.new(0.5, 1)
	arrow.TextColor3 = Color3.fromRGB(255, 230, 90)

	-- Misiones diarias.
	local toggle = Ui.button(
		gui,
		"QuestsToggle",
		UDim2.fromScale(0.02, 0.34),
		UDim2.fromScale(0.14, 0.06),
		"Misiones",
		Color3.fromRGB(80, 160, 220)
	)
	questPanel = Ui.make("Frame", {
		Name = "Quests",
		Position = UDim2.fromScale(0.17, 0.3),
		Size = UDim2.fromScale(0.34, 0.2),
		BackgroundColor3 = Color3.fromRGB(25, 30, 45),
		BackgroundTransparency = 0.2,
		Visible = false,
	}, gui) :: Frame
	Ui.make("UICorner", { CornerRadius = UDim.new(0, 12) }, questPanel)
	Ui.label(
		questPanel,
		"Title",
		UDim2.fromScale(0.05, 0.03),
		UDim2.fromScale(0.9, 0.2),
		"Misiones de hoy (se reinician cada día)"
	)
	for i = 1, #Quests.QUESTS do
		local y = 0.26 + (i - 1) * 0.24
		local label = Ui.label(questPanel, "Q" .. i, UDim2.fromScale(0.04, y), UDim2.fromScale(0.62, 0.2), "")
		label.TextXAlignment = Enum.TextXAlignment.Left
		local button = Ui.button(
			questPanel,
			"Claim" .. i,
			UDim2.fromScale(0.7, y),
			UDim2.fromScale(0.27, 0.2),
			"…",
			Color3.fromRGB(80, 80, 90)
		)
		button.Activated:Connect(function()
			Net.event("ClaimQuest"):FireServer(i)
		end)
		table.insert(questRows, { label = label, button = button })
	end
	toggle.Activated:Connect(function()
		questPanel.Visible = not questPanel.Visible
	end)

	-- Aviso de combo: barra que se vacía durante la ventana REAL del combo.
	comboFrame = Ui.make("Frame", {
		Name = "Combo",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.62),
		Size = UDim2.fromScale(0.3, 0.07),
		BackgroundColor3 = Color3.fromRGB(25, 30, 45),
		BackgroundTransparency = 0.25,
		Visible = false,
	}, gui) :: Frame
	Ui.make("UICorner", { CornerRadius = UDim.new(0, 12) }, comboFrame)
	Ui.label(comboFrame, "Text", UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.7), "¡Combo cerca! Lanza YA")
	comboFill = Ui.make("Frame", {
		Position = UDim2.fromScale(0.05, 0.75),
		Size = UDim2.fromScale(0.9, 0.15),
		BackgroundColor3 = Color3.fromRGB(255, 200, 80),
		BorderSizePixel = 0,
	}, comboFrame) :: Frame
end

-- Un compañero lanzó cerca: el combo (decidido por el servidor) sigue disponible Quests.COMBO_WINDOW s.
local function showComboPrompt()
	comboToken += 1
	local token = comboToken
	local start = os.clock()
	comboFrame.Visible = true
	task.spawn(function()
		while token == comboToken do
			local left = 1 - (os.clock() - start) / Quests.COMBO_WINDOW
			if left <= 0 then
				break
			end
			comboFill.Size = UDim2.fromScale(0.9 * left, 0.15)
			task.wait()
		end
		if token == comboToken then
			comboFrame.Visible = false
		end
	end)
end

local function myRoot(): BasePart?
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

function ProgressController.init()
	build()
	player.AttributeChanged:Connect(function()
		refreshTutorial()
		refreshQuests()
	end)
	refreshTutorial()
	refreshQuests()

	-- La flecha rebota sobre el botón objetivo.
	RunService.RenderStepped:Connect(function()
		if not arrow.Visible then
			return
		end
		local target = arrowTarget(attrNumber("TutorialStep"))
		if target == nil then
			arrow.Visible = false
			return
		end
		local bob = math.sin(os.clock() * 6) * 6
		local pos = target.AbsolutePosition
		local size = target.AbsoluteSize
		arrow.Position = UDim2.fromOffset(pos.X + size.X / 2, pos.Y - 4 + bob)
	end)

	Net.event("ThrowResult").OnClientEvent:Connect(function(result: any)
		if type(result) ~= "table" or result.userId == player.UserId then
			return
		end
		local thrower = Players:GetPlayerByUserId(result.userId)
		local character = if thrower then thrower.Character else nil
		local theirs = if character then character:FindFirstChild("HumanoidRootPart") else nil
		local mine = myRoot()
		if mine and theirs and theirs:IsA("BasePart") then
			if (theirs.Position - mine.Position).Magnitude <= Quests.COMBO_RADIUS then
				showComboPrompt()
			end
		end
	end)

	Net.event("Notify").OnClientEvent:Connect(function(kind: any, data: any)
		if kind == "QuestDone" and type(data) == "table" then
			HudController.toast("✔ Misión completada: +$" .. NumberFormat.short(tonumber(data.reward) or 0))
			refreshQuests()
		elseif kind == "Tutorial" and type(data) == "table" and data.step == Quests.TUTORIAL_DONE then
			HudController.toast("¡Tutorial completado! Mira las Misiones de hoy.", Color3.fromRGB(120, 255, 140))
		end
	end)
end

return ProgressController
