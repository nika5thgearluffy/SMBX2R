local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local verletrope = require("verletrope")
local lineguide = require("lineguide")

local thwomps = require("npcs/ai/thwomps")
local berries = require("npcs/ai/berries")

local chainChomp = {}


chainChomp.postIDList = {}
chainChomp.postIDMap  = {}

chainChomp.chompIDList = {}
chainChomp.chompIDMap  = {}


-- Map of NPC ID's that, when attached to a pole, will have their X/Y directly set in addition to their speed.
-- Mostly for NPC's that force their speed.
chainChomp.forceMoveMap = table.map{
    600,601,602,603, -- barrels
    437,295,435,432, -- thwomps
    564,
}



local CHOMPSTATE_PATROL  = 0
local CHOMPSTATE_PREPARE = 1
local CHOMPSTATE_LUNGE   = 2
local CHOMPSTATE_RETURN  = 3
local CHOMPSTATE_SWIM    = 4

local CHAINBEHAVIOUR_NORMAL = 0
local CHAINBEHAVIOUR_STICK  = 1 -- when at the edge of the chain, the attached NPC will stay more still
local CHAINBEHAVIOUR_FIXED  = 2 -- has the chains just follow after the NPC at a fixed distance


local yoshiForcedStates = table.map{5,6}
local staticForcedStates = table.map{1,2,3,4,208}


local function attachedNPCCanStay(a)
    return (
        a ~= nil and a.isValid
        and (a.id ~= 263 or a.spawnId == a.id) -- frozen
        and a:mem(0x12C,FIELD_WORD) == 0 -- held by the player
        and not yoshiForcedStates[a:mem(0x138,FIELD_WORD)] -- on yoshi's tongue/in yoshi's mouth
        and a.id ~= 0 -- attached bubbles turn into NPC 0 when they pop
    )
end

local function stopLineguideAttach(v)
    local lineguideData = v.data._basegame.lineguide

    if lineguideData ~= nil then
        lineguideData.state = lineguide.states.NORMAL
        lineguideData.attachCooldown = 2

        --Text.print("A",v.x-camera.x,v.y-camera.y)
    end
end

local function hasNoBlockCollision(v)
    return (v.noblockcollision or NPC.config[v.id].noblockcollision)
end


local function getHoldingPlayer(v)
    if yoshiForcedStates[v.forcedState] then
        if v.forcedCounter1 > 0 then
            return Player(v.forcedCounter1)
        end

        return nil
    end

    return v.heldPlayer
end

local function getHoldingNPC(p)
    if p:mem(0xB8,FIELD_WORD) > 0 and p:mem(0xB8,FIELD_WORD) <= NPC.count() then
        return NPC(p:mem(0xB8,FIELD_WORD) - 1)
    end

    return p.holdingNPC
end


local function initialiseChains(v,data,config,chainCount,hasRope)
    local startPos = vector(v.x + v.width*0.5,v.y + v.height)

    if hasRope then
        local settings = v.data._settings

        local count = chainCount + 1
        if data.attachedNPC ~= nil then
            count = count + 1
        end

        local endPos = startPos + settings.attachedSpawnOffset

        data.chainsRope = verletrope.Rope(startPos,endPos,count,10,Defines.npc_grav,true)
        data.chainsRope.segmentLength = settings.chainDistance
    else
        startPos.y = v.y + v.height*0.5
    end

    -- Make separate chains for holding extra data and whatnot
    data.chains = {}

    for i = 1,chainCount do
        local chain = {}

        chain.effectID = config.chainEffectID
        chain.effectConfig = Effect.config[chain.effectID][1]

        chain.width = chain.effectConfig.width
        chain.height = chain.effectConfig.height

        if hasRope then
            chain.ropeSegment = data.chainsRope.segments[i + 1]
            chain.position = chain.ropeSegment.position
        else
            chain.position = startPos + vector(0,chain.height*0.5)
        end

        table.insert(data.chains,chain)
    end
end


local function initialisePost(v,data,config,settings)
    v.collisionGroup = "chainChomp ".. v.uid

    if not data.attachedNPCSpawned and v.ai1 > 0 then
        local attachedConfig = NPC.config[v.ai1]

        data.attachedNPC = NPC.spawn(v.ai1,v.x + v.width*0.5 + settings.attachedSpawnOffset.x,v.y + v.height - attachedConfig.height*0.5 + settings.attachedSpawnOffset.y,v.section,true,true)

        data.attachedNPC.direction = v.direction
        data.attachedNPC.spawnDirection = v.direction

        if v.spawnId == 0 then
            data.attachedNPC.spawnId = 0
        end

        data.attachedNPC.layerName = v.layerName
        data.attachedNPC.friendly = v.friendly

        data.attachedNPC.collisionGroup = v.collisionGroup

        data.attachedNPC.data._basegame.attachedPost = v

        data.attachedIsOnEdge = false

        data.attachedNPCSpawned = true

        stopLineguideAttach(data.attachedNPC)
    end

    if settings.hasChainsIfNoNPC or data.attachedNPC then
        initialiseChains(v,data,config,settings.chainCount,true)
    else
        initialiseChains(v,data,config,0,true)
    end

    data.chainBehaviour = CHAINBEHAVIOUR_NORMAL

    data.lastPos = vector(v.x + v.width*0.5,v.y + v.height)
    data.translation = vector.zero2

    data.initialized = true
end


local function npcIsSolid(v,n)
    if n.despawnTimer <= 0 then
        return false
    end

    local config = NPC.config[n.id]

    if not config.npcblock and not config.playerblocktop then
        return false
    end

    if not Misc.groupsCollide[v.collisionGroup][n.collisionGroup] then
        return false
    end

    if n.id == 58 or n.id == 67 or n.id == 68 or n.id == 69 or n.id == 70 then -- hardcoded nonsense
        return true
    end

    if n:mem(0x12C,FIELD_WORD) > 0 or n:mem(0x136,FIELD_BOOL) or n:mem(0x138,FIELD_WORD) > 0 then
        return false
    end

    if (n.id == 45 and n.ai1 == 1) or ((n.id == 46 or n.id == 212) and n.ai1 == 1) then -- more hardcoded nonsense
        return false
    end
    
    return true
end

local function solidIsSemisolid(solid)
    if type(solid) == "Block" then
        return Block.SEMISOLID_MAP[solid.id]
    else
        local config = NPC.config[solid.id]

        return (config.playerblocktop and not config.npcblock)
    end
end


local function getSolids(v,x1,y1,x2,y2)
    local solids = {}

    for _,b in Block.iterateIntersecting(x1,y1,x2,y2) do
        if not b.isHidden and not b:mem(0x5A,FIELD_BOOL) then
            local config = Block.config[b.id]

            if not config.passthrough and (config.npcfilter ~= v.id and config.npcfilter >= 0) and Misc.groupsCollide[v.collisionGroup][b.collisionGroup] then
                table.insert(solids,b)
            end
        end
    end

    for _,n in NPC.iterateIntersecting(x1,y1,x2,y2) do
        if n ~= v and npcIsSolid(v,n) then
            table.insert(solids,n)
        end
    end

    return solids
end

--[[local function shouldSnapChain(v,data,config)
    local a = data.attachedNPC

    if not a.collidesBlockBottom and not a.collidesBlockUp and not a.collidesBlockLeft and not a.collidesBlockRight then
        return false
    end

    local attachedConfig = NPC.config[a.id]

    if (attachedConfig.noblockcollision or a.noblockcollision) and not a:mem(0x136,FIELD_BOOL) then
        return false
    end


    local lineCastStart = data.chainsRope.segments[#data.chainsRope.segments - 1].position
    local lineCastEnd   = vector(a.x + a.width*0.5,a.y + a.height*0.5)

    local x1 = math.min(lineCastStart.x,lineCastEnd.x)
    local y1 = math.min(lineCastStart.y,lineCastEnd.y)
    local x2 = math.max(lineCastStart.x,lineCastEnd.x)
    local y2 = math.max(lineCastStart.y,lineCastEnd.y)

    local solids = getSolids(a,x1,y1,x2,y2)

    --Colliders.Box(x1,y1,x2 - x1,y2 - y1):draw()

    if solids[1] == nil then
        return false
    end

    -- Is there a direct line between the NPC and its post?
    for _,solid in ipairs(solids) do
        local hit,hitPoint,hitNormal = Colliders.linecast(lineCastStart,lineCastEnd,solid)

        if hit and (hitNormal.y < 0 or not solidIsSemisolid(solid)) then
            -- Line is blocked by a solid; snap!
            return true
        end
    end

    return false
end]]


local function createChainEffects(chains)
    for i = 1,#chains do
        local chain = chains[i]
        local e = Effect.spawn(chain.effectID,chain.position.x,chain.position.y)

        e.x = e.x - e.width*0.5
        e.y = e.y - e.height

        chains[i] = nil
    end
end

local function snapChains(v,data,config)
    local a = data.attachedNPC

    if a ~= nil and a.isValid then
        if chainChomp.chompIDMap[a.id] then
            local attachedConfig = NPC.config[a.id]
            local attachedData = a.data._basegame

            a.speedX = attachedConfig.escapedSpeedX*a.direction
            a.speedY = attachedConfig.escapedSpeedY

            a.noblockcollision = false

            attachedData.chains = data.chains
            data.chains = {}

            SFX.play(2)
        else
            if a.collisionGroup == v.collisionGroup then
                a.collisionGroup = ""
            end
            
            a.speedX = 0
            a.speedY = 0
        end

        a.layerName = "Spawned NPCs"
    end

    if #data.chains > 0 then
        createChainEffects(data.chains)
        SFX.play(2)
    end
    
    data.attachedNPC = nil
end


local function getPostTranslation(v,data,config)
    local pos = vector(v.x + v.width*0.5,v.y + v.height)

    if data.chainBehaviour ~= CHAINBEHAVIOUR_NORMAL then
        return (pos - data.lastPos)
    end

    local holdingPlayer = getHoldingPlayer(v)

    if holdingPlayer == nil then
        return vector.zero2
    end

    if holdingPlayer.standingNPC == data.attachedNPC then
        return vector.zero2
    end

    if holdingPlayer.forcedState == FORCEDSTATE_NONE then
        pos.x = pos.x - holdingPlayer.speedX

        if holdingPlayer:mem(0x48,FIELD_WORD) == 0 and holdingPlayer:mem(0x176,FIELD_WORD) == 0 then
            pos.y = pos.y - holdingPlayer.speedY
        end
    end

    return (pos - data.lastPos)
end


local function updateChainsPost(v,data,config,settings)
    local chainCount = #data.chains

    if chainCount <= 0 then
        return
    end

    local a = data.attachedNPC
    local hasCollision = (not hasNoBlockCollision(v))


    if v:mem(0x1C,FIELD_WORD) > 0 then
        data.chainsRope.gravity = Defines.npc_grav*0.2
    else
        data.chainsRope.gravity = Defines.npc_grav
    end


    if staticForcedStates[v:mem(0x138,FIELD_WORD)] then
        for _,segment in ipairs(data.chainsRope.segments) do
            segment.position.x = v.x + v.width*0.5
            segment.position.y = v.y + config.height - 2
            segment.oldpos = segment.position
        end

        for index,chain in ipairs(data.chains) do
            chain.position = chain.ropeSegment.position
        end
        
        return
    end


    local attachedIsValid = attachedNPCCanStay(a)

    if attachedIsValid then
        local segment = data.chainsRope.segments[#data.chainsRope.segments]
        
        --a.x = a.x + data.translation.x
        --a.y = a.y + data.translation.y

        segment.position = vector(a.x + a.width*0.5,a.y + a.height)
        segment.oldpos = segment.position + vector.down2*data.chainsRope.gravity - vector(a.speedX,a.speedY)

        hasCollision = (hasCollision and not hasNoBlockCollision(a))
    end


    local segmentCount = #data.chainsRope.segments
    local originPos = vector(v.x + v.width*0.5,v.y + v.height)

    for i,segment in ipairs(data.chainsRope.segments) do
        if i > 1 then
            if data.chainBehaviour == CHAINBEHAVIOUR_FIXED and attachedIsValid and i < segmentCount then
                local t = (i - 1)/(segmentCount - 1)

                segment.position = originPos + (vector(a.x + a.width*0.5,a.y + a.height) - originPos)*t
                segment.oldpos = segment.position

                hasCollision = false
            elseif i < segmentCount or data.chainBehaviour == CHAINBEHAVIOUR_FIXED then
                segment.position = segment.position + data.translation
                segment.oldpos = segment.oldpos + data.translation
            end
        else
            segment.position = originPos
        end
    end

    data.chainsRope:update()


    local solidsX1 = math.huge
    local solidsY1 = math.huge
    local solidsX2 = -math.huge
    local solidsY2 = -math.huge

    for index,chain in ipairs(data.chains) do
        local segment = chain.ropeSegment

        solidsX1 = math.min(solidsX1,segment.position.x,chain.position.x)
        solidsY1 = math.min(solidsY1,segment.position.y,chain.position.y)
        solidsX2 = math.max(solidsX2,segment.position.x,chain.position.x)
        solidsY2 = math.max(solidsY2,segment.position.y,chain.position.y)
    end


    local solids = getSolids(v,solidsX1 - 8,solidsY1 - 8,solidsX2 + 8,solidsY2 + 8)

    for _,chain in ipairs(data.chains) do
        local segment = chain.ropeSegment
        
        if hasCollision then
            local velocity = (segment.position - chain.position) + data.translation
            local lineCastStart = chain.position - vector(0.01,1)

            local finalHitPoint,finalHitNormal
            local maxSqrtDist
            
            for _,solid in ipairs(solids) do
                local hit,hitPoint,hitNormal,_ = Colliders.linecast(lineCastStart,segment.position,solid)

                if hit then
                    local sqrDist = (hitPoint - lineCastStart).sqrlength

                    if (hitNormal.y < 0 or not solidIsSemisolid(solid)) and (maxSqrtDist == nil or sqrDist < maxSqrtDist) then
                        finalHitPoint = hitPoint
                        finalHitNormal = hitNormal
                        maxSqrtDist = sqrDist
                    end
                end
            end

            --Graphics.drawLine{start = lineCastStart,stop = segment.position,sceneCoords = true,color = Color.red}

            if finalHitPoint ~= nil then
                if finalHitNormal.y < 0 then
                    segment.oldpos.x = math.lerp(segment.oldpos.x,segment.position.x,0.25) -- slow down
                    segment.position.y = finalHitPoint.y
                    segment.oldpos.y = segment.position.y
                elseif finalHitNormal.y > 0 then
                    segment.position.y = finalHitPoint.y
                    segment.oldpos.y = segment.position.y
                else
                    segment.position.x = finalHitPoint.x
                    segment.oldpos.x = segment.position.x
                end
            end
        end

        chain.position = segment.position
    end
end

local function drawChains(v,data,config,priority)
    for _,chain in ipairs(data.chains) do
        local image = Graphics.sprites.effect[chain.effectID].img
        local x = chain.position.x - chain.width*0.5
        local y = chain.position.y - chain.height

        Graphics.drawImageToSceneWP(image,x,y,0,0,chain.width,chain.height,priority - 1)
    end
end


function chainChomp.registerPost(npcID)
    npcManager.registerEvent(npcID, chainChomp, "onTickEndNPC", "onTickEndPost")
    npcManager.registerEvent(npcID, chainChomp, "onDrawNPC", "onDrawPost")

    table.insert(chainChomp.postIDList,npcID)
    chainChomp.postIDMap[npcID] = true

    lineguide.registerNPCs(npcID)

    thwomps.registerNPCInteraction(npcID,function(v,thwomp,strong)
        snapChains(v,v.data._basegame,NPC.config[v.id])

        local e = Effect.spawn(10,v.x + v.width*0.5,v.y + v.height*0.5)

        e.x = e.x - e.width *0.5
        e.y = e.y - e.height*0.5

        v:kill(HARM_TYPE_VANISH)
    end)
end

function chainChomp.onTickEndPost(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if v.despawnTimer <= 0 then
        if attachedNPCCanStay(data.attachedNPC) and data.attachedNPC.despawnTimer > 0 then
            data.attachedNPC.despawnTimer = 0
            data.attachedNPC:mem(0x124,FIELD_BOOL,false)
        end
        
		data.initialized = false
		return
	end

    local settings = v.data._settings
    local config = NPC.config[v.id]

	if not data.initialized then
		initialisePost(v,data,config,settings)
	end

    local holdingPlayer = getHoldingPlayer(v)
    local a = data.attachedNPC

    if hasNoBlockCollision(v) and v:mem(0x12C,FIELD_WORD) == 0 and v:mem(0x138,FIELD_WORD) == 0 then
        v.speedX,v.speedY = npcutils.getLayerSpeed(v)
    end

    if v:mem(0x138,FIELD_WORD) == 6 then -- in yoshi's mouth, update position
        local p = Player(v:mem(0x13C,FIELD_DFLOAT))

        v.x = p.x + p:mem(0x6E,FIELD_WORD) - v.width*0.5 + 16
        v.y = p.y + p:mem(0x70,FIELD_WORD) - v.height*0.5 + 16
    end


    -- Translation, mostly to make turning around while holding it a little less janky
    data.translation = getPostTranslation(v,data,config)

    data.lastPos.x = v.x + v.width*0.5
    data.lastPos.y = v.y + v.height

    --Text.print(data.translation,v.x - camera.x,v.y - camera.y)
    

    updateChainsPost(v,data,config,settings)


    if attachedNPCCanStay(a) then
        if v:mem(0x138,FIELD_WORD) == 4 then
            a:mem(0x138,FIELD_WORD,v:mem(0x138,FIELD_WORD))
            a:mem(0x13C,FIELD_DFLOAT,v:mem(0x13C,FIELD_DFLOAT))
            a:mem(0x144,FIELD_WORD,0)
            
            a.x = v.x + v.width*0.5 - a.width*0.5
            a.y = v.y + v.height - a.height - 2
        end

        -- Get despawn timers matched up
        v.despawnTimer = math.max(v.despawnTimer,a.despawnTimer)
        a.despawnTimer = v.despawnTimer

        if yoshiForcedStates[v:mem(0x138,FIELD_WORD)] then
            a:mem(0x12E,FIELD_WORD,50)
            a:mem(0x130,FIELD_WORD,v:mem(0x13C,FIELD_DFLOAT))
        elseif v:mem(0x12E,FIELD_WORD) > a:mem(0x12E,FIELD_WORD) then
            a:mem(0x12E,FIELD_WORD,v:mem(0x12E,FIELD_WORD))
            a:mem(0x130,FIELD_WORD,v:mem(0x130,FIELD_WORD))
        end

        stopLineguideAttach(a)


        -- Restrict movement
        local segment = data.chainsRope.segments[#data.chainsRope.segments]
        local lastSegment = data.chainsRope.segments[#data.chainsRope.segments - 1]
        local distance = (lastSegment.position - segment.oldpos)
        --local distance = (lastSegment.position - vector(a.x + a.width*0.5,a.y + a.height))

        local maxRadius = data.chainsRope.segmentLength

        if distance.length > maxRadius then
            local useForceMove = (chainChomp.forceMoveMap[a.id] or data.chainBehaviour == CHAINBEHAVIOUR_STICK)
            local direction = distance:normalise()
            
            local distanceX = segment.position.x - (a.x + a.width*0.5)
            local distanceY = segment.position.y - (a.y + a.height)

            if data.chainBehaviour ~= CHAINBEHAVIOUR_FIXED then
                a.speedX = math.clamp(distanceX,-96,96)
                a.speedY = math.clamp(distanceY,-96,96)

                if a:mem(0x1C,FIELD_WORD) > 0 then
                    a:mem(0x18,FIELD_FLOAT,a.speedX*2)
                end

                if useForceMove then
                    a.x = a.x + a.speedX
                    a.y = a.y + a.speedY
                end

                if not useForceMove and not hasNoBlockCollision(a) then
                    a:mem(0x136,FIELD_BOOL,true)
                end
            else
                a.x = a.x + distanceX
                a.y = a.y + distanceY
            end

            -- Snap mechanics
            if config.chainSnapThreshold > 0 and distance.length >= (maxRadius + config.chainSnapThreshold) then
                snapChains(v,data,config)
            end

            data.attachedIsOnEdge = true
        else
            if data.chainBehaviour == CHAINBEHAVIOUR_FIXED then
                a.x = a.x + data.translation.x
                a.y = a.y + data.translation.y
            end
            
            data.attachedIsOnEdge = false
        end

        --segment.oldpos = vector(a.x + a.width*0.5,a.y + a.height + data.chainsRope.gravity)
    elseif a ~= nil then
        snapChains(v,data,config)
    end
end


local lowPriorityStates = table.map{1,3,4}

function chainChomp.onDrawPost(v)
	if v.despawnTimer <= 0 then return end

    local settings = v.data._settings
    local config = NPC.config[v.id]
    local data = v.data._basegame

	if not data.initialized then
		initialisePost(v,data,config,settings)
	end
    
    local priority = -55
    if config.foreground then
        priority = -15
    elseif lowPriorityStates[v:mem(0x138,FIELD_WORD)] then
        priority = -75
    end

    drawChains(v,data,config,priority)

    if v:mem(0x138,FIELD_WORD) ~= 6 then
        local yOffset = 0
        if v:mem(0x138,FIELD_WORD) == 1 then
            yOffset = (config.height - v.height)
        end

        npcutils.drawNPC(v,{priority = priority - 1.5,yOffset = yOffset})
    end

    npcutils.hideNPC(v)

    --Graphics.drawBox{sceneCoords = true,color = Color.red.. 0.8,x = v.x,y = v.y,width = v.width,height = v.height}

    --[[for i = 1,#data.chainsRope.segments-1 do
        local a = data.chainsRope.segments[i]
        local b = data.chainsRope.segments[i + 1]

        Graphics.drawLine{
            color = Color.red,sceneCoords = true,
            start = a.position,stop = b.position,
        }
    end]]

    --[[for _,segment in ipairs(data.chainsRope.segments) do
        Graphics.drawBox{color = Color.green.. 0.75,sceneCoords = true,x = segment.position.x,y = segment.position.y,width = 4,height = 4}
    end]]
end



local function isOnPost(v)
    local post = v.data._basegame.attachedPost

    return (post ~= nil and post.isValid and post.despawnTimer > 0 and post.data._basegame.initialized and post.data._basegame.attachedNPC == v)
end

local function isOnEdgeOfChain(v)
    local post = v.data._basegame.attachedPost
    
    return (post.data._basegame.attachedIsOnEdge)
end

local function setChainBehaviour(v,value)
    local post = v.data._basegame.attachedPost
    local postData = post.data._basegame
    
    postData.chainBehaviour = value
end


local function getGravity(v,data,config)
    if config.nogravity then
        return 0
    end

    local gravity = Defines.npc_grav

    if v.underwater and not config.nowaterphysics then
        gravity = gravity*0.2
    end

    return gravity
end

local function faceProperDirection(v)
    if v.speedX < 0 then
        v.direction = DIR_LEFT
    elseif v.speedX > 0 then
        v.direction = DIR_RIGHT
    end
end


local function getDistanceVector(v,n)
    local post = v.data._basegame.attachedPost

    local x = ((v.x + v.width *0.5) + (post.x + post.width *0.5))*0.5 -- average of post and chomp's position
    local y = ((v.y + v.height*0.5) + (post.y + post.height*0.5))*0.5

    return vector((n.x + n.width*0.5) - x,(n.y + n.height*0.5) - y)
end

local function canTargetPlayer(v,p)
    if p.forcedState ~= FORCEDSTATE_NONE or p:mem(0x13C,FIELD_BOOL) or p.deathTimer > 0 then
        return false
    end

    if p.isMega or p.hasStarman then
        return false
    end

    if v:mem(0x12E,FIELD_WORD) > 0 and v:mem(0x130,FIELD_WORD) == p.idx then
        return false
    end

    return true
end

local function edibleNPCFilter(v)
    if not Colliders.FILTER_COL_NPC_DEF(v) or v:mem(0x138,FIELD_WORD) > 0 then
        return false
    end

    if chainChomp.chompIDMap[v.id] -- cannibalism
    or chainChomp.postIDMap[v.id]
    then
        return false
    end

    if not NPC.HITTABLE_MAP[v.id] and not berries.idMap[v.id] then
        return false
    end

    --[[local config = NPC.config[v.id]
    if config.noyoshi then
        return false
    end]]

    return true
end


local function chooseBoolByCondition(condition,boolA,boolB)
    if condition then
        return boolA
    else
        return boolB
    end
end

local function findLungeTarget(v,data,config)
    if v.friendly then
        return nil
    end

    local post = v.data._basegame.attachedPost
    local postData = post.data._basegame
    local postSettings = post.data._settings

    local radius = #postData.chains*postSettings.chainDistance + config.lungeTargetExtraRadius
    local collider = Colliders.Circle(post.x + post.width*0.5,post.y + post.height*0.5,radius)


    local maxSqrtDist = math.huge
    local closest

    if chooseBoolByCondition(v:mem(0x12E,FIELD_WORD) > 0,config.targetPlayersFriendly,config.targetPlayersNormally) then
        for _,p in ipairs(Player.get()) do
            if collider:collide(p) and canTargetPlayer(v,p) then
                local sqrDist = getDistanceVector(v,p).sqrlength

                if sqrDist < maxSqrtDist then
                    maxSqrtDist = sqrDist
                    closest = p
                end
            end
        end
    end

    if chooseBoolByCondition(v:mem(0x12E,FIELD_WORD) > 0,config.targetEnemiesFriendly,config.targetEnemiesNormally) then
        local npcs = Colliders.getColliding{a = collider,btype = Colliders.NPC,filter = edibleNPCFilter,collisionGroup = v.collisionGroup}

        for _,n in ipairs(npcs) do
            local sqrDist = getDistanceVector(v,n).sqrlength

            if sqrDist < maxSqrtDist then
                maxSqrtDist = sqrDist
                closest = n
            end
        end
    end

    return closest
end

local function chooseLungeDirection(v,data,config)
    local target = findLungeTarget(v,data,config)

    if target ~= nil then
        local distance = getDistanceVector(v,target)

        return distance:normalise()
    end

    -- No target; lunge with a bit of RNG
    local post = v.data._basegame.attachedPost
    
    if yoshiForcedStates[post:mem(0x138,FIELD_WORD)] then
        local p = Player(post:mem(0x13C,FIELD_DFLOAT))

        v.direction = p.direction
    else
        if (v.x + v.width*0.5) > (post.x + post.width*0.5) then
            v.direction = DIR_RIGHT
        else
            v.direction = DIR_LEFT
        end
    end

    local direction = vector(1,0):rotate(RNG.random(config.lungeMinRandomAngle,config.lungeMaxRandomAngle))

    direction.x = direction.x*v.direction

    return direction
end

local function mainBehaviour(v,data,config)
    if v:mem(0x12C,FIELD_WORD) > 0 or v:mem(0x138,FIELD_WORD) > 0 then -- held/forced state
        data.state = CHOMPSTATE_PATROL
        data.timer = 0

        if isOnPost(v) then
            setChainBehaviour(v,CHAINBEHAVIOUR_NORMAL)
        end

        return
    end

    if not isOnPost(v) then
        -- Not on a post; just hop around!
        data.state = CHOMPSTATE_PATROL
        data.timer = 0

        faceProperDirection(v)

        if v.collidesBlockBottom then
            v.speedX = math.max(math.abs(v.speedX),config.looseJumpSpeedX)*v.direction
            v.speedY = config.looseJumpSpeedY
        elseif v.speedX > config.looseJumpSpeedX then
            v.speedX = math.max(config.looseJumpSpeedX,v.speedX - config.deceleration)
        elseif v.speedX < -config.looseJumpSpeedX then
            v.speedX = math.min(-config.looseJumpSpeedX,v.speedX + config.deceleration)
        end
        
        return
    end
    


    if data.state == CHOMPSTATE_PATROL then
        if v:mem(0x1C,FIELD_WORD) > 0 then -- underwater
            data.state = CHOMPSTATE_SWIM
            data.timer = 0
            return
        end

        faceProperDirection(v)

        if v.collidesBlockBottom then
            if data.timer >= config.patrolTime then
                data.state = CHOMPSTATE_PREPARE
                data.timer = 0

                data.lungeDirection = chooseLungeDirection(v,data,config)

                if data.lungeDirection.x ~= 0 then
                    v.direction = math.sign(data.lungeDirection.x)
                end
            else
                v.speedX = config.chainedJumpSpeedX*v.direction
                v.speedY = config.chainedJumpSpeedY
            end
        end
    elseif data.state == CHOMPSTATE_PREPARE then
        if v.collidesBlockBottom then
            if not isOnEdgeOfChain(v) then
                v.speedX = 0
                v.speedY = 0

                v:mem(0x18,FIELD_FLOAT,0)
            end

            if data.timer >= config.prepareTime then
                data.state = CHOMPSTATE_LUNGE
                data.timer = 0

                setChainBehaviour(v,CHAINBEHAVIOUR_STICK)
                v.noblockcollision = true
            end
        else
            data.state = CHOMPSTATE_PATROL
            data.timer = 0
        end
    elseif data.state == CHOMPSTATE_LUNGE then
        v.speedX = data.lungeDirection.x*config.lungeSpeed
        v.speedY = data.lungeDirection.y*config.lungeSpeed - getGravity(v,data,config)


        if not v.friendly and chooseBoolByCondition(v:mem(0x12E,FIELD_WORD) > 0,config.eatEnemiesFriendly,config.eatEnemiesNormally) then
            local edibleNPCs = Colliders.getColliding{a = v,btype = Colliders.NPC,filter = edibleNPCFilter,collisionGroup = v.collisionGroup}

            for _,n in ipairs(edibleNPCs) do
                if berries.idMap[n.id] then
                    berries.eatFromNPC(n,v)
                    SFX.play(55)
                elseif n.killFlag == 0 then
                    n:harm(HARM_TYPE_NPC)

                    -- If the NPC died from that, make the death harm type "VANISH" instead of "NPC"
                    if n.killFlag > 0 then
                        n.killFlag = HARM_TYPE_VANISH

                        SFX.play(9)
                        SFX.play(55)
                    end
                end
            end
        end

        if not v.friendly and chooseBoolByCondition(v:mem(0x12E,FIELD_WORD) > 0,config.destroyBlocksFriendly,config.destroyBlocksNormally) then
            local blocks = Colliders.getColliding{a = v,b = Block.MEGA_SMASH,btype = Colliders.BLOCK,collisionGroup = v.collisionGroup}

            for _,b in ipairs(blocks) do
                if b.id == 90 then
                    b:hit()
                    SFX.play(3)
                elseif b.contentID == 0 then
                    b:remove(true)
                end
            end
        end


        if data.timer >= config.lungeTime then
            data.state = CHOMPSTATE_RETURN
            data.timer = 0

            v.speedX = 0
            v.speedY = 0

            v:mem(0x18,FIELD_FLOAT,0)

            setChainBehaviour(v,CHAINBEHAVIOUR_FIXED)
        end
    elseif data.state == CHOMPSTATE_RETURN then
        local post = v.data._basegame.attachedPost

        local distanceX = (post.x + post.width*0.5) - (v.x + v.width*0.5)
        local distanceY = (post.y + post.height) - (v.y + v.height)

        if data.timer == 1 then
            if distanceX ~= 0 then
                v.speedX = distanceX/32*config.returnSpeedPerBlock

                local t = math.max(1,math.abs(distanceX/v.speedX))

                v.speedY = distanceY/t - getGravity(v,data,config)*config.returnGravityMultiplier*t*0.5

                --Misc.dialog(v.speedX,v.speedY)
            else
                v.speedX = 0
                v.speedY = 0

                v:mem(0x18,FIELD_FLOAT,0)
            end
        end

        if distanceY < -12 and v.speedY > 0 then
            snapChains(post,post.data._basegame,NPC.config[post.id])
        elseif math.abs(distanceX) < 12 then
            if distanceY < post.height*0.5 and v.speedY >= 0 then
                data.state = CHOMPSTATE_PATROL
                data.timer = 0

                setChainBehaviour(v,CHAINBEHAVIOUR_NORMAL)
                v.noblockcollision = false
            end

            v.speedX = 0

            v:mem(0x18,FIELD_FLOAT,0)
        end

        v.speedY = v.speedY - getGravity(v,data,config)*(1 - config.returnGravityMultiplier)

        --if isOnEdgeOfChain(v) then Misc.dialog(data.timer) end
    elseif data.state == CHOMPSTATE_SWIM then
        if v:mem(0x1C,FIELD_WORD) <= 0 then -- not underwater
            data.state = CHOMPSTATE_PATROL
            data.timer = 0
            return
        end

        local post = v.data._basegame.attachedPost

        local distanceX = (post.x + post.width*0.5) - (v.x + v.width*0.5)
        local distanceY = (post.y + post.height) - (v.y + v.height)

        v:mem(0x136,FIELD_BOOL,false)
        faceProperDirection(v)

        v.speedX = config.underwaterSpeedX*v.direction

        if not isOnEdgeOfChain(v) then
            v.speedY = -math.sin(data.timer/config.underwaterFloatTime)*config.underwaterFloatSpeed

            if distanceY < 64 then
                v.speedY = v.speedY - 0.1
            end
            
            v:mem(0x18,FIELD_FLOAT,0)
        end
    end

    --Text.print(v:mem(0x136,FIELD_BOOL),v.x-camera.x,v.y-camera.y)

    data.timer = data.timer + 1
end


local function initialiseChomp(v,data,config)
    if not isOnPost(v) then
        initialiseChains(v,data,config,config.chainCount,false)
    else
        data.chains = {}
    end

    data.state = CHOMPSTATE_PATROL
    data.timer = 0

    data.lungeDirection = vector.zero2

    data.positionHistory = {} -- note: this is a circular buffer, and is zero-based
    data.positionHistoryIndex = 0

    data.animationTimer = 0
    
    data.initialized = true
end


function chainChomp.registerChomp(npcID)
	npcManager.registerEvent(npcID, chainChomp, "onTickEndNPC", "onTickEndChomp")
    npcManager.registerEvent(npcID, chainChomp, "onDrawNPC", "onDrawChomp")

    table.insert(chainChomp.chompIDList,npcID)
    chainChomp.chompIDMap[npcID] = true
end

function chainChomp.onTickEndChomp(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if v.despawnTimer <= 0 then
        if data.initialized then
            v.noblockcollision = false
        end

		data.initialized = false
		return
	end

    local config = NPC.config[v.id]

	if not data.initialized then
		initialiseChomp(v,data,config)
	end


    mainBehaviour(v,data,config)


    -- Handle chain stuff
    local maxLength = #data.chains*config.chainTimeDifference

    if maxLength > 0 then
        local newPos = vector(v.x + v.width*0.5,v.y + v.height*0.5)
        
        data.positionHistory[data.positionHistoryIndex] = newPos
        data.positionHistoryIndex = (data.positionHistoryIndex + 1) % maxLength

        for index,chain in ipairs(data.chains) do
            local index = (data.positionHistoryIndex - index*config.chainTimeDifference) % maxLength
            local pos = data.positionHistory[index]

            if pos ~= nil then
                chain.position = pos + vector(0,chain.height*0.5)
            end
        end
    end

    -- Animation
    if data.state == CHOMPSTATE_PREPARE or data.state == CHOMPSTATE_LUNGE then
        data.animationTimer = data.animationTimer + 2
    else
        data.animationTimer = data.animationTimer + 1
    end

    local frame = math.floor(data.animationTimer/config.framespeed) % config.frames

    v.animationFrame = npcutils.getFrameByFramestyle(v,{frame = frame})


	--[[if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then return end]]
	
	
end


function chainChomp.onDrawChomp(v)
    if v.despawnTimer <= 0 then return end

    local config = NPC.config[v.id]
    local data = v.data._basegame

	if not data.initialized then
		initialiseChomp(v,data,config)
	end
    
    local priority = -46
    if config.foreground then
        priority = -16
    elseif lowPriorityStates[v:mem(0x138,FIELD_WORD)] then
        priority = -76
    end

    drawChains(v,data,config,priority)
end


function chainChomp.onPostNPCKill(v,reason)
    if chainChomp.postIDMap[v.id] then
        local config = NPC.config[v.id]
        local data = v.data._basegame

        if data.initialized then
            snapChains(v,data,config)
        end
    end

    if chainChomp.chompIDMap[v.id] then
        local data = v.data._basegame

        if data.initialized then
            createChainEffects(data.chains)
        end
    end
end


local playersSetCollisionGroup = {}

local function preventSpinJump(p)
    -- Force keys to not set alt jump
    p.keys.jump = p.keys.jump or p.keys.altJump
    p.keys.altJump = false

    -- Disable spin jumps already in progress
    p:mem(0x50,FIELD_BOOL,false)
end

function chainChomp.onTick()
    for _,p in ipairs(Player.get()) do
        local heldNPC = getHoldingNPC(p)

        if heldNPC ~= nil and chainChomp.postIDMap[heldNPC.id] then
            -- Disable spin jumping
            if NPC.config[heldNPC.id].disableSpinJumpWhenHeld and p.mount == MOUNT_NONE then
                preventSpinJump(p)
            end

            -- Set collision group
            if NPC.config[heldNPC.id].setGroupWhenHeld and p.collisionGroup == "" then
                p.collisionGroup = heldNPC.collisionGroup
                playersSetCollisionGroup[p.idx] = p.collisionGroup
            end
        elseif playersSetCollisionGroup[p.idx] ~= nil then
            -- Reset collision group
            if playersSetCollisionGroup[p.idx] == p.collisionGroup then
                p.collisionGroup = ""
            end

            playersSetCollisionGroup[p.idx] = nil
        end
    end
end


function chainChomp.onInitAPI()
    registerEvent(chainChomp,"onPostNPCKill")
    registerEvent(chainChomp,"onTick")
end


return chainChomp