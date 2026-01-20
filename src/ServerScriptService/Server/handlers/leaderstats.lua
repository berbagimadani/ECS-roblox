local function ensureLeaderstats(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end

    local points = leaderstats:FindFirstChild("Points")
    if not points then
        points = Instance.new("IntValue")
        points.Name = "Points"
        points.Value = 0
        points.Parent = leaderstats
    end

    return points
end

local function awardPoints(player, amount)
    local points = ensureLeaderstats(player)
    points.Value = points.Value + amount
end

return {
    awardPoints = awardPoints,
}

