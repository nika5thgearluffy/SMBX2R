-- Code based on the engine block cannons and their AI file (npc-535.lua, npc-536.lua, cannons.lua)
-- also based some stuff on babyyoshis.lua
local yoshieggplants = {}

local npcManager = require("npcManager")
local utils = require("npcs/npcutils")

local CANNON_CONTENTS = 96
local eggPlantInfo = {}

--[[
local exSetDefs = {
	spitAngle = 22,
	projectileSpeed = 6,
	spitBlanks = false,
	dontRender = false,
	silent = false,
	projBlockCollision = false,
	initDelayTicks = 0,
	fireDelayTicks = 128,
	spawnLimit = 6,
}
--]]

local spitSFX = Misc.resolveSoundFile("extended/eggplant-spit")
local blankSFX = Misc.resolveSoundFile("extended/eggplant-blank")

function yoshieggplants.onInitAPI()
	registerEvent(yoshieggplants, "onNPCHarm")
end


--*************************************************************************
--*
--*								Helper functions
--*
--*************************************************************************


-- Function: areaObstructed
-- Description: checks if the given area is obstructed by players, npcs, or blocks
-- Arguments: x1,y1,x2,y2
--	x1,y1 = top left corner of area to check
--	x2,y2 = bottom right corner
-- Return:
--	true if the area is obstructed; false otherwise
local function areaObstructed(x1,y1,x2,y2,shouldOnlyCheckPlayer)
	if #Player.getIntersecting(x1,y1,x2,y2) > 0 then
		return true
	end

	if shouldOnlyCheckPlayer then return false end

	for _,v in ipairs(NPC.getIntersecting(x1,y1,x2,y2)) do
		if not v.isHidden then
			return true
		end
	end
	for _,v in ipairs(Block.getIntersecting(x1,y1,x2,y2)) do
		if not v.isHidden then
			return true
		end
	end
	return false
end


local function forceUp(npc)
	local data = npc.data._basegame
	local epInfo = eggPlantInfo[npc.id]

	if  not epInfo.horizontal  then
		
		-- Force to up if grabbed, thrown or contained
		if  npc:mem(0x12C, FIELD_WORD) ~= 0      --Grabbed 
		    or npc:mem(0x136, FIELD_BOOL)        --Thrown
		    or npc:mem(0x138, FIELD_WORD) > 0    --Contained within
		then
			npc.direction = DIR_LEFT
			data.initDirection = DIR_LEFT
		end
	end

end


--*************************************************************************
--*
--*							Egg-Plant Settings
--*
--*************************************************************************

--- These properties can be set in npc.txt files for Egg-Plants.
-- @table plant_npc.txt
-- @field containednpc The ID of the NPC to fire if the individual NPC does not provide one. (Default: 134 (SMB2 Bomb))

yoshieggplants.eggplantSharedSettings = {
    width=32,
    height=32,

    speed=1,
    
    score=0,
    
    frames=9,
    framestyle=1,
    framespeed=6,
    
    playerblock=false,
    playerblocktop=false,
    npcblock=false,
    npcblocktop=false,
    
    grabside=false,
    grabtop=false,
    
    jumphurt=true,
    nohurt=true,
    
    noblockcollision=false,
    cliffturn=false,
	staticdirection=true,
    
    foreground=false,
    nofireball=true,
    noiceball=true,
	noyoshi=true,
    nogravity=false,
    nowaterphysics = true,

	notcointransformable = true,

    harmlessgrab=true,
    harmlessthrown=true,
    spinjumpsafe=false,
    
    ignorethrownnpcs = true,

	isstationary=true,
    isshell=false,
    isinteractable=false,
    iscoin=false,
    isvine=false,
    iscollectablegoal=false,
    isflying=false,
    iswaternpc=false,
    isshoe=false,
    isyoshi=false,
    isbot=false,
    isvegetable=false,
    iswalker=false,
    
	-- custom properties
	spitframes = 5,
	spitoffset = 0,
	containednpc = CANNON_CONTENTS,
}

--*************************************************************************
--*
--*							Plant Event Handlers
--*
--*************************************************************************


function yoshieggplants.register(id, horizontal, isAngy, crushEffect)

	eggPlantInfo[id] = {
		horizontal = horizontal,
		isAngy = isAngy
	}
	npcManager.registerHarmTypes(id,
	{
		HARM_TYPE_LAVA,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_NPC
	},
	{
		[HARM_TYPE_NPC]={id=crushEffect},
		[HARM_TYPE_PROJECTILE_USED]={id=crushEffect},
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
	});

end


function yoshieggplants.onStartPlant(npc)
	local parsedData = npc.data
	local data = parsedData._basegame
	local cfg = NPC.config[npc.id]
	
	if npc.ai1 > 0 then
		data.containednpc = npc.ai1
	else
		data.containednpc = cfg.containednpc
	end

	local settings = parsedData._settings


	settings.fireDelayTicks = (settings.fireDelayTicks or 128) - (settings.initDelayTicks  or  0)
	
	data.section = npc:mem(0x146, FIELD_WORD)
	data.initDirection = npc.direction
	--data.initFriendly = npc.friendly
	--npc.friendly = true

	data.frame = 0
	data.frameTimer = 0
    data.spitting = false

	data.spawnedRefs = {}
	
	data.fireTimer = 0
	data.init = true
end

--horizontal is always going to be false, maybe I should've reserved more IDs so I could've set this thing up even more like the cannons...
function yoshieggplants.onTickPlant(npc)
	if  npc:mem(0x12A, FIELD_WORD) <= 0
	or  Defines.levelFreeze  then  
		return
	end

	-- Initialize data
	local data = npc.data._basegame
	if not data.init then
		yoshieggplants.onStartPlant(npc)
	end
	local cfg = NPC.config[npc.id]
	local epInfo = eggPlantInfo[npc.id]


	-- Stop when landing from a throw
	if  npc:mem(0x136, FIELD_BOOL)  then

		if  npc.collidesBlockBottom  then
			npc.speedX = 0
		end
	end


	-- Store player momentum for projectiles
	local playerSpeed = vector.zero2
	local pGrabIdx = npc:mem(0x12C, FIELD_WORD)
	if  pGrabIdx > 0  then
		local p = Player(npc:mem(0x12C, FIELD_WORD))
		playerSpeed = vector(p.speedX, p.speedY)
	end

	-- Force up if grabbed, held or thrown
	forceUp(npc)

	-- No gravity if facing down
	if  not epInfo.horizontal  and  data.initDirection == DIR_RIGHT  and  not cfg.nogravity  then
		npc.speedY = -Defines.npc_grav
	end


	-- Animation
	data.frameTimer = (data.frameTimer + 1) % cfg.framespeed
	if data.frameTimer == 0 then
		data.frame = (data.frame + 1) % cfg.frames
		
		if  not data.spitting  then
			data.frame = data.frame % (cfg.frames - cfg.spitframes)
		elseif  data.frame == 1  then
			data.spitting = false
		end
	end

	local settings = npc.data._settings


	-- Clear out despawned NPC references
	for  i=#data.spawnedRefs,1,-1  do
		if  data.spawnedRefs[i] ~= nil  and  not data.spawnedRefs[i].isValid  then
			table.remove(data.spawnedRefs,i)
		end
	end


	-- Ready to fire
	data.fireTimer = (data.fireTimer + 1)
	if  data.fireTimer > 0  then 
		data.fireTimer = data.fireTimer % settings.fireDelayTicks
	end

	if data.fireTimer == 0 then

		local projectile,puffX,puffY
		if  not epInfo.horizontal  then -- vertical cannon
			puffX = npc.x + 0.5 * npc.width

			projectile = NPC.spawn(data.containednpc,npc.x+0.5*npc.width,npc.y,data.section,false,true)

			if npc.direction == DIR_LEFT then -- facing up
				puffY = npc.y - 8 - cfg.spitoffset
				projectile.speedY = -10 -- speed values based on comparison with vanilla generators;  this speed gets overridden later
				projectile.y = projectile.y - projectile.height + 16 - cfg.spitoffset
			else -- facing down
				puffY = npc.y + npc.height + 8 + cfg.spitoffset
				projectile.speedY = 8 -- this speed gets overridden later
				projectile.y = npc.y + npc.height - 16 + cfg.spitoffset
			end
		else -- horizontal cannon
			puffY = npc.y + 0.5 * npc.height

			projectile = NPC.spawn(data.containednpc,npc.x+0.5*npc.width,npc.y,data.section)

			projectile.y = npc.y + (npc.height - projectile.height) * 0.5
			if npc.direction == DIR_LEFT then
				puffX = npc.x - 8 - cfg.spitoffset
				projectile.speedX = -7 -- this speed gets overridden later
				if (not NPC.config[projectile.id].staticdirection) then
					projectile.direction = DIR_LEFT
				end
				projectile.x = npc.x - projectile.width - cfg.spitoffset
			else
				puffX = npc.x + npc.width + 8 + cfg.spitoffset
				projectile.speedX = 7 -- this speed gets overridden later
				if (not NPC.config[projectile.id].staticdirection) then
					projectile.direction = DIR_RIGHT
				end
				projectile.x = npc.x + npc.width + cfg.spitoffset
			end
		end
		projectile.isHidden = true
		projectile.layerName = "Spawned NPCs"
		projectile.friendly = npc.friendly--data.initFriendly
		local pCfg = NPC.config[projectile.id]


		local showSpitAttempt = true

		-- If the npc cannot be spawned, hide it...?
		--if   not areaObstructed(projectile.x,projectile.y,projectile.x+projectile.width,projectile.y+projectile.height, pCfg.noblockcollision)  
		if  #data.spawnedRefs < (settings.spawnLimit  or  6)  then
			projectile.isHidden = false
			projectile.noblockcollision = (not settings.projBlockCollision)
			projectile:mem(0x136, FIELD_BOOL, epInfo.isAngy)
			
			local halfAngle = (settings.spitAngle  or  22)*0.5
			local spitVector = vector.v2(projectile.speedX, projectile.speedY)
			local rotated = spitVector:rotate(RNG.random(-halfAngle, halfAngle)):normalise() * settings.projectileSpeed

			projectile.speedX = rotated.x + playerSpeed.x
			projectile.speedY = rotated.y --+ math.min(playerSpeed.y, 0)

			table.insert(data.spawnedRefs, projectile)

			if  not settings.silent  then
				SFX.play(spitSFX)
			end

		-- Unsuccessful spit
		elseif  settings.spitBlanks  then
			-- spawn the puff effect and center it
			local anim = Animation.spawn(10,puffX,puffY)
			anim.x = anim.x - 0.5 * anim.width
			anim.y = anim.y - 0.5 * anim.height
			anim.speedY = 4*npc.direction

			if  not settings.silent  then
				SFX.play(blankSFX)
			end

		-- If not supposed to spit blanks, hide all traces of the attempt
		else
			showSpitAttempt = false
		end


		-- Animate the spit attempt
		if  showSpitAttempt  then
			data.spitting = true
			data.frameTimer = 1
			data.frame = cfg.frames - cfg.spitframes
		end
	end
end

function yoshieggplants.onTickEndPlant(npc)

	if  npc:mem(0x12A, FIELD_WORD) <= 0
	or  Defines.levelFreeze  then  
		return
	end

	-- Initialize data
	local data = npc.data._basegame
	if not data.init then
		yoshieggplants.onStartPlant(npc)
	end
	local cfg = NPC.config[npc.id]
	local epInfo = eggPlantInfo[npc.id]


	-- Don't Move facing correction
	if  npc.dontMove  then
		npc.direction = data.initDirection
	end


	-- Move with layers
	if  epInfo.horizontal  or  (not epInfo.horizontal  and  npc.direction == DIR_RIGHT)  or  cfg.nogravity  then
		utils.applyLayerMovement(npc)
	end
	--[[
	local lsx,lsy = utils.getLayerSpeed(npc)
	if  not npc.collidesBlockBottom  or  cfg.nogravity  then
		npc.x = npc.x + lsx
		--npc.y = npc.y + lsy
	end
	--]]
end

function yoshieggplants.onDrawPlant(npc)
	if npc:mem(0x12A, FIELD_WORD) > 0 then
		
		local data = npc.data._basegame
		if not data.init then return end

		local settings = npc.data._settings

		if  settings.dontRender == true  then
			npc.animationFrame = -1
		else
			npc.animationFrame = data.frame
			forceUp(npc)

			local cfg = NPC.config[npc.id]

			utils.drawNPC(npc, {
				frame = utils.getFrameByFramestyle(npc, {direction=data.initDirection, frame=data.frame}),
				applyFrameStyle = false
				-- dunno what else I need to put here to make it properly emerge from a block so I'm putting that off for now
			})
		end
		utils.hideNPC(npc)
	end
end


function yoshieggplants.onNPCHarm(eventObj, npc, killReason, culprit)
	if  eggPlantInfo[npc.id] == nil  or  npc.isGenerator  then  return  end


	-- Only die by harm type NPC if crushed
	local wasCrushed = (((npc:mem(0x0A, FIELD_WORD) > 0 and npc:mem(0x0E, FIELD_WORD) > 0) or (npc:mem(0x0C, FIELD_WORD) > 0 and npc:mem(0x10, FIELD_WORD) > 0)) and npc:mem(0x12, FIELD_WORD) > 0)

	if  killReason == HARM_TYPE_NPC  and  not wasCrushed  then
		eventObj.cancelled = true
	end

	-- Get launched from block bops
	if  killReason == HARM_TYPE_FROMBELOW  then
		eventObj.cancelled = true
		npc.speedY = -8
		SFX.play(9)
	end
end


return yoshieggplants
