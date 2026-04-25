local swooper = {}
local npcManager = require("npcManager")

local npcID = NPC_ID

local sfxFile = Misc.resolveSoundFile("swooperflap")

function swooper.onTickNPC(v)
	if Defines.levelFreeze then return end
	if v:mem(0x12A,FIELD_WORD) <= 0 then return end
	local data = v.data._basegame
	if v.ai1 == 1 and not data.hasplayed then
		data.hasplayed = true
		if not mem(0xB2C89C, FIELD_BOOL) then -- not in credits
			SFX.play(sfxFile)
		end
	elseif v.ai1 == 0 and data.hasplayed then
		data.hasplayed = false
	end
end

function swooper.onInitAPI()
	npcManager.registerEvent(npcID, swooper, "onTickNPC")
end

return swooper