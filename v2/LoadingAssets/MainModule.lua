return function()
    --// Handler
for _,service in pairs(script:GetChildren()) do
    for _,files in pairs(service:GetChildren()) do
        files.Parent = game:GetService(service.Name)
    end            
end

--// Checkpoint (#1)
_G.BypassFinished = true

--// Cleaning Up
wait(1.5)
script:Destroy()
end