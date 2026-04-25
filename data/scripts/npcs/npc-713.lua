local veggie = {}

local npcManager = require("npcManager")
local npcID = NPC_ID

local settings = {
	id = npcID,
	width=32,
	height=32,
	gfxwidth=32,
	gfxheight=32,
	frames=1,
	framestyle=0,
	speed=1,
	playerblock=false,
	playerblocktop = true,
	npcblock = false,
	npcblocktop = true,
	nogravity = false,
	nohurt = false,
	isvegetable = true,
	jumphurt = false,
	spinjumpsafe = false,
	grabtop = true,
	noyoshi = false,
}

npcManager.setNpcSettings(settings)

function veggie.onPostNPCKill(v, r)
	if v.id == npcID and r == HARM_TYPE_VANISH and (v.forcedState == NPCFORCEDSTATE_YOSHI_TONGUE or v.forcedState == NPCFORCEDSTATE_YOSHI_MOUTH) and v.forcedCounter1 > 0 then
		local p = Player(v.forcedCounter1)

		if p then
			p:harm()
		end
	end
end

function veggie.onTickEndNPC(v)
	v:mem(0x12E, FIELD_WORD, math.min(v:mem(0x12E, FIELD_WORD), Defines.npc_throwfriendlytimer))
end

npcManager.registerEvent(NPC_ID, veggie, "onTickEndNPC")
registerEvent(veggie, "onPostNPCKill")

return veggie