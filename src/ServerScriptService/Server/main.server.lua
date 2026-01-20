-- Entry point: route skill requests to helpers (VFX, knockback, damage, points).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local skillRequest = remotes:WaitForChild("SkillRequest")

local serverFolder = ServerScriptService:WaitForChild("Server")
local handlersFolder = serverFolder:WaitForChild("handlers")

require(handlersFolder:WaitForChild("ui_debug"))

local Skills = require(serverFolder:WaitForChild("skills"))
local VFX = require(handlersFolder:WaitForChild("vfx"))
local Knockback = require(handlersFolder:WaitForChild("knockback"))
local Leaderstats = require(handlersFolder:WaitForChild("leaderstats"))

local lastCast = {}

skillRequest.OnServerEvent:Connect(function(player, action)
    local skill = Skills[action]
    if not skill then
        return
    end

    local now = os.clock()
    lastCast[player] = lastCast[player] or {}
    local last = lastCast[player][action] or 0
    if now - last < skill.cooldown then
        return
    end
    lastCast[player][action] = now

    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if hrp then
        VFX.playVFX(skill.vfx, hrp)
        Knockback.knockbackTargets(character, skill, hrp)
    end

    if skill.points then
        Leaderstats.awardPoints(player, skill.points)
    end
end)
