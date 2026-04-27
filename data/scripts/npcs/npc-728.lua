--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
    gfxwidth = 96,
	gfxheight = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 96,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 1,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = true, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,

	--Identity-related flags. Apply various vanilla AI based on the flag:
	--iswalker = false,
	--isbot = false,
	--isvegetable = false,
	--isshoe = false,
	--isyoshi = false,
	--isinteractable = false,
	--iscoin = false,
	--isvine = false,
	--iscollectablegoal = false,
	--isflying = false,
	--iswaternpc = false,
	--isshell = false,

	--Emits light if the Darkness feature is active:
	--lightradius = 100,
	--lightbrightness = 1,
	--lightoffsetx = 0,
	--lightoffsety = 0,
	--lightcolor = Color.white,

	--Define custom properties below
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		--HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		--[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below
local CollisionSpot = {
    COLLISION_NONE = 0,
    COLLISION_TOP = 1,
    COLLISION_RIGHT = 2,
    COLLISION_BOTTOM = 3,
    COLLISION_LEFT = 4,
    COLLISION_CENTER = 5,
    COLLISION_SLOPEUPLEFT = 6,
    COLLISION_SLOPEUPRIGHT = 7,
    COLLISION_SLOPEDOWNLEFT = 8,
    COLLISION_SLOPEDOWNRIGHT = 9,
}

function CheckCollision(Loc1, Loc2) --Checks a collision between two things
    return (Loc1.y + Loc1.height >= Loc2.y) and
           (Loc1.y <= Loc2.y + Loc2.height) and
           (Loc1.x <= Loc2.x + Loc2.width) and
           (Loc1.x + Loc1.width >= Loc2.x)
end

function EasyModeCollision(Loc1, Loc2, StandOn)
    local tempEasyModeCollision = Collisionz.CollisionSpot.COLLISION_NONE
    
    if StandOn == nil then
        error("Must specify if this is being standed on or not.")
        return
    end

    if(not Defines.levelFreeze) then --Defines.levelFreeze = FreezeNPCs
        if(Loc1.y + Loc1.height - Loc1.speedY <= Loc2.y - Loc2.speedY + 10) then
            if(Loc1.speedY > Loc2.speedY or StandOn) then
                tempEasyModeCollision = CollisionSpot.COLLISION_TOP
            else
                tempEasyModeCollision = CollisionSpot.COLLISION_NONE
            end
        elseif(Loc1.x - Loc1.speedX >= Loc2.x + Loc2.width - Loc2.speedX) then
            tempEasyModeCollision = CollisionSpot.COLLISION_RIGHT
        elseif(Loc1.x + Loc1.width - Loc1.speedX <= Loc2.x - Loc2.speedX) then
            tempEasyModeCollision = CollisionSpot.COLLISION_LEFT
        elseif(Loc1.y - Loc1.speedY >= Loc2.y + Loc2.height - Loc2.speedY) then
            tempEasyModeCollision = CollisionSpot.COLLISION_BOTTOM
        else
            tempEasyModeCollision = CollisionSpot.COLLISION_CENTER
        end
    else
        if(Loc1.y + Loc1.height - Loc1.speedY <= Loc2.y + 10) then
            tempEasyModeCollision = CollisionSpot.COLLISION_TOP
        elseif(Loc1.x - Loc1.speedX >= Loc2.x + Loc2.width) then
            tempEasyModeCollision = CollisionSpot.COLLISION_RIGHT
        elseif(Loc1.x + Loc1.width - Loc1.speedX <= Loc2.x) then
            tempEasyModeCollision = CollisionSpot.COLLISION_LEFT
        elseif(Loc1.y - Loc1.speedY >= Loc2.y + Loc2.height) then
            tempEasyModeCollision = CollisionSpot.COLLISION_BOTTOM
        else
            tempEasyModeCollision = CollisionSpot.COLLISION_CENTER
        end
    end

    return tempEasyModeCollision
end

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	--registerEvent(sampleNPC, "onNPCKill")
end

function sampleNPC.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	
	--Execute main AI.
    for _,p in ipairs(Player.get()) do
        if CheckCollision(p, v) and EasyModeCollision(p, v, true) == CollisionSpot.COLLISION_TOP then
            v.speedY = 4
        else
            v.speedY = 0
        end
    end
end

--Gotta return the library table!
return sampleNPC