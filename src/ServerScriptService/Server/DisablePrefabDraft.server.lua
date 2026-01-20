-- ServerScriptService/Server/DisablePrefabDraft.server.lua

if not game:GetService("RunService"):IsServer() then
	return
end

local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")

local runtime = Workspace:WaitForChild("Runtime")
local prefabDraft = runtime:FindFirstChild("_PrefabDraft")

if prefabDraft then
	prefabDraft:Destroy()
end
