local lakitu = {}
local npcManager = require("npcManager")
local laktiuAI = require("npcs/ai/lakitu")

local npcID = NPC_ID

local config = npcManager.setNpcSettings({
	id = npcID,
	inheritfriendly = false
})


function lakitu.onTickNPC(v)
	if Defines.levelFreeze then return end
	if v:mem(0x12A,FIELD_WORD) <= 0 then return end

	if v.ai5 >= 149 then
		local data = v.data._basegame
		data.collider = data.collider or Colliders.Box(0,0,0,0)
		data.collider.x = v.x - 16
		data.collider.y = v.y - 16
		data.collider.width = v.width + 32
		data.collider.height = v.height + 32

		local collides = #Colliders.getColliding{
			a = data.collider, b = Block.SOLID .. Block.PLAYER, btype = Colliders.BLOCK, collisionGroup = v.collisionGroup,
		} > 0

		if not collides then
			v.animationTimer = 100
			v.ai3 = 3
			v.ai5 = 0
			local p = Player.getNearest(v.x + 0.5 * v.width, v.y + 0.5 * v.height)
			local dir = -1
			if p.x + 0.5 * p.width > v.x + 0.5 * v.width then
				dir = 1
			end
			local speedX = dir * (RNG.random(0,1) + 1)
			local speedY = -7
			
			local n = laktiuAI.spawnNPC(v, v.ai1, v.x + 0.5 * v.width, v.y + 8, speedX, speedY)
			SFX.play(25)

			if NPC.config[n.id].iscoin then
				n.ai1 = 1
				n.speedX = n.speedX * 0.5
			end

			if v:mem(0x12E, FIELD_WORD) > 0 then
				n:mem(0x12E, FIELD_WORD, 100)
				n:mem(0x130, FIELD_WORD, v:mem(0x130, FIELD_WORD))
			end
		end
	end
	v.ai5 = math.min(v.ai5, 148)
end

function lakitu.onInitAPI()
	npcManager.registerEvent(npcID, lakitu, "onTickNPC")
end

return lakitu