local smallSwitch = {}

local npcManager = require("npcManager")
local ssw = require("npcs/ai/smallswitch")
local synced = require("blocks/ai/synced")

local npcID = NPC_ID

local settings = { --What have I got in my pocket?
	id = npcID,
	color="synced",
	iscustomswitch = true,
	width=32,
	height=32,
	gfxwidth=32,
	gfxheight=32,
	grabside = false,
	grabtop = false,
	frames=2,
	noyoshi = true,
	nofireball = true,
	noiceball = true,

	switchstate = 2,
	permanent = true,
	switchon = false, --Whether the switch transforms "off" blocks into "on" blocks.
	switchoff = false, --Whether the switch transforms existing "on" blocks into off blocks.
	iscustomswitch = true
}
ssw.registerSwitch(settings)

function smallSwitch.onTickEndNPC(v)
	local pressed = synced.state == NPC.config[v.id].switchstate
	v.data._basegame.pressed = pressed
end

function smallSwitch.onTickEnd()
	local pressed = synced.state == NPC.config[npcID].switchstate
	NPC.config[npcID].npcblocktop = not pressed
	NPC.config[npcID].npcblock = not pressed
	NPC.config[npcID].playerblocktop = not pressed
	NPC.config[npcID].playerblock = not pressed
end

registerEvent(smallSwitch, "onTickEnd")
npcManager.registerEvent(npcID, smallSwitch, "onTickEndNPC")

return smallSwitch
