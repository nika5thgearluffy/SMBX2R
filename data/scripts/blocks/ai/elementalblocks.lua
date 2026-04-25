local eBlocks = {}

local blockmanager = require("blockmanager")
local blockutils = require("blocks/blockutils")

local idMap = {}
local ids = {}
local relevantNPCIDs = {}
local relevantNPCIDMap = {}
local keywords = {}

function eBlocks.register(id, configString)
	idMap[id] = configString
	table.insert(ids, id)
	blockmanager.registerEvent(id, eBlocks, "onIntersectBlock")
end

local function meltIce(v)	
	Animation.spawn(10,v.x,v.y)
	
	blockutils.spawnNPC(v)
	
	v:remove()
	SFX.play(3)
end

function eBlocks.onInitAPI()
	registerEvent(eBlocks, "onPostNPCKill")
end

local function blockfilter(w)
	return idMap[w.id] and blockutils.hiddenFilter(w)
end

function eBlocks.onIntersectBlock(v, o)
	if o.__type ~= "NPC" then return end
	local cfg = NPC.config[o.id]
	if cfg[idMap[v.id]] then
		if o:mem(0x138, FIELD_WORD) == 0 and o:mem(0x12C, FIELD_WORD) == 0 then
			meltIce(v)
			local durability = cfg.durability
			if durability >= 0 then
				o.data._basegame._durability = (o.data._basegame._durability or durability) - 1
				if o.data._basegame._durability <= 0 then
					o:kill(3)
				end
			end
		end
	end
end

function eBlocks.onPostNPCKill(v, rsn)
	if rsn ~= 4 and rsn ~= 3 then return end
	
	local doCollideCheck = false
	local cfg = NPC.config[v.id]
	for k,i in ipairs(ids) do
		if cfg[idMap[i]] then
			doCollideCheck = true
			break
		end
	end
	
	if doCollideCheck then
		for _,w in ipairs(blockutils.checkNPCCollisions(v, blockfilter)) do
			if cfg[idMap[w.id]] then
				meltIce(w)
			end
		end
	end
end

return eBlocks