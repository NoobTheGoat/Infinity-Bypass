repeat wait() until script:GetAttribute("id") ~= nil

local id = script:GetAttribute("id")

local FinalObject = game:GetService("ServerStorage"):WaitForChild("FinalHLO"):FindFirstChild(id)

if FinalObject then
	FinalObject.Name = FinalObject:GetAttribute("name")
	FinalObject.Parent = script.Parent
	
	task.wait()
	
	script:Destroy()
else 
	script.Name = "FailedHLO"
end