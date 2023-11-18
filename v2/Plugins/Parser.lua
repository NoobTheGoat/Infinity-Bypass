-- Services
local SS = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")

local AssetsLoaded = false

repeat wait() spawn(function()
	AssetsLoaded = (script:FindFirstChild("Properties"))
end) until AssetsLoaded

local Properties = require(script.Properties)

local last = os.clock()

-- [1] = ClassName
-- [2] = Name
-- [3] = Properties
-- [4] = Attributes
-- [5] = Children

local function parseChildren(parent: Instance, parent_properties: any, ignore: boolean)
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

				self_properties[3][property] = tostring(parent[property])
			end

			table.insert(parent_properties[5], self_properties)
		end
	end

	-- Recursion for children of children
	for _,obj in pairs(parent:GetChildren()) do
		parseChildren(obj, self_properties, false)
	end

	return self_properties
end

local toolbar = plugin:CreateToolbar("Parser")
local parse_selection = toolbar:CreateButton("Parse", "Parses your game files", "")

local db = false

parse_selection.Click:Connect(function()
	if db == true then warn("Currently In Process, Cooldown is enabled, try again later!") end
	if not SS:FindFirstChild("Asset") or not SS.Asset:FindFirstChild("MainModule") then warn("Asset/MainModule Is Missing!") end
	db = true
	
	local data = game.HttpService:JSONEncode(parseChildren(SS.Asset, {["Children"] = {}, ["ClassName"] = "nil"}, true))

	local success = false

	-- URL of the endpoint you want to send the request to
	local url = "http://parser.rshift4496.repl.co//SetJson"  -- Replace with your URL

	-- Create a table for custom headers
	local headers = {
		["DataJ"] = data,
	}

	-- Create a table for the HTTP request parameters
	local requestInfo = {
		Url = url,
		Method = "POST",  -- Use POST to send data in the request body
		Headers = {
			["Content-Type"] = "application/json",  -- Set the content type
		},
		Body = HttpService:JSONEncode({ DataJ = data }),  -- Encode data as JSON and send in the body
	}

	local response = game.HttpService:RequestAsync(requestInfo)

	print("Response :", response.Body)
	
	db = false
end)