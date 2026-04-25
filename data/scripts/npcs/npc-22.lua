local billy = {}

local utils = require("npcs/npcutils")

local npcID = NPC_ID

local function spawnNPC(id, v, speed)
	local n = NPC.spawn(id, v.x, v.y, v.section)
	n:mem(0x136,FIELD_BOOL, true)
	n:mem(0x12E,FIELD_WORD, 9999)
	n:mem(0x130,FIELD_WORD, v:mem(0x12C, FIELD_WORD))
	n:mem(0x132,FIELD_WORD, v:mem(0x12C, FIELD_WORD))
	
	n.y = n.y+v.height*0.5-n.height*0.5

	n.layerName = "Spawned NPCs"
	
	if v.direction == 1 then
		n.x = n.x + v.width
	else
		n.x = n.x - n.width
	end
	
	n.direction = v.direction
	n.speedX = v.direction*speed
	n.friendly = v.friendly
	
	if NPC.config[n.id].iscoin then
		n.ai1 = 1
		n.speedY = RNG.random(-4,0)
	end
	
	return n
end

function billy.onTickNPC(v)
	if Defines.levelFreeze then return end
	if v:mem(0x12A,FIELD_WORD) <= 0 then return end
	local settings = v.data._settings
	local data = v.data._basegame
	
	if (settings.projectile ~= 0 and settings.projectile ~= 17) or settings.timer ~= 20 then
		v.ai1 = 0
		if v:mem(0x12C, FIELD_WORD) > 0 then
			data.timer = (data.timer or 0)+1
		else
			data.timer = 0
		end
		
		--If the player's in a clown car
		if v:mem(0x60, FIELD_WORD) > 0 then
			--Give it a delay before it can fire, for some reason bullet bills do this when in a billy gun
			if data.clownCarTimer == nil then data.clownCarTimer = -38 end
			--If the run button is pressed and the initial delay has finished, start counting a timer up
			if data.clownCarTimer == 0 then
				if Player(v:mem(0x60, FIELD_WORD)).keys.run == KEYS_DOWN then
					data.clownCarTimer = 1
				end
			else
				--Count phase
				if data.clownCarTimer ~= 0 and data.clownCarTimer <= 38 then
					data.clownCarTimer = data.clownCarTimer + 1
				elseif data.clownCarTimer > 38 then
					data.clownCarTimer = 0
				end
			end
		else
			--Reset the timer when the player leaves the clown car
			data.clownCarTimer = nil
		end
		
		if (data.timer >= settings.timer and v:mem(0x60, FIELD_WORD) == 0 and v:mem(0x12C, FIELD_WORD) > 0) or (v:mem(0x60, FIELD_WORD) > 0 and data.clownCarTimer == 2) then
			local id = settings.projectile
			if id == 0 then
				id = 17
			end
			
			local n
			if id > 0 then
				n = spawnNPC(id, v, 8)
			else
				for i = -1,id,-1 do
					n = spawnNPC(10, v, RNG.random(4, 8))
				end
			end
			
			v.ai1 = 0
			data.timer = 0
			
			local e = Effect.spawn(10, n.x + n.width*0.5, n.y + n.height*0.5)
			e.x = e.x - e.width*0.5
			e.y = e.y - e.height*0.5
			SFX.play(22)
		end
	end
end

function billy.onInitAPI()
	NPC.registerEvent(billy, "onTickNPC")
end

return billy