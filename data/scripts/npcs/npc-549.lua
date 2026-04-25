local npcManager = require("npcManager")
local burner = require("npcs/ai/burner")
local npcutils = require("npcs/npcutils")

local burnerTop = {}
local npcID = NPC_ID

local burnerTopSettings = {
	id = npcID,
	flames = 1,
	frames=2,
	framestyle=1,
	framespeed=8,
	burnerframes=1,
	burnerframestyle=0,
	burnerframespeed=8,
	cliffturn = true,
	nogravity = false,
	iswalker = true,
	notcointransformable = false,
	nowalldeath = false,
	staticdirection = false,
	luahandlesspeed = false,
	noblockcollision = false
}

npcManager.registerHarmTypes(npcID, 	
{
	--HARM_TYPE_JUMP,
	HARM_TYPE_FROMBELOW,
	HARM_TYPE_NPC,
	HARM_TYPE_HELD,
	--HARM_TYPE_SPINJUMP,
	HARM_TYPE_PROJECTILE_USED,
	HARM_TYPE_SWORD,
	HARM_TYPE_LAVA
}, 
{--[HARM_TYPE_JUMP]=10,
[HARM_TYPE_FROMBELOW]=314,
[HARM_TYPE_PROJECTILE_USED]=314,
[HARM_TYPE_NPC]=314,
[HARM_TYPE_HELD]=314,
[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}});

burner.registerBurner(npcID, burnerTopSettings)

function burnerTop.onDrawNPC(v)
	if v.despawnTimer <= 0 then return end
	local data = v.data._basegame
	if data.bop then
		local cfg = NPC.config[v.id]
		if data.animationTimer == nil then
			data.animationTimer = 0
		end
		if not Misc.isPaused() then
			data.animationTimer = data.animationTimer + 1
		end
		local frame = math.floor(data.animationTimer / cfg.framespeed) % cfg.frames
		data.bop = (math.floor(data.animationTimer / cfg.framespeed) % 2) * -2

		local p = -45
		if cfg.foreground then
			p = -15
		end
		p = p + 0.001
		npcutils.drawNPC(v, {priority = p, frame = frame})
		local f = math.floor(data.animationTimer / cfg.burnerframespeed) % cfg.burnerframes
		local totalFrames = cfg.burnerframes
		if cfg.burnerframestyle > 0 then
			if cfg.burnerframestyle == 2 then
				if v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x132, FIELD_WORD) > 0 then
					f = f + 2 * cfg.burnerframes
				end
			end
			if dir == 1 then
				f = f + cfg.burnerframes
			end
		end
		local totalFrames2 = cfg.frames
		if cfg.framestyle > 0 then
			if cfg.framestyle == 2 then
				if v:mem(0x12C, FIELD_WORD) > 0 or v:mem(0x132, FIELD_WORD) > 0 then
					totalFrames2 = totalFrames2 + 2 * cfg.frames
				end
			end
			totalFrames2 = totalFrames2 + cfg.frames
		end
		v.animationFrame = f + totalFrames2
	end
end

npcManager.registerEvent(npcID, burnerTop, "onDrawNPC")

--Gotta return the library table!
return burnerTop