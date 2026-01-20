local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Runtime = Workspace:FindFirstChild("Runtime")
local EnemyRoot = Runtime and Runtime:FindFirstChild("Enemies")

local HealthBarTemplate = ReplicatedStorage:FindFirstChild("UI")
    and ReplicatedStorage.UI:FindFirstChild("EnemyHealthBillboard")

local HealthBars = {}

local function attachHealthBar(model, humanoid, healthAttrProvider)
    if HealthBars[model] then
        return HealthBars[model]
    end

    local head = model:FindFirstChild("Head") or model:FindFirstChildWhichIsA("BasePart")
    if not head or not HealthBarTemplate then
        return nil
    end

    local ui = HealthBarTemplate:Clone()
    ui.Adornee = head
    ui.AlwaysOnTop = true
    ui.Parent = model
    HealthBars[model] = ui

    local function update(current, max)
        local frame = ui:FindFirstChild("Frame") or ui:FindFirstChildWhichIsA("Frame")
        local bar = frame and frame:FindFirstChild("Bar")
        if bar and bar:IsA("Frame") then
            bar.Size = UDim2.new(math.clamp(max > 0 and current / max or 0, 0, 1), 0, 1, 0)
        end

        local label = frame and (frame:FindFirstChild("HPText") or frame:FindFirstChildWhichIsA("TextLabel"))
        if label then
            label.Text = string.format("%d / %d", math.floor(current), math.floor(max))
        end

        if _G.DEBUG_HEALTH then
            print(string.format("[HealthBar] %s: %d/%d", model:GetFullName(), math.floor(current), math.floor(max)))
        end
    end

    if humanoid then
        local maxHealth = humanoid.MaxHealth
        update(humanoid.Health, maxHealth)

        humanoid.HealthChanged:Connect(function(newHealth)
            update(newHealth, maxHealth)
        end)
    elseif healthAttrProvider then
        local maxHealth = healthAttrProvider:GetAttribute("MaxHealth") or 100
        local current = healthAttrProvider:GetAttribute("Health") or maxHealth
        update(current, maxHealth)

        healthAttrProvider:GetAttributeChangedSignal("Health"):Connect(function()
            local nextHealth = healthAttrProvider:GetAttribute("Health") or 0
            update(nextHealth, maxHealth)
        end)
    end

    model.Destroying:Connect(function()
        HealthBars[model] = nil
    end)

    return ui
end

local function isEnemyModel(model)
    return EnemyRoot and model and model:IsDescendantOf(EnemyRoot)
end

local function applyDamage(targetModel, targetHumanoid, skill)
    local damage = skill.damage or 0
    if damage <= 0 then
        return
    end

    if targetHumanoid then
        attachHealthBar(targetModel, targetHumanoid, nil)
        targetHumanoid:TakeDamage(damage)
        return
    end

    local current = targetModel and targetModel:GetAttribute("Health")
    if current then
        local nextHealth = math.max(0, current - damage)
        targetModel:SetAttribute("Health", nextHealth)

        attachHealthBar(targetModel, nil, targetModel)

        if nextHealth <= 0 then
            targetModel:Destroy()
        end
    end
end

return {
    isEnemyModel = isEnemyModel,
    applyDamage = applyDamage,
    attachHealthBar = attachHealthBar,
}
