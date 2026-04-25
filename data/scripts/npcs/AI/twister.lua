local twister = {}

twister.npcBlacklist = {}
twister.npcWhitelist = {}

function twister.blacklist(id)
	twister.npcBlacklist[id] = true
end

function twister.whitelist(id)
	twister.npcWhitelist[id] = true
end

return twister