local npcManager = require("npcManager")
local configTypes = require("configTypes")

local Magic = {}

local npcID = NPC_ID;

local Magic = {}

local defaultTransformations = {54, 112, 33, 185, 301, 165}

npcManager.setNpcSettings({
	id = npcID, 
	gfxwidth = 42, 
	gfxheight = 42, 
	width = 38, 
	height = 38, 
	frames = 16, 
	framespeed = 3, 
	gfxoffsetx = 2, 
	gfxoffsety = 2, 
	nogravity = 1, 
	noblockcollision = 1, 
	nofireball = 1, 
	noiceball = 1,
	jumphurt = 1,
	spinjumpsafe = 1,
	noyoshi=true,
	lightradius=64,
	lightbrightness=1,
	lightcolor=Color.white,
	luahandlesspeed=true,
	movespeed = 3,
	sound = Misc.resolveSoundFile("magikoopa-magic"),
	transformations = configTypes.asArray(defaultTransformations),
	blocktargets = configTypes.asArray{90},

	-- these are kept so that they may still be read for compatibility
	transformation1 = defaultTransformations[1],
	transformation2 = defaultTransformations[2],
	transformation3 = defaultTransformations[3],
	transformation4 = defaultTransformations[4],
	transformation5 = defaultTransformations[5],
	transformation6 = defaultTransformations[6],
	blocktarget1 = 90,
})

function Magic.onInitAPI()
    npcManager.registerEvent(npcID, Magic, "onTickNPC")
    --registerEvent(Magic, "onNPCKill")
end

--[[ function Magic.onNPCKill(ev, killedNPC, rsn)
    if (killedNPC.id == npcID) then --Magic
		local magic = killedNPC
		local data = magic.data._basegame
		data.sound:Stop()
	end 
end ]]

local function sparkle(x,y) 
	local spawnX = x + RNG.randomInt(-18, 18)
	local spawnY = y + RNG.randomInt(-18, 18)
	local anim = Animation.spawn(80, spawnX, spawnY)
	anim.x = anim.x - anim.width/4
	anim.y = anim.y - anim.height/4
end 

function Magic.onTickNPC(magic)
    if Defines.levelFreeze then return end
	local v = magic
	local data = magic.data._basegame
	local cfg = NPC.config[v.id]
	if not v.isHidden and v:mem(0x124, FIELD_WORD) ~= 0 then
		if not data.initialized  then
			data.initialized = true
			data.sparkleTimer = 0
			local p = Player.getNearest(magic.x + 0.5 * magic.width, magic.y)
			data.playerX = p.x+p.width/2
			data.playerY = p.y+p.height/2
			data.direction = vector.v2(data.playerX - (magic.x+magic.width/2), data.playerY - (magic.y+magic.height/2)):normalise() * cfg.movespeed
			data.sound = SFX.play(cfg.sound)

			-- compatibility code for setting transformation npcs
			local compatTransformations = nil
			for i = 1, 6 do
				if cfg["transformation" .. i] ~= defaultTransformations[i] or compatTransformations ~= nil then
					if compatTransformations == nil then
						-- initialize table at the first changed value
						compatTransformations = {}
						for j = 1, i - 1 do
							compatTransformations[j] = defaultTransformations[j]
						end
					end
					local legacyValue = cfg["transformation" .. i]
					if legacyValue == 0 then
						-- 0 marked the end of the list
						break
					else
						compatTransformations[i] = legacyValue
					end
				end
			end
			data.transformations = compatTransformations or cfg.transformations

			if cfg.blocktarget1 ~= 90 then
				-- old name, for compatibility
				data.blockTargets = {[cfg.blocktarget1] = true}
			else
				data.blockTargets = table.map(cfg.blocktargets)
			end
		end
		data.sparkleTimer = (data.sparkleTimer + 1) % 4
		if(data.sparkleTimer == 0) then 
			sparkle(magic.x+magic.width/2, magic.y+magic.height/2)
		end 
		if not (v.dontMove or magic:mem(0x138, FIELD_WORD) > 0 or magic:mem(0x132, FIELD_WORD) > 0 or magic:mem(0x130, FIELD_WORD) > 0) then
				magic.speedX = data.direction.x * NPC.config[npcID].speed
				magic.speedY = data.direction.y * NPC.config[npcID].speed
			for _, intersectingBlock in Block.iterateIntersecting(v.x, v.y, v.x + v.width, v.y + v.height) do
				if data.blockTargets[intersectingBlock.id] and not intersectingBlock.isHidden then
					spawnedNpc = NPC.spawn(RNG.irandomEntry(data.transformations), intersectingBlock.x + 0.5 * intersectingBlock.width, intersectingBlock.y + intersectingBlock.height, magic:mem(0x146, FIELD_WORD))
					spawnedNpc.x = spawnedNpc.x -0.5 * spawnedNpc.width
					spawnedNpc.y = spawnedNpc.y - spawnedNpc.height
					spawnedNpc.layerName = "Spawned NPCs"
					spawnedNpc.friendly = magic.friendly
					if spawnedNpc.id == 33 then
						spawnedNpc.ai1 = 1
						spawnedNpc.speedX = RNG.random(-1, 1)
					end
					spawnedNpc.direction = RNG.randomInt(0, 1) * 2 - 1 -- either left (-1) or right (1)
					Animation.spawn(10, intersectingBlock.x, intersectingBlock.y)
					intersectingBlock:remove()
					v:kill()
					break
				elseif ((Block.SOLID_MAP[intersectingBlock.id] or Block.PLAYER_MAP[intersectingBlock.id]) and not intersectingBlock.isHidden) then
					v:kill()
				end
			end
		end
	end
	
end

return Magic