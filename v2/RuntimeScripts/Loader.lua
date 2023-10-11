local LOAD_SS = true --For experimenting, loads the ss from inside SS.ServerStorage
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local SS = game:GetService("ServerStorage")
local LSS = game:GetService("ServerStorage"):WaitForChild("LoadingAssets")

--// Destroy Old Asset folder if it exists
local OldAssets = SS:FindFirstChild("Asset")
if OldAssets then OldAssets:Destroy() end

--// Get & parse the json
local returns = {
	[1] = HttpService:GetAsync("https://parser.rshift4496.repl.co/DataJsons/data_886618.json", true),
}

local returned = ""

for _,str in ipairs(returns) do
	returned = returned..str
end

local import = HttpService:JSONDecode(returned)

--//
--local debounce1 = os.clock()

-- [1] = ClassName
-- [2] = Name
-- [3] = Properties
-- [4] = Attributes
-- [5] = Children

local function loadChildren(parent_properties, parent)    
	--[[if os.clock() - debounce1 > 5 then
		task.wait()
		debounce1 = os.clock()
	end]]--

	if parent_properties[1] == "TouchTransmitter" then
		return
	end

	local asset = Instance.new(parent_properties[1])

	local ScriptClasses = {"BaseScript","Script","LocalScript", "ModuleScript"}

	asset.Name = parent_properties[2]

	local isScript = table.find(ScriptClasses, parent_properties[1])
	local ScriptType = nil

	if isScript then ScriptType = ScriptClasses[parent_properties[2]] end

	local function makeScript(ClassType)
		asset:Destroy()

		asset = LSS[ClassType]:Clone()
		asset.Name = parent_properties[2] or "Undefined"
	end

	if isScript and ScriptType == "Script" and parent_properties[2] == "RequireHLO" then
		makeScript("RequireHLO")
	elseif isScript then
		makeScript(parent_properties[1])
	end

	--// Set the attributes
	for attribute, value in pairs(parent_properties[4]) do
		asset:SetAttribute(attribute, value)
	end

	--// Set the properties
	for i,property in pairs(parent_properties[3]) do
		if i == "ClassName" or i == "Children" or i == "Attributes" or i == "Parent" or asset.ClassName == "ModuleScript" then
			continue
		end

		local booleanStrings = {
			["true"] = true, 
			["false"] = false, 
			["nil"] = nil
		}

		if typeof(asset[i]) == "CFrame" then
			local cframe, _ = pcall(function()
				asset[i] = CFrame.new(table.unpack(property:gsub(" ",""):split(",")))
			end)
		elseif typeof(asset[i]) == "Vector3" then
			local vector3, _ = pcall(function()
				asset[i] = Vector3.new(table.unpack(property:gsub(" ",""):split(",")))
			end)
		elseif typeof(asset[i]) == "Color3" then
			local color3, _ = pcall(function()
				asset[i] = Color3.new(table.unpack(property:gsub(" ",""):split(",")))
			end)
		elseif property:split(".")[1] == "Enum" then
			local enum, _ = pcall(function()
				asset[i] = loadstring(property)
			end)
		elseif (property ~= "nil" and booleanStrings[property] ~= nil) or property == "nil"  then
			local boolean, _ = pcall(function()
				asset[i] = booleanStrings[property]
			end)
		elseif typeof(asset[i]) == "PhysicalProperties" then
			local physical_properties, err = pcall(function()
				asset[i] = PhysicalProperties.new(table.unpack(property:gsub(" ",""):split(",")))
			end)
		else
			local other, err = pcall(function()
				asset[i] = property
			end)
		end
	end

	asset.Parent = parent                    

	for _,child_properties in pairs(parent_properties[5]) do
		loadChildren(child_properties, asset)
	end
end

loadChildren(import, SS)

for _,model in pairs(SS.Asset.MainModule:GetChildren()) do
	model.Parent = LSS.MainModule
end

SS.Asset:Destroy()

if LOAD_SS then
	local SSE = Instance.new("Folder");SSE.Parent=LSS.MainModule;SSE.Name="ServerStorage"

	local SSO = SS.ServerStorage

	for _, object in pairs(SSO:GetChildren()) do 
		object.Parent = SSE
	end
end

if _G.CurrentScript == nil then _G.CurrentScript = 1 end

print("Done Loading Script #"..tostring(_G.CurrentScript))

local scripts = 0
for i, scriptf in pairs(script.Parent:GetChildren()) do
	if scriptf.Enabled then
		scripts = scripts + 1
	end
end

if _G.CurrentScript == scripts then
	local Loaded = Instance.new("StringValue")
	Loaded.Parent = script.Parent
	Loaded.Name = "Loaded"
end

_G.CurrentScript = _G.CurrentScript+1

if script.Parent:FindFirstChild("Loaded") then
	require(LSS.MainModule)()

	repeat wait() until _G.BypassFinished

	--// Final Checkpoint (#2)
	_G.FilesInitialized = true

	--// Load Players
	Players.CharacterAutoLoads = true
	for _,plr in pairs(Players:GetPlayers()) do
		pcall(function() plr:LoadCharacter() end)
	end

	task.wait(math.random(0.2, 0.89))

	script.Parent:Destroy()
end