local fuzzy = {}

local npcID = NPC_ID

local npcManager = require("npcManager")
local fuzzyAI = require("npcs/ai/yifuzzy")

fuzzy.settings = npcManager.setNpcSettings{
	id = npcID,
	
	width = 48,
	height = 40,
	gfxwidth = 64,
	gfxheight = 60,
	gfxoffsetx = 0,
	gfxoffsety = 6,
	ignorethrownnpcs = true,
	speed = 1,
	frames = 2,
	framespeed = 16,
	nogravity = true,
	noblockcollision = true,
	noyoshi = false,
	grabside = false,
	jumphurt = true,
	nohurt = true,
	isinteractable = true,

	dizzytransitiontime = 7.5,
	dizzytime = 15,
	dizzystrength = 1
}

local harmTypes = {
	HARM_TYPE_JUMP, HARM_TYPE_NPC, HARM_TYPE_EXT_FIRE, HARM_TYPE_EXT_ICE, HARM_TYPE_EXT_HAMMER, --no dizzy
	HARM_TYPE_TAIL --dizzy
}

local harmMap = {}
for _,v in ipairs(harmTypes) do
	harmMap[v] = 131
end

npcManager.registerHarmTypes(npcID, harmTypes, harmMap)

fuzzyAI.registerFuzzy(npcID)

return fuzzy
