local starcoin = {}

local starcoinAI = require("npcs/ai/starcoin")
local npcutils = require("npcs/npcutils")
local npcManager = require("npcManager")

local npcID = NPC_ID

local config = npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 46,
	gfxheight = 46,
	width = 46,
	height = 46,
	frames = 8,
	framespeed = 8,
	framestyle = 0,
	nohurt = true,
	score = 8,
	nofireball = true,
	noiceball = true,
	noyoshi = false,
	nohurt = true,
	isinteractable = true,
	noblockcollision=false,
	nogravity = true,
	harmlessgrab = true,
	notcointransformable = true,
	luahandlesspeed = true,

	nospecialanimation = false,
	shellcollectable = true,
	nopowblock = false,
	collectedframes = -1
})
npcManager.registerHarmTypes(npcID, {}, nil)


local UNCOLLECTED = 0
local SAVED = 1
local COLLECTED = 2
local COLLECTED_WEAK = 3

function starcoin.onStartNPC(coin)
	if coin.ai2 == nil then coin.ai2 = UNCOLLECTED end
	starcoinAI.registerAlive(coin.ai2)
end

--This is called from here to ensure it runs AFTER onStartNPC
function starcoin.onStart()
	starcoinAI.init()
end

function starcoin.onDrawNPC(coin)
	local CoinData = starcoinAI.getTemporaryData()
	if coin.ai2 == nil then coin.ai2 = UNCOLLECTED end
	if CoinData[coin.ai2] == nil then
		CoinData[coin.ai2] = UNCOLLECTED
	end
	starcoinAI.registerAlive(coin.ai2)

	if not config.nospecialanimation then
		local collectedframes = config.collectedframes
		if collectedframes == -1 then collectedframes = math.ceil(config.frames*0.5) end
		local frames = config.frames - collectedframes
		local offset = 0
		local gap = collectedframes
		if CoinData[coin.ai2] and CoinData[coin.ai2] > UNCOLLECTED then
			frames = collectedframes
			offset = config.frames - collectedframes
			gap = 0
		end
			--npcutils.restoreAnimation(coin)
			coin.animationFrame = npcutils.getFrameByFramestyle(coin, { frames = frames, offset = offset, gap = gap })
	end
end

local function shellFilterFunction(other)
	return (not other.friendly) and  (other.despawnTimer > 0) and (other:mem(0x12C, FIELD_WORD) == 0) and (other:mem(0x132, FIELD_WORD) > 0)
end

function starcoin.onTickEndNPC(v)
	if Defines.levelFreeze then return end

	local data = v.data._basegame

	if v.despawnTimer <= 0 then
		data.init = false
	end

	if not data.init then
		v.noblockcollision = true
		data.init = true
		data.falling = false
		data.bounces = 0
	end
	
	if v.friendly or v:mem(0x138, FIELD_WORD) > 0 or v:mem(0x12C, FIELD_WORD) ~= 0 then return end

	if data.falling then
		v.speedY = v.speedY + Defines.npc_grav
		if v.collidesBlockBottom then
			if data.bounces < 4 then
				data.bounces = data.bounces + 1
				v.speedY = -6 * (1/(data.bounces+2))
			else
				v.speedY = 0
			end
		end
	else
		npcutils.applyLayerMovement(v)
	end

	if NPC.config[v.id].shellcollectable then
		for k, shell in ipairs(Colliders.getColliding{a = v, b = NPC.SHELL, btype = Colliders.NPC, filter = shellFilterFunction, collisionGroup = v.collisionGroup}) do
			starcoinAI.collect(v)
			break
		end
	end
end

function starcoin.onPostNPCCollect(n, p)
	if n.id == npcID then
		starcoinAI.collect(n)
	end
end

function starcoin.onNPCPOWHit(eo, npc, type)
	if npc.id == npcID then
		npc.data._basegame.falling = true
		npc.noblockcollision = false
	end
end

function starcoin.onInitAPI()
	npcManager.registerEvent(npcID, starcoin, "onStartNPC")
	npcManager.registerEvent(npcID, starcoin, "onDrawNPC")
	npcManager.registerEvent(npcID, starcoin, "onTickEndNPC")
	registerEvent(starcoin, "onPostNPCCollect")
	registerEvent(starcoin, "onNPCPOWHit")
	registerEvent(starcoin, "onStart", "onStart", false)
end

return starcoin
