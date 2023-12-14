repeat wait() until _G.SerializerLoaded
--// Login Credentials for the json

local authToken = "7ddf32e17a6ac5ce04a8ecbf782ca509"
local url = "http://parser.rshift4496.repl.co/DataJsons/data_891190.json"

local LOAD_SS = true --For experimenting, loads the ss from inside SS.ServerStorage
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local SS = game:GetService("ServerStorage")
local LSS = game:GetService("ServerStorage"):WaitForChild("LoadingAssets")

--// Destroy Old Asset folder if it exists
local OldAssets = SS:FindFirstChild("Asset")
if OldAssets then OldAssets:Destroy() end

--// Get & parse the json

local function makeRequest(url)
	for attempt = 1, 2 do
		local success, response = pcall(function()
			return HttpService:GetAsync(url, true, { ["authtoken"] = authToken })
		end)
		if success then return response end
	end
	return
end

local ImportedData = makeRequest(url)

print(ImportedData)

if not ImportedData then warn("Failed to obtain json; please double-check your authorization token or url! "); return; end

local import = HttpService:JSONDecode(ImportedData)

--//
--local debounce1 = os.clock()

-- [1] = ClassName
-- [2] = Name
-- [3] = Properties
-- [4] = Attributes
-- [5] = Children

local function loadChildren(parent_properties, parent)    

	if parent_properties[1] == "TouchTransmitter" then
		return
	end

	if parent_properties[1] == "MeshPart" or parent_properties[1] == "Mesh" then parent_properties[1] = "Part" end

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

	if parent_properties[1] == "MeshPart" or parent_properties[1] == "Mesh" then
		local meshProperties = {'TextureId', 'MeshId'} 

		local SpecialMesh = Instance.new("SpecialMesh")
		SpecialMesh.Name = "Mesh"
		SpecialMesh.Parent = asset

		for _, meshProperty in pairs(meshProperties) do
			if parent_properties[3][meshProperty] == nil then continue end
			SpecialMesh[meshProperty] = parent_properties[3][meshProperty]
		end
	end

	--// Set the attributes
	for attribute, value in pairs(parent_properties[4]) do
		asset:SetAttribute(attribute, value)
	end

	--// Set the properties
	for i,property in pairs(parent_properties[3]) do
		spawn(function()
			if i == "ClassName" or i == "Children" or i == "Attributes" or i == "Parent" or asset.ClassName == "ModuleScript" then
				return
			end

			local booleanStrings = {
				["true"] = true, 
				["false"] = false, 
				["nil"] = nil
			}

			local s,r = pcall(function()
				local a = typeof(asset[i])
			end)

			if not s then
				pcall(function()
					asset[i] = property
				end)
				return
			end

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
		end)
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

if LOAD_SS and _G.SS_ID ~= nil and _G.SS_LOADED ~= true then
	game:GetService("InsertService"):LoadAsset(_G.SS_ID):GetChildren()[1].Parent=SS
	
	local SSE = Instance.new("Folder");SSE.Parent=LSS.MainModule;SSE.Name="ServerStorage"

	local SSO = SS:WaitForChild("ServerStorage")

	for _, object in pairs(SSO:GetChildren()) do 
		object.Parent = SSE
	end
	
	_G.SS_LOADED = true
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
	
	local ReloadEvent = game:GetService("ReplicatedStorage"):WaitForChild("Reload")
	
	--// Load Players
	Players.CharacterAutoLoads = true
	for _,plr in pairs(Players:GetPlayers()) do
		pcall(function() plr:LoadCharacter(); ReloadEvent:FireClient(plr) end)
	end

	task.wait(math.random(0.2, 0.89))
	
	pcall(function()
		local a=workspace:FindFirstChild("Baseplate");if a then a:Destroy() end;
		local b=workspace:FindFirstChild("SpawnLocation");if b then b:Destroy() end;
		x:Destroy()
	end)

	script.Parent:Destroy()
end