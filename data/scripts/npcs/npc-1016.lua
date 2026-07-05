local npcManager = require("npcManager")
local whistle = require("npcs/ai/whistle")
local friendlyNPC = require("npcs/ai/friendlies")

local friendlies = {}
local npcID = NPC_ID

local defaults = {frames = 4, 
				  framestyle = 1, 
				  jumphurt = 1,
				  ignorethrownnpcs = 1,
				  nofireball=1,
				  noiceball=1,
				  noyoshi=1,
				  grabside=0,
				  grabtop=0,
				  isshoe=0,
				  isyoshi=0,
				  isstationary = true,
				  nowalldeath = true,
				  nohurt=1,
				  score = 0,
				  spinjumpsafe=0}

local megan = npcManager.setNpcSettings(table.join(
				 {id = npcID,
				  gfxwidth = 32, 
                  gfxheight = 52, 
				  ignorethrownnpcs = 0,
				  width = 32, 
				  height = 48, },
				  defaults))

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_NPC,
		HARM_TYPE_LAVA,
	},
	{
		[HARM_TYPE_PROJECTILE_USED] = 10,
		[HARM_TYPE_NPC] = 10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
	}
)

friendlyNPC.register(npcID)

function friendlies.onInitAPI()
	npcManager.registerEvent(npcID, friendlies, "onTickEndNPC")
    npcManager.registerEvent(npcID, friendlies, "onDrawNPC")
end

local animationOnFloor = {0,1}

function friendlies.onTickEndNPC(v)
	if Defines.levelFreeze or v:mem(0x12A, FIELD_WORD) <= 0 then return end
end

function friendlies.onDrawNPC(v)
    if Misc.isPaused() then return end

    local data = v.data
    
    --If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end
    
    if not data.initialized then
        data.animationTimer = 0
        data.animationArray = 0
        data.animationFramed = 1

        data.hasJumped = 0
        data.jumpedOnce = false
        data.jumpedTwice = false
        data.landed = false

        data.initialized = true
    end
    data.animationTimer = data.animationTimer + 1
    Text.print(data.animationTimer, 100, 100)
    if data.animationTimer < 35 then
        v.animationFrame = 0
    end
    if data.animationTimer == 2 then
        data.landed = false
        data.hasJumped = 0
    end
    if data.animationTimer >= 35 and data.animationTimer < lunatime.toTicks(1) then
        data.animationArray = data.animationTimer % 8
        if data.animationArray >= 7 then
            data.animationFramed = data.animationFramed + 1
        end
        if data.animationFramed > 2 then
            data.animationFramed = 1
        end
        v.animationFrame = animationOnFloor[data.animationFramed]
    end
    if data.animationTimer >= lunatime.toTicks(1) and data.animationTimer < lunatime.toTicks(1.3) then
        v.animationFrame = 0
    end
    if data.animationTimer >= lunatime.toTicks(1.3) and data.animationTimer < lunatime.toTicks(1.4) then
        v.animationFrame = 2
    end
    if data.animationTimer >= lunatime.toTicks(1.4) then
        if v.collidesBlockBottom then
            if data.hasJumped == 0 and not data.jumpedOnce then
                data.hasJumped = 1
                v.animationFrame = 2
                v.speedY = -7
                data.jumpedOnce = true
            elseif data.hasJumped == 1 and not data.jumpedTwice then
                data.hasJumped = 2
                v.animationFrame = 2
                v.speedY = -7
                data.jumpedTwice = true
            elseif data.hasJumped == 2 and not data.landed then
                data.landed = true
                data.animationTimer = 0
                data.jumpedOnce = false
                data.jumpedTwice = false
            end
        end
        if v.speedY ~= 0 then
            v.animationFrame = 3
        end
    end
end

return friendlies