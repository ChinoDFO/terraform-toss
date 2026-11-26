--!strict
-- Lectura de ventajas del jugador. Las escribe SOLO el servidor como atributos del Player
-- (un cambio de atributo hecho en el cliente no se replica al servidor, así que no se puede falsificar).

local Perks = {}

function Perks.hasPass(player: Player, key: string): boolean
	return player:GetAttribute("Pass_" .. key) == true
end

function Perks.setPass(player: Player, key: string, owned: boolean)
	player:SetAttribute("Pass_" .. key, owned)
end

function Perks.hasPlus(player: Player): boolean
	return player:GetAttribute("PlusPerk") == true
end

function Perks.boostActive(player: Player): boolean
	local untilTime = tonumber(player:GetAttribute("BoostUntil")) or 0
	return os.time() < untilTime
end

function Perks.adLuckActive(player: Player): boolean
	local untilTime = tonumber(player:GetAttribute("AdLuckUntil")) or 0
	return os.time() < untilTime
end

return Perks
