--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local colliders = require("colliders")

local missile = {}
local npcIDs = {}

function missile.register(id)
	npcManager.registerEvent(id, missile, "onTickNPC")
	npcIDs[id] = true
end

function missile.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--Kill NPCs
	for k,npc in ipairs(Colliders.getColliding{a = v, atype = Colliders.NPC, b = NPC.HITTABLE}) do
		if (not npc.friendly and not npc.isHidden and not npc.isinteractable and not npc.iscoin) and npc:mem(0x138, FIELD_WORD) == 0 then
			npc:harm(HARM_TYPE_NPC)
			Animation.spawn(10,v.x,v.y - 10)
			v:kill(HARM_TYPE_OFFSCREEN)
		end
	end
	
	--Break blocks
	data.destroyCollider = data.destroyCollider or Colliders.Box(v.x - 4, v.y + 8, v.width + 8, v.height - 8);
	data.destroyCollider.x = v.x + 0.5 * (v.width + 2) * v.direction;
	data.destroyCollider.y = v.y + 8;
	local tbl = Block.SOLID .. Block.PLAYER
	local list = Colliders.getColliding{
	a = data.destroyCollider,
	b = tbl,
	btype = Colliders.BLOCK,
	filter = function(other)
		if other.isHidden or other:mem(0x5A, FIELD_BOOL) then
			return false
		end
		v:kill()
		Animation.spawn(10,v.x,v.y - 10)
		return true
	end
	}
	for _,b in ipairs(list) do
		if (Block.config[b.id].smashable ~= nil and Block.config[b.id].smashable == 3) or b.id == 186 then
			b:remove(true)
		else
			b:hit(true)
		end
	end
	
	--Set its despawn timer to be shorter so it doesnt destroy blocks too far away from the screen
	if (v.x + v.width > camera.x and v.x < camera.x + camera.width and v.y + v.height > camera.y and v.y < camera.y + camera.height) then
		v:mem(0x12A, FIELD_WORD, 48)
	end
end

return missile