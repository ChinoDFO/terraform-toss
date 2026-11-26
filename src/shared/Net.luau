--!strict
-- Acceso tipado a los RemoteEvents definidos en default.project.json (carpeta ReplicatedStorage.Remotes).
-- Regla: NO usamos RemoteFunction. El cliente pide con un evento; el servidor responde con otro.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = {}

function Net.event(name: string): RemoteEvent
	local folder = ReplicatedStorage:WaitForChild("Remotes")
	local remote = folder:WaitForChild(name, 15)
	assert(remote ~= nil and remote:IsA("RemoteEvent"), "RemoteEvent no encontrado: " .. name)
	return remote :: RemoteEvent
end

function Net.serverState(): Folder
	local folder = ReplicatedStorage:WaitForChild("ServerState")
	assert(folder:IsA("Folder"), "ServerState debe ser un Folder")
	return folder :: Folder
end

return Net
