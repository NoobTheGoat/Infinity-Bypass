local HttpService = game:GetService("HttpService")
local SS = game:GetService("ServerStorage")

local toolbar = plugin:CreateToolbar("Upload Script")
local upload_all_scripts_button = toolbar:CreateButton("Upload", "parses the scripts inside mainmodule present in SS.Asset.MainModule", "")

local repo = "awdwadwa213eawdaw/externalmonkey"
local token = "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"

-- Functions
local http = {}
local base64 = {}

upload_all_scripts_button.Click:Connect(function()
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
					["content"] = base64.to_base64(v.Source),
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
					["content"] = base64.to_base64(v.Source),
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
	
	print("Program finished successfully!")
end)

-- Http

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

-- Base64

function base64.to_base64(data: string)
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