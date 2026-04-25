local npcManager = require("npcManager")
local utils = require("npcs/npcutils")

local ninjaman = {}
local npcID = NPC_ID

local configTypes = require("configTypes")

local defaultJumpHeights = {4.5, 4.5, 6.5, 8.5}

local regularSettings = {
	id = npcID,
	gfxoffsety=2,
	gfxheight = 32,
	gfxwidth = 32,
	width = 24,
	height = 24,
	frames = 2,
	framespeed=8,
	framestyle = 1,
	jumphurt = 0,
	nogravity = 0,

	bounces=4, -- no longer supported
	bounceheights = configTypes.asArray(defaultJumpHeights),
	bounce1=defaultJumpHeights[1],
	bounce2=defaultJumpHeights[2],
	bounce3=defaultJumpHeights[3],
	bounce4=defaultJumpHeights[4],
	startbounce = 3,
	wait=65,
}


npcManager.registerHarmTypes(npcID, 	
{
	HARM_TYPE_JUMP,
	HARM_TYPE_FROMBELOW,
	HARM_TYPE_NPC,
	HARM_TYPE_HELD,
	HARM_TYPE_TAIL,
	HARM_TYPE_SPINJUMP,
	HARM_TYPE_SWORD,
	HARM_TYPE_LAVA
}, 
{
	[HARM_TYPE_JUMP]={id=197, speedX=0, speedY=0},
	[HARM_TYPE_FROMBELOW]=197,
	[HARM_TYPE_NPC]=197,
	[HARM_TYPE_HELD]=197,
	[HARM_TYPE_TAIL]=197,
	[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
});


npcManager.setNpcSettings(regularSettings)

function ninjaman.onInitAPI()
	npcManager.registerEvent(npcID, ninjaman, "onTickNPC")
	npcManager.registerEvent(npcID, ninjaman, "onDrawNPC")
end

function ninjaman.onDrawNPC(v)
	if Defines.levelFreeze then return end
	
	v.animationTimer = 500
	v.animationFrame = 0
	if v.speedY < 0 then
		v.animationFrame = 1
	end
	if v.direction == 1 then v.animationFrame = v.animationFrame + 2 end
end

local function parseJumpHeight(v, cfg)
	local tbl = {}
	local compatJumpHeights = nil
	for i = 1, 4 do
		if cfg["bounce" .. i] ~= defaultJumpHeights[i] or compatJumpHeights ~= nil then
			if compatJumpHeights == nil then
				-- initialize table at the first changed value
				compatJumpHeights = {}
				for j = 1, i - 1 do
					compatJumpHeights[j] = defaultJumpHeights[j]
				end
			end
			-- unlike magikoopa, for this npc a value of 0 just means "dont jump"
			compatJumpHeights[i] = cfg["bounce" .. i]
		end
	end
	return compatJumpHeights or cfg.bounceheights
end

function ninjaman.onTickNPC(v)
	if Defines.levelFreeze then return end

	local data = v.data._basegame
	if v.isHidden or v:mem(0x12A, FIELD_WORD) <= 0 or v:mem(0x138,FIELD_WORD) > 0 or v:mem(0x136, FIELD_BOOL) or v:mem(0x12C, FIELD_WORD) > 0 then
		data.jumpTimer = nil
		return
	end

	local cfg = NPC.config[v.id]
	
	if data.jumpTimer == nil then
		data.jumpHeight = parseJumpHeight(v, cfg)
		data.currentHeight = math.clamp(cfg.startbounce, 1, #data.jumpHeight)
		data.jumpTimer = cfg.wait
	end
	
	if v.collidesBlockBottom then
		data.jumpTimer = data.jumpTimer + 1
		
		v.speedX = utils.getLayerSpeed(v)
	end
	
	if data.jumpTimer > cfg.wait then
		data.jumpTimer = 0
		v.speedY = -data.jumpHeight[data.currentHeight]
		data.currentHeight = data.currentHeight%(#data.jumpHeight) + 1
	end
end
	
return ninjaman