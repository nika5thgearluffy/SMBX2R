--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

local rad, sin, cos, pi = math.rad, math.sin, math.cos, math.pi

--Create the library table
local chicken = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local chickenSettings = {
	id = npcID,
	gfxheight = 38,
	gfxwidth = 42,
	width = 42,
	height = 38,
	frames = 2,
	framestyle = 1,
	framespeed = 8,
	speed = 1.8,
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = false,
	--Various interactions
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,
	score = 4,

	grabside=false,
	grabtop=false,
	radius = 64,
}

--Applies NPC settings
npcManager.setNpcSettings(chickenSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=334,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=334,
		[HARM_TYPE_PROJECTILE_USED]=334,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=334,
		[HARM_TYPE_TAIL]=334,
		[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below


--Register events
function chicken.onInitAPI()
	npcManager.registerEvent(npcID, chicken, "onTickNPC")
end

function chicken.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local cfg = NPC.config[v.id]
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.attackTimer = 0
		return
	end
	
	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	then
		data.attackTimer = -1
	end
	
	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.radius = cfg.radius or 64
		data.attackTimer = data.attackTimer or 0
	end
	
	v.speedX = cfg.speed * v.direction
	
	if data.attackTimer <= 1 then
		v.speedY = 0
	end
	
	if data.attackTimer > 0 then 
		data.attackTimer = data.attackTimer - 1
		if v.y == v.spawnY and data.attackTimer < 63 then
			data.attackTimer = -1
		else
			data.w = 2 * pi/65
			if data.up then
				v.speedY = 50 * -data.w * cos(data.w*data.attackTimer / 2)
			else
				v.speedY = 50 * data.w * cos(data.w*data.attackTimer / 2)
			end
		end
	end
	
	if math.abs(plr.x-v.x)<=data.radius then
		if data.attackTimer == 0 and v:mem(0x138, FIELD_WORD) == 0 then
			v.spawnY = v.y
			data.attackTimer = 64
			if plr.y >= v.y then
				data.up = true
			else
				data.up = false
			end
		end
	end
	
end

--Gotta return the library table!
return chicken