--// Github login info, please update
local repo = "awdwadwa213eawdaw/externalmonkey"
local token = "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"

--// Parser API Endpoint

local Endpoint = "http://parser.rshift4496.repl.co//SetJson"

--// Services
local SS = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")

--// Plugin Tools
local Toolbar = plugin:CreateToolbar("Serializer")
local Serialize_Selection = Toolbar:CreateButton("Serialize", "Serialize your game files", "")
local UploadAllScripts = Toolbar:CreateButton("Upload Scripts", "Serialize/Update your scripts!", "")

--// Important Files
local RequireHLOF = SS:FindFirstChild("FinalHLO")

--// Ask for plugin permissions
local perms = Instance.new("Script", workspace)
pcall(function() perms:Destroy() end)
local perms2 = HttpService:GetAsync("https://raw.githubusercontent.com/jvalen/pixel-art-react/master/.travis.yml")

--// Create Require High Level Object Folder if it does not exist
if not RequireHLOF then
    RequireHLOF = Instance.new("Folder")
    RequireHLOF.Parent = game.ServerStorage
    RequireHLOF.Name = "FinalHLO"
end

local Properties = loadstring(game:GetService("HttpService"):GetAsync("https://pastebin.com/raw/fVNGzkZr"))()

local last = os.clock()

-- [1] = ClassName
-- [2] = Name
-- [3] = Properties
-- [4] = Attributes
-- [5] = Children

local function serializeChildren(parent: Instance, parent_properties: any, ignore: boolean)
	if os.clock() - last >= 3 then
		last = os.clock()
		task.wait()
	end
	
	local IgnoredClasses = {'TouchTransmitter'}

	if not ignore then ignore = table.find(IgnoredClasses, parent.ClassName) end

	if ignore and #parent:GetChildren() <= 0 then return end

	local IgnoredProperties = {'LinkedSource', 'Archivable'}

	local self_properties = {}

	self_properties[1] = parent.ClassName or "Folder"
	self_properties[3] = {}
	self_properties[4] = parent:GetAttributes() or {}
	self_properties[5] = {}
	self_properties[2] = parent.Name or "Undefined"

	if not ignore then
		local fetched_properties = Properties.GetProperties(parent.ClassName)

		if fetched_properties then
			for _,property in ipairs(fetched_properties) do
				if typeof(parent[property]) == "Instance" or property == "Name" or table.find(IgnoredProperties, property) then
					continue
				end

				if property == "PrimaryPart" and parent[property] == nil then continue end
				if property == "Anchored" and parent[property] == false then continue end
				if property == "Locked" and parent[property] == false then continue end
				if property == "CustomPhysicalProperties" and parent[property] == nil then continue end
				if property == "Transparency" and parent[property] == 0 then continue end

				self_properties[3][property] = tostring(parent[property])
			end

			table.insert(parent_properties[5], self_properties)
		end
	end

	-- Recursion for children of children
	for _,obj in pairs(parent:GetChildren()) do
		serializeChildren(obj, self_properties, false)
	end

	return self_properties
end

--// Cooldown
local Cooldown = false

--// SourceCode of "RequireHLO" Script
local RequireHLOsource = [[local a=script:GetAttribute("id")pcall(function()local b=game:GetService("ServerStorage"):WaitForChild("FinalHLO")[a]b.Name=b:GetAttribute("name")b.Parent=script.Parent;script:Destroy()end)]]

--// Current Union being processed!
local currentUnion = #RequireHLOF:GetChildren() + 1

--// Replace Union function
local function replaceUnion(object: Instance)
    currentUnion = currentUnion + 1
    object:SetAttribute("name", object.Name)
    object.Name = tostring(currentUnion)
    local RequireHLO = Instance.new("Script")
    RequireHLO.Parent = object.Parent
    RequireHLO.Name = "RequireHLO"
	RequireHLO.Source = RequireHLOsource
    RequireHLO:SetAttribute("id", tostring(currentUnion))
    object.Parent = RequireHLOF
end

--// Iterate through every union and replace it with a temporary placeholder
local function fixUnions(object: Instance)
	for i,v in pairs(object:GetDescendants()) do
		if not v:IsA("UnionOperation") or v:IsA("MeshPart") then continue end
		replaceUnion(v)
	end
end

--// Main Serializer
Serialize_Selection.Click:Connect(function()
	if Cooldown == true then warn("Currently In Process, Cooldown is enabled, try again later!") end

    --// Check if the files are present in the correct manner
	if not SS:FindFirstChild("Asset") then warn("Asset Folder/ModuleScript Missing! game.ServerStorage.Asset") return end
	if not SS.Asset:FindFirstChild("MainModule") then warn("MainModule Missing! game.ServerStorage.Asset.MainModule") return end
	Cooldown = true
	
    --// Migrate the unions
	print("Attempting To Migrate Unions!")
	fixUnions(SS.Asset)
	print("Unions Migrated Successfully to game.ServerStorage.FinalHLO!")

    --// Serialize the scripts
    print("Attempting To Serialize Scripts!")
    UploadScripts(true)

    --// Serialize the MainModule
	print("Attempting To Serialize MainModule!")

	local DataJSON = serializeChildren(SS.Asset, {["Children"] = {}, ["ClassName"] = "nil"}, true)

	print("Serialized MainModule Successfully!")

	print("Attempting To Upload JSON data!")

	local data = HttpService:JSONEncode(DataJSON)

	--// Create a table for the HTTP request parameters
	local requestInfo = {
		Url = Endpoint,
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json",
		},
		Body = HttpService:JSONEncode({ DataJ = data }),
	}

	local response = HttpService:RequestAsync(requestInfo)

	print("Response :", response.Body)
	
	Cooldown = false
end)

UploadAllScripts.Click:Connect(function()
	print("Attempting to upload scripts!")
	UploadAllScripts()
end)

-- Functions
local http = {}

function UploadScripts(ignore: boolean)
    local roblox_requests = 0
	local github_requests = 0

	if not SS:FindFirstChild("Asset") then warn("Asset Folder Does not exist, file structure is game.ServerStorage.Asset.MainModule") return end
	if not SS.Asset:FindFirstChild("MainModule") then warn("MainModule Does not exist, file structure is game.ServerStorage.Asset.MainModule") return end

	for _,v in pairs(SS.Asset.MainModule:GetDescendants()) do
		if roblox_requests == 499 and github_requests < 999 then
			print(roblox_requests)
			warn("Roblox is being ratelimited, waiting 1 minute.")
			task.wait(61)
			roblox_requests = 0
		elseif github_requests == 999 then
			warn("GitHub is being ratelimited, waiting 1 hour.")
			task.wait(3601)
			github_requests = 0
			roblox_requests = 0
		end

		if v:IsA("BaseScript") then
			if ignore == true and v:GetAttribute("loadstring") ~= nil then return end
			local filename = HttpService:GenerateGUID(false).."_S.lua"
			local url = `https://api.github.com/repos/{repo}/contents/{filename}`
			local raw = `https://raw.githubusercontent.com/{repo}/main/{filename}`

			local r = http.put(
				url,
				{
					["Authorization"] = `Token {token}`
				},
				{
					["message"] = `Created {filename}`,
					["content"] = encode_base64(v.Source),
					["branch"] = "main"
				}
			)

			local updated = (v:GetAttribute("loadstring") ~= nil)

			if updated then
				print("Script updated with name: "..filename.."!")
			else
				print("Script created with name: "..filename.."!")
			end

			v:SetAttribute("loadstring", raw)

			roblox_requests += 1
			github_requests += 1
		elseif v:IsA("ModuleScript") then
			if ignore == true and v:GetAttribute("loadstring") ~= nil then return end
			local filename = HttpService:GenerateGUID(false).."_MS.lua"
			local url = `https://api.github.com/repos/{repo}/contents/{filename}`
			local raw = `https://raw.githubusercontent.com/{repo}/main/{filename}`

			local r = http.put(
				url,
				{
					["Authorization"] = `Token {token}`
				},
				{
					["message"] = `Created {filename}`,
					["content"] = encode_base64(v.Source),
					["branch"] = "main"
				}
			)

			local updated = (v:GetAttribute("loadstring") ~= nil)

			if updated then
				print("ModuleScript updated with name: "..filename.."!")
			else
				print("ModuleScript created with name: "..filename.."!")
			end

			v:SetAttribute("loadstring", raw)



			roblox_requests += 1
			github_requests += 1	
		end
	end
	
	print("Finished Serializing Scripts!")
end

--// Http Functions

function http.get(url: string, headers: any)
	local r = HttpService:RequestAsync({
		Url = url,
		Method = "GET",
		Headers = headers
	})

	return r
end

function http.put(url: string, headers: any, body: any)
	local r = HttpService:RequestAsync({
		Url = url,
		Method = "PUT",
		Headers = headers,
		Body = HttpService:JSONEncode(body)
	})

	return r
end

function http.delete(url: string, headers: any, body: any)
	local r = HttpService:RequestAsync({
		Url = url,
		Method = "DELETE",
		Headers = headers,
		Body = HttpService:JSONEncode(body)
	})

	return r
end

--// Cryptographic functions

function encode_base64(data: string)
	local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
	return ((data:gsub('.', function(x) 
		local r,b='',x:byte()
		for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
		return r;
	end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
		if (#x < 6) then return '' end
		local c=0
		for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
		return b:sub(c+1,c+1)
	end)..({ '', '==', '=' })[#data%3+1])
end