local HttpService = game:GetService("HttpService")

repeat task.wait() until script:GetAttribute("loadstring")

if not script:FindFirstAncestor("ServerScriptService") then
    local loadstring = require(game:GetService("ReplicatedStorage").Loadstring)
    
    local s, code = pcall(function()
        local code = game:GetService("ReplicatedStorage"):WaitForChild("GetSource"):InvokeServer(script:GetAttribute("loadstring"))
        if code == nil then return end
        return loadstring(code)
    end)

    if not s then
        return loadstring(HttpService:GetAsync(script:GetAttribute("loadstring")))()
    end

    return (code ~= nil) and code or {}
end

return loadstring(HttpService:GetAsync(script:GetAttribute("loadstring")))()