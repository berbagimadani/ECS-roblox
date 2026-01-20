local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local assets = ServerStorage:WaitForChild("Assets")
local npcFolder = assets:WaitForChild("NPC")
local enemies = npcFolder:WaitForChild("Enemies") 

local map = Workspace:WaitForChild("Map")
local markers = map:WaitForChild("Markers")
local npc = markers:WaitForChild("NPC")
local enemyMarkers = npc:WaitForChild("Enemies")

local runtime = Workspace:FindFirstChild("Runtime") or Instance.new("Folder")
runtime.Name = "Runtime"
runtime.Parent = Workspace

local function hideMarker(p: BasePart)
	p.Transparency = 1
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
end

for _, marker in ipairs(enemyMarkers:GetDescendants()) do
	if marker:IsA("BasePart") then
		local prefabName = marker:GetAttribute("Prefab")
		if typeof(prefabName) ~= "string" or prefabName == "" then
			warn("Marker missing Prefab attribute:", marker:GetFullName())
			continue
		end

		local prefab = enemies:FindFirstChild(prefabName)
		if not prefab then
			warn("Prefab not found in ServerStorage.Assets.Enemies:", prefabName)
			continue
		end

		local count = marker:GetAttribute("Count")
		if typeof(count) ~= "number" or count < 1 then count = 1 end

		for i = 1, count do
			local clone = prefab:Clone()
			if clone:IsA("Model") then
				clone:PivotTo(marker.CFrame)
			elseif clone:IsA("BasePart") then
				clone.CFrame = marker.CFrame
			end
			clone.Parent = runtime
		end

		hideMarker(marker)
	end
end
