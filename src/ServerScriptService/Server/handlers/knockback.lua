local Workspace = game:GetService("Workspace")

local damage = require(script.Parent.damage)

local function getOverlapParams(character)
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { character }
    params.MaxParts = 50
    return params
end

local function moveTarget(target, hrp, distance)
    local direction = hrp.CFrame.LookVector
    local destination = target.Position + direction * distance

    if target:IsA("BasePart") then
        target.AssemblyLinearVelocity = Vector3.zero
        target.AssemblyAngularVelocity = Vector3.zero
        target.CFrame = CFrame.new(destination, destination + direction)
    elseif target:IsA("Model") then
        local primary = target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
        if primary then
            target:PivotTo(CFrame.new(primary.Position + direction * distance, destination + direction))
        end
    end
end

local function knockbackTargets(character, skill, hrp)
    local kb = skill.knockback
    if not kb then
        return
    end

    local radius = kb.radius or 10
    local slide = kb.slide or 4

    local center = hrp.CFrame + hrp.CFrame.LookVector * math.min(radius, 12)
    local size = Vector3.new(radius * 2, radius, radius * 2)

    local parts = Workspace:GetPartBoundsInBox(center, size, getOverlapParams(character))
    local hitModels = {}

    for _, part in ipairs(parts) do
        local skip = part:IsDescendantOf(character) or part.Anchored
        if not skip then
            local targetModel = part:FindFirstAncestorWhichIsA("Model")
            local targetHRP = targetModel and targetModel:FindFirstChild("HumanoidRootPart")
            local targetHumanoid = targetModel and targetModel:FindFirstChildOfClass("Humanoid")

            local target = targetHRP or part

            if target then
                if targetModel and not hitModels[targetModel] and damage.isEnemyModel(targetModel) then
                    damage.applyDamage(targetModel, targetHumanoid, skill)
                    hitModels[targetModel] = true
                end

                moveTarget(targetHRP or target, hrp, slide)
            end
        end
    end
end

return {
    knockbackTargets = knockbackTargets,
}
