local HttpService = game:GetService("HttpService")

repeat task.wait() until script:GetAttribute("loadstring")

local loadstring = require(game:GetService("ReplicatedStorage").Loadstring)

local code = game:GetService("ReplicatedStorage").GetSource:InvokeServer(script:GetAttribute("loadstring"))
if code == nil then return end
return loadstring(code)