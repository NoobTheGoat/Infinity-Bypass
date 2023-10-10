game:GetService("ReplicatedStorage").GetSource.OnServerInvoke = function(player, url)
	local s, r = pcall(function()
		return game:GetService("HttpService"):GetAsync(url)
	end)
	
	if s then return r else return nil end
end