local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SkillRequest")

local Skills = {
    [Enum.KeyCode.T] = { name = "SkillT", anim = "rbxassetid://18240706555" },
    [Enum.KeyCode.Y] = { name = "SkillY", anim = "rbxassetid://18240706555" },
    [Enum.KeyCode.U] = { name = "SkillU", anim = "rbxassetid://18240706555" },
}

local localPlayer = Players.LocalPlayer

local function getAnimator(humanoid)
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end
    return animator
end

local function playSkillAnimation(skill)
    local character = localPlayer.Character
    if not character then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    local animator = getAnimator(humanoid)
    local animation = Instance.new("Animation")
    animation.AnimationId = skill.anim

    local track = animator:LoadAnimation(animation)
    track.Looped = false

    local fired = false
    local markerConn = track:GetMarkerReachedSignal("Hit"):Connect(function()
        if fired then
            return
        end
        fired = true
        remote:FireServer(skill.name)
    end)

    track.Stopped:Connect(function()
        if markerConn then
            markerConn:Disconnect()
        end

        if not fired then
            remote:FireServer(skill.name)
        end
    end)

    track:Play()
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end

    local skill = Skills[input.KeyCode]
    if not skill then
        return
    end

    playSkillAnimation(skill)
end)
