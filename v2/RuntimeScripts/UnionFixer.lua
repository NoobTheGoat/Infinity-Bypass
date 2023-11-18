for i,v in pairs(game.ServerStorage.Asset.MainModule:GetDescendants()) do
    local unionsI = 0
    local RequireHLOF = game.ServerStorage:FindFirstChild("RequireHLO")
    if not RequireHLOF then
        RequireHLOF = Instance.new("Folder")
        RequireHLOF.Parent = game.ServerStorage
        RequireHLOF.Name = "RequireHLO"
    end
    if v:IsA("UnionOperation") or v:IsA("MeshPart") then
        unionsI = unionsI + 1
        v:SetAttribute("name", v.Name)
        v.Name = tostring(unionsI)
        local RequireHLO = Instance.new("Script")
        RequireHLO.Parent = v.Parent
        RequireHLO.Name = "RequireHLO"
        RequireHLO:SetAttribute("id", tostring(unionsI))
        v.Parent = RequireHLOF
    end
end