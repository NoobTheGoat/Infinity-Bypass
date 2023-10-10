local HttpService = game:GetService("HttpService")
local SS = game:GetService("ServerStorage")
local LSS = game:GetService("ServerStorage"):WaitForChild("LoadingAssets")

local returns = {
	[1] = HttpService:GetAsync("http://parser.rshift4496.repl.co/DataJsons/data_975909.json", true),
}

local returned = ""

for _,str in ipairs(returns) do
	returned = returned..str
end

local import = HttpService:JSONDecode(returned)

local debounce1 = os.clock()

local function loadChildren(parent_properties, parent)    
	if os.clock() - debounce1 > 5 then
		task.wait()
		debounce1 = os.clock()
	end
	
	if parent_properties[1] == "TouchTransmitter" then
		return
	end
	
	local asset = Instance.new(parent_properties[1])
	
	if (parent_properties[1] == "Script" and parent_properties[2] ~= "RequireHLO") or parent_properties[1] == "LocalScript" or parent_properties[1] == "ModuleScript" then
		asset:Destroy()
		
		asset = LSS[parent_properties[1]]:Clone()
		asset.Name = parent_properties[2]
	elseif parent_properties[1] == "Script" then
		asset:Destroy()

		asset = LSS["RequireHLO"]:Clone()
		asset.Name = parent_properties[2]	
	end
	
	for _, attributes in pairs(parent_properties[4]) do
		for attribute, value in pairs(attributes) do
			asset:SetAttribute(attribute, value)
		end
	end

	for i,property in pairs(parent_properties[3]) do
		if i == "ClassName" or i == "Children" or i == "Attributes" or i == "Parent" or asset.ClassName == "ModuleScript" then
			continue
		end

		if i == "CFrame" then
			local cframe, _ = pcall(function()
				asset[i] = CFrame.new(table.unpack(property:gsub(" ",""):split(",")))
			end)
			return
		elseif i == "Color3" then
			local color3, _ = pcall(function()
				asset[i] = Color3.new(table.unpack(property:gsub(" ",""):split(",")))
			end)
			return
		end

		if property:split(".")[1] == "Enum" then
			local enum_catagory = property:split(".")[2]
			local enum_value = property:split(".")[3]

			asset[i] = Enum[enum_catagory][enum_value]
		else    
			local success, _ = pcall(function()
				local booleanHandler = { ["true"]=true, ["false"]=false }

				if booleanHandler[property] == nil then
					asset[i] = property
				else 
					asset[i] = booleanHandler[property]
				end
			end)

			if not success then
				local vector3, _ = pcall(function()
					asset[i] = Vector3.new(table.unpack(property:gsub(" ",""):split(",")))
				end)

				if not vector3 then
					local cframe, _ = pcall(function()
						asset[i] = CFrame.new(table.unpack(property:gsub(" ",""):split(",")))
					end)

					if not cframe then
						local color3, _ = pcall(function()
							asset[i] = Color3.new(table.unpack(property:gsub(" ",""):split(",")))
						end)

						if not color3 then
							local physical_properties, err = pcall(function()
								asset[i] = PhysicalProperties.new(table.unpack(property:gsub(" ",""):split(",")))
							end)
						end
					end
				end
			end
		end
	end
	
	asset.Parent = parent
	
	
	for _,child_properties in pairs(parent_properties[3]) do
		loadChildren(child_properties, asset)
	end
end

loadChildren(import, SS)

for _,model in pairs(SS.Folder.MainModule:GetChildren()) do
	model.Parent = LSS.MainModule
end

SS.Folder:Destroy()

--[[local SSE = Instance.new("Folder");SSE.Parent=LSS.MainModule;SSE.Name="ServerStorage"

local SSO = SS.ServerStorage
SSO.Parent = game:GetService("ServerScriptService")

wait(1.5)

for _, object in pairs(SSO:GetChildren()) do
	object.Parent = SSE
end]]--

--SS.MapChunks.Parent = LSS.MainModule.ServerStorage

--LSS.MainModule.Parent = game:GetService("ServerStorage")

if _G.Chunk == nil then _G.Chunk = 1 end

print("Done Loading Chunk #"..tostring(_G.Chunk))

local scripts = 0
for i, scriptf in pairs(script.Parent:GetChildren()) do
	if scriptf.Enabled then
		scripts = scripts + 1
	end
end

if _G.Chunk == scripts then
	local Loaded = Instance.new("StringValue")
	Loaded.Parent = script.Parent
	Loaded.Name = "Loaded"
end

_G.Chunk = _G.Chunk+1

if script.Parent:FindFirstChild("Loaded") then
	--game:GetService("ServerScriptService").Initializer.Enabled = true
	
	local players = game:GetService("Players")

	local loadfunc = require(LSS.MainModule)()

	repeat wait() until _G.BypassFinished

	--// Final Checkpoint (#2)
	_G.FilesInitialized = true

	--// Load Players
	players.CharacterAutoLoads = true
	for _,plr in pairs(players:GetPlayers()) do
		pcall(function() plr:LoadCharacter() end)
	end

	script:Destroy()

end