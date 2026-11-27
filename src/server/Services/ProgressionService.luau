--!strict
-- FTUE y retención: tutorial guiado de 3 pasos, misiones diarias simples y meta visible.
-- El servidor decide TODO: el cliente solo muestra atributos y pide "reclamar misión" / "entendido".
-- Sin dark patterns: sin temporizadores falsos, sin castigo por perder un día; las recompensas son
-- solo dinero PERSONAL y nada de lo compartido (planeta) depende de esto.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Quests = require(ReplicatedStorage.Shared.Config.Quests)
local Formulas = require(ReplicatedStorage.Shared.Util.Formulas)
local Net = require(ReplicatedStorage.Shared.Net)
local DataService = require(script.Parent.DataService)
local Progression = require(script.Parent.Parent.Util.Progression)
local RateLimiter = require(script.Parent.Parent.Util.RateLimiter)
local Validate = require(script.Parent.Parent.Util.Validate)

type PlayerData = Types.PlayerData

local DAY = 86400

local ProgressionService = {}
local notify: RemoteEvent
local allowClaim = RateLimiter.new(3, 1)
local allowAck = RateLimiter.new(2, 1)

local function sync(player: Player, data: PlayerData)
	player:SetAttribute("TutorialStep", data.tutorialStep)
	for i = 1, #Quests.QUESTS do
		player:SetAttribute("QuestProgress" .. i, Progression.questProgress(data, i))
		player:SetAttribute("QuestClaimed" .. i, data.questClaimed[i] == true)
	end
	player:SetAttribute("GoalText", Progression.nextGoal(data))
end

local function update(player: Player, data: PlayerData)
	Progression.rollQuests(data, os.time() // DAY)

	local before = data.tutorialStep
	local after = Progression.advanceTutorial(data)
	if after ~= before then
		data.tutorialStep = after
		if before == 1 and after >= 2 and after < Quests.TUTORIAL_DONE then
			-- Primera mejora garantizada: si no alcanza el dinero, se completa lo que falta (una sola vez).
			local cost = Formulas.trainingCost(data.trainingLevel)
			if data.cash < cost then
				data.cash = cost
			end
		end
		notify:FireClient(player, "Tutorial", { step = after })
	end
	sync(player, data)
end

local function onClaimQuest(player: Player, rawIndex: unknown)
	if not allowClaim(player) then
		return
	end
	local n = Validate.number(rawIndex, 1, #Quests.QUESTS)
	local data = DataService.get(player)
	if n == nil or data == nil or n ~= math.floor(n) then
		return
	end
	if data.questClaimed[n] == true or not Progression.questComplete(data, n) then
		return
	end
	data.questClaimed[n] = true
	local reward = Progression.questReward(data)
	data.cash += reward
	notify:FireClient(player, "QuestDone", { index = n, reward = reward })
	sync(player, data)
end

local function onTutorialAck(player: Player)
	if not allowAck(player) then
		return
	end
	local data = DataService.get(player)
	-- Solo se acepta en el paso 3; en cualquier otro momento se ignora.
	if data == nil or data.tutorialStep ~= 3 then
		return
	end
	data.tutorialStep = Quests.TUTORIAL_DONE
	notify:FireClient(player, "Tutorial", { step = data.tutorialStep })
	sync(player, data)
end

function ProgressionService.init()
	notify = Net.event("Notify")
	Net.event("ClaimQuest").OnServerEvent:Connect(onClaimQuest)
	Net.event("TutorialAck").OnServerEvent:Connect(onTutorialAck)
	DataService.Loaded:Connect(function(player: Player, data: PlayerData)
		update(player, data)
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			for player, data in DataService.all() do
				update(player, data)
			end
		end
	end)
end

return ProgressionService
