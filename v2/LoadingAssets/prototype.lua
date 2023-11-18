local id = script:GetAttribute("id")

pcall(function()
    local FinalObject = game:GetService("ServerStorage"):WaitForChild("FinalHLO")[id]
    FinalObject.Name = FinalObject:GetAttribute("name")
    FinalObject.Parent = script.Parent

    script:Destroy()
end)