--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local Buzz = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local BuzzSettings = {
id = npcID,
	--Sprite size
	gfxheight = 64,
	gfxwidth = 60,
	width = 60,
	height = 64,
	--Frameloop-related
	frames = 4,
	framestyle = 0,
	framespeed = 8,
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = true,
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	grabside=false,
	grabtop=false,
	score = 4,
	muted = false,
	jumpHeight = 7,
	waitTime = 56,
	health = 2
}

--Applies NPC settings
npcManager.setNpcSettings(BuzzSettings)

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
		[HARM_TYPE_JUMP]=316,
		[HARM_TYPE_FROMBELOW]=316,
		[HARM_TYPE_NPC]=316,
		[HARM_TYPE_PROJECTILE_USED]=316,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=316,
		[HARM_TYPE_TAIL]=10,
		[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_OFFSCREEN] = {id=316, speedY=-2.5},
		[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below
local STATE_INACTIVE = 0
local STATE_DED = 1

--Register events
function Buzz.onInitAPI()
	npcManager.registerEvent(npcID, Buzz, "onTickEndNPC")
	registerEvent(Buzz, "onNPCHarm")
end

function Buzz.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local cfg = NPC.config[v.id]
	local plr = Player.getNearest(v.x + v.width / 2, v.y + v.height / 2)
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.deathTimer = 0
		return
	end

	--Initialize
	if not data.initialized then
		data.state = STATE_INACTIVE
		data.initialized = true
		data.timer = data.timer or 0
		data.deathTimer = data.deathTimer or 0
	end
	
	--Execute main AI. This template just jumps when it touches the ground.
	if data.state == STATE_INACTIVE then
		if v.collidesBlockBottom then
			v.speedX = 0
			data.timer = data.timer + 1
			v.friendly = false
			
			v.animationFrame = 0
			if plr.x < v.x then
				v.direction = DIR_LEFT
			else
				v.direction = DIR_RIGHT
			end
			if data.timer >= cfg.waitTime then
				v.speedY = -cfg.jumpHeight
				SFX.play(24)
				
			end
		else
			
			v.speedX = 2.5 * v.direction
			
			v.animationFrame = math.floor((lunatime.tick() / 8) % 2) + 1
			
			data.timer = 0
		end
	
	else
		v.animationFrame = 3
		v.speedX = 0
		v.friendly = true
		if v.collidesBlockBottom then
			data.deathTimer = data.deathTimer + 1
			if data.deathTimer >= 48 then
				v:kill(HARM_TYPE_OFFSCREEN)
				if not NPC.config[v.id].muted then
					SFX.play("sound/extended/sml1-death.ogg")
				else
					SFX.play(4)
				end
			end
		end
	end
	
end

function Buzz.onNPCHarm(eventObj,v,reason,culprit)
	local data = v.data
	if v.id ~= npcID then return end
	
	if not data.health then
		data.health = BuzzSettings.health
	end
	
	if reason == HARM_TYPE_JUMP then
		eventObj.cancelled = true
		Misc.givePoints(4, v, true)
		SFX.play(2)
		v.data.state = STATE_DED
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
			for _,n in ipairs(NPC.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
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
return Buzz