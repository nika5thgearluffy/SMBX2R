--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local Ninji_Guiden = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local Ninji_GuidenSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 64,
	gfxwidth = 74,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 48,
	height = 58,
	framestyle = 1,
	framespeed = 8, 
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = true,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false
	score = 5,
	jumpdelay = 32,
	preparedelay = 0,
	deaddelay = 200,
	shakedelay = 250,

	grabside=false,
	grabtop=false,
	health = 2
}

--Applies NPC settings
npcManager.setNpcSettings(Ninji_GuidenSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=10,
		[HARM_TYPE_FROMBELOW]=331,
		[HARM_TYPE_NPC]=331,
		[HARM_TYPE_PROJECTILE_USED]=331,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=331,
		[HARM_TYPE_TAIL]=331,
		[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below
local STATE_ALIVE = 0
local STATE_DEAD = 1

--Register events
function Ninji_Guiden.onInitAPI()
	npcManager.registerEvent(npcID, Ninji_Guiden, "onTickEndNPC")
	registerEvent(Ninji_Guiden, "onNPCHarm")
end

function Ninji_Guiden.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	data.timer = data.timer or 0
	data.Dead = data.Dead or 0
	local cfg = NPC.config[v.id]
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		data.state = STATE_ALIVE
		data.initialized = true
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	
	if v.collidesBlockBottom and data.state == STATE_ALIVE then
		v.speedX = 0
		data.timer = data.timer + 1
		
		if v.x < player.x then
			v.direction = DIR_RIGHT
		else
			v.direction = DIR_LEFT
		end
		v.friendly = false
		if v.direction == DIR_LEFT then
			v.animationFrame = 0
		else
			v.animationFrame = 4
		end

		if data.timer >= cfg.preparedelay and v.direction == DIR_LEFT then
			v.animationFrame = 1
		elseif data.timer >= cfg.preparedelay and v.direction == DIR_RIGHT then
			v.animationFrame = 5
		end

		if data.timer >= cfg.jumpdelay then
			if v.dontMove then
				v.speedY = -3
			else
				v.speedY = -7
			end
			SFX.play(24)
		end
	else
		v.speedX = 2.5 * v.direction
		if v.direction == DIR_LEFT then
			v.animationFrame = 2
		else
			v.animationFrame = 6
		end
		data.timer = 0
	end
	data.Shake = data.Shake or 0

	if data.state == STATE_DEAD then
		if v.collidesBlockBottom then
			data.Dead = data.Dead + 1
		end
		v.speedX = 0
		v.friendly = true
			
		if data.Dead >= cfg.deaddelay then
		   if data.Shake == 0 then
				v.x = v.x + 2
				data.Shake = 1
		   else
				v.x = v.x - 2
				data.Shake = 0
		   end
		end
			
		if data.Dead >= cfg.shakedelay then
			data.state = STATE_ALIVE
			data.Dead = 0
		end
		
		if v.direction == DIR_LEFT then
			v.animationFrame = 3
		else
			v.animationFrame = 7
		end
		
	end
	
end

function Ninji_Guiden.onNPCHarm(eventObj, npc, reason, culprit)
	local data = npc.data
	if npc.id ~= npcID then return end
	
	if not data.health then
		data.health = Ninji_GuidenSettings.health
	end
	
	if reason == 1 then
		eventObj.cancelled = true
		data.state = STATE_DEAD
		Misc.givePoints(5, npc, true)
		SFX.play(3)
	end
	
	if reason == HARM_TYPE_NPC then
	
		if culprit then
			if culprit.__type == "NPC" and (culprit.id == 13 or culprit.id == 108 or culprit.id == 17 or NPC.config[culprit.id].SMLDamageSystem) then
				data.health = data.health - 1
				culprit:kill()
			else
				data.health = 0
			end
		else
			for _,n in ipairs(NPC.getIntersecting(npc.x, npc.y, npc.x + npc.width, npc.y + npc.height)) do
				if NPC.config[n.id].SMLDamageSystem then
					data.health = data.health - 1
					SFX.play(9)
					Animation.spawn(75, n.x, n.y)
					if data.health > 0 then
						eventObj.cancelled = true
					end
				end
			end
		end
		
		if data.health > 0 then
			SFX.play(9)
			if reason ~= HARM_TYPE_SWORD and culprit then
				Animation.spawn(75, culprit.x, culprit.y)
			end
			eventObj.cancelled = true
			return
		end
		
	end

end
--Gotta return the library table!
return Ninji_Guiden