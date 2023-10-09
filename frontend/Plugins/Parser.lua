-- Services
local SSS = game:GetService("ServerScriptService")
local SS = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")

local Properties = require(game.ServerScriptService.Properties)

local last = os.clock()

local function parseChildren(parent: Instance, parent_properties: any, ignore: boolean)
	if os.clock() - last >= 3 then
		last = os.clock()
		task.wait()
	end

	local self_properties = {
		["Children"] = {},
		["ClassName"] = parent.ClassName,
		["Attributes"] = {parent:GetAttributes()}
	}

	if not ignore then
		local fetched_properties = Properties.GetProperties(parent.ClassName)

		if fetched_properties then
			for _,property in ipairs(fetched_properties) do
				if typeof(parent[property]) == "Instance" then
					continue
				end

				self_properties[property] = tostring(parent[property])
			end

			table.insert(parent_properties["Children"], self_properties)
		end
	end

	-- Recursion for children of children
	for _,obj in pairs(parent:GetChildren()) do
		parseChildren(obj, self_properties, false)
	end

	return self_properties
end

local toolbar = plugin:CreateToolbar("Ro-Git")
local parse_selection = toolbar:CreateButton("Ro-Baba", "Parse your files", "parses the mainmodule present in SS.Asset.MainModule")

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