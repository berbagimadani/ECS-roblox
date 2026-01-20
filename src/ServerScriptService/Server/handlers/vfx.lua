local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local VFX_ROOT = ReplicatedStorage:FindFirstChild("VFX")

local function spawnFallbackVFX(hrp)
    local part = Instance.new("Part")
    part.Size = Vector3.new(1, 1, 1)
    part.Color = Color3.fromRGB(255, 80, 80)
    part.Transparency = 0.35
    part.Anchored = true
    part.CanCollide = false
    part.CFrame = hrp.CFrame * CFrame.new(0, 0, -3)
    part.Name = "Skill_Fallback_VFX"
    part.Parent = workspace

    TweenService:Create(
        part,
        TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = Vector3.new(6, 6, 6), Transparency = 1 }
    ):Play()

    Debris:AddItem(part, 1)
end

local function playVFX(templateName, hrp)
    if not hrp then
        return
    end

    local forwardOffset = hrp.CFrame.LookVector * 8
    local template = VFX_ROOT and VFX_ROOT:FindFirstChild(templateName)
    if template then
        local clone = template:Clone()

        -- Position parts/descendants in front of the player, add a quick tween for motion and fade.
        for _, inst in ipairs(clone:GetDescendants()) do
            if inst:IsA("BasePart") then
                inst.Anchored = true
                inst.CanCollide = false
                inst.CFrame = CFrame.new(hrp.Position + forwardOffset)

                local targetOrientation = Vector3.new(
                    math.random(-180, 180),
                    math.random(-180, 180),
                    math.random(-180, 180)
                )

                TweenService:Create(
                    inst,
                    TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {
                        Position = inst.Position + hrp.CFrame.LookVector * 4,
                        Orientation = targetOrientation,
                        Transparency = 1,
                    }
                ):Play()
            elseif inst:IsA("ParticleEmitter") then
                inst:Emit(inst:GetAttribute("Burst") or 25)
            end
        end

        clone.Parent = workspace
        Debris:AddItem(clone, 2)
    else
        spawnFallbackVFX(hrp)
    end
end

return {
    playVFX = playVFX,
}
