local npcManager = require("npcManager")
local ai = require("npcs/ai/flipperGates")

local flipperGate = {}
local npcID = NPC_ID

local flipperGateSettings = table.join({
	id = npcID,

	gfxwidth = 128,
	gfxheight = 40,
	gfxoffsety = 4,
	width = 128,
	height = 32,

	isVertical = true,
}, ai.sharedSettings)

npcManager.setNpcSettings(flipperGateSettings)
npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

ai.register(npcID)

return flipperGate