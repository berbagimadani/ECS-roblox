local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HealthBarTemplate = ReplicatedStorage:FindFirstChild("UI")
	and ReplicatedStorage.UI:FindFirstChild("EnemyHealthBillboard")

local HealthBars = {}

local function getEnemyRoot()
	local runtime = Workspace:FindFirstChild("Runtime")
	return runtime and runtime:FindFirstChild("Enemies")
end

local function chooseAdornee(model: Model)
	return model:FindFirstChild("Head")
		or model:FindFirstChild("HumanoidRootPart")
		or model:FindFirstChildWhichIsA("BasePart")
end

local function attachHealthBar(model, humanoid, healthAttrProvider)
	if HealthBars[model] then
		return HealthBars[model]
	end

	local adornee = chooseAdornee(model)
	if not adornee or not HealthBarTemplate then
		return nil
	end

	local ui = HealthBarTemplate:Clone()
	ui.Adornee = adornee
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
	end

	local conn

	if humanoid then
		update(humanoid.Health, humanoid.MaxHealth)

		conn = humanoid.HealthChanged:Connect(function(newHealth) 
			update(newHealth, humanoid.MaxHealth) -- maxHealth dinamis
		end)

	elseif healthAttrProvider then
		local function readMax()
			return healthAttrProvider:GetAttribute("MaxHealth") or 100
		end

		local function readHealth()
			local maxH = readMax()
			return healthAttrProvider:GetAttribute("Health") or maxH
		end

		update(readHealth(), readMax())

		conn = healthAttrProvider:GetAttributeChangedSignal("Health"):Connect(function()
			update(readHealth(), readMax())
		end)
	end

	model.Destroying:Connect(function()
		HealthBars[model] = nil
		if conn then conn:Disconnect() end
	end)

	return ui
end

local function isEnemyModel(model)
	local enemyRoot = getEnemyRoot()
	return enemyRoot and model and model:IsDescendantOf(enemyRoot)
end

local function applyDamage(targetModel, targetHumanoid, skill)
	local dmg = skill.damage or 0
	if dmg <= 0 then return end

	if targetHumanoid then
		attachHealthBar(targetModel, targetHumanoid, nil)
		targetHumanoid:TakeDamage(dmg)
		return
	end

	local current = targetModel and targetModel:GetAttribute("Health")
	if current ~= nil then
		local nextHealth = math.max(0, current - dmg)
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
