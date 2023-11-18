local currentUnion = 1
local SS = game:GetService("ServerStorage")
local RequireHLOF = SS:FindFirstChild("RequireHLO")

if not SS:FindFirstChild("Asset") then warn("Asset Folder/ModuleScript Missing! game.ServerStorage.Asset") return end
if not SS.Asset:FindFirstChild("MainModule") then warn("MainModule Missing! game.ServerStorage.Asset.MainModule") return end

if not RequireHLOF then
    RequireHLOF = Instance.new("Folder")
    RequireHLOF.Parent = game.ServerStorage
    RequireHLOF.Name = "RequireHLO"
end

local function replaceUnion(object)
    currentUnion = currentUnion + 1
    object:SetAttribute("name", object.Name)
    object.Name = tostring(currentUnion)
    local RequireHLO = Instance.new("Script")
    RequireHLO.Parent = object.Parent
    RequireHLO.Name = "RequireHLO"
    RequireHLO:SetAttribute("id", tostring(currentUnion))
    object.Parent = RequireHLOF
end

for i,v in pairs(SS.Asset.MainModule:GetDescendants()) do
    if not v:IsA("UnionOperation") or v:IsA("MeshPart") then continue end
    replaceUnion(v)
end