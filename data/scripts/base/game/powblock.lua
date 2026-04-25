local powblock = {}

-- The absolute maximum number of ripples that may ever be rendered at the same time
powblock.maxRipples = 64

local typeDefinitions = {}
powblock.type = {}

local tableinsert = table.insert

function powblock.registerType(name, args)
    name = string.upper(name)
    if powblock.type[name] then
        Misc.warn("POW effect of type " .. name .. " is already defined.")
        return
    end
    powblock.type[name] = #typeDefinitions + 1
    if args.dropsCoins == nil then
        args.dropsCoins = true
    end

    tableinsert(typeDefinitions, {
        useLegacy = args.useLegacy,
        dropsCoins = args.dropsCoins,
        type = powblock.type[name],
        npcsHit = args.npcsHit,
        sound = args.sound or 38,
        earthquake = args.earthquake or 8,
        blocksHit = args.blocksHit,
        smashableStrength = args.smashableStrength or 4 -- smaller is more powerful
    })
end

local currentShadersCompiledUpTo = 4

local activeRippleCount = 0

local powShaders = {}

local rippleData = {}

local rippleColliders = {}

local thisFrameGlobalPow = nil

local powShader = Misc.resolveFile("shaders/npc/powblockripple.frag")

local function compileNewShaders()
    if powShaders[powblock.maxRipples] == nil then
        powShaders[powblock.maxRipples] = Shader()
        powShaders[powblock.maxRipples]:compileFromFile(nil, powShader, { _MAXRIPPLES = powblock.maxRipples})
    end
    local i = 4
    while i <= currentShadersCompiledUpTo do
        if powShaders[i] == nil then
            powShaders[i] = Shader()
            powShaders[i]:compileFromFile(nil, powShader, { _MAXRIPPLES = i})
        end
        if i == 0 then
            i = 1
        else
            i = i*2
        end
    end

    for i=0, currentShadersCompiledUpTo-1 do
        if rippleData[i*4 + 1] == nil then
            rippleData[i*4 + 1] = 0
            rippleData[i*4 + 2] = 0
            rippleData[i*4 + 3] = 0
            rippleData[i*4 + 4] = 0
        end
    end
end

local cameraCaptureBuffers = {
    Graphics.CaptureBuffer(800, 600),
    Graphics.CaptureBuffer(800, 600)
}

local function getBestShader()
    local count = #rippleData / 4
    if count >= powblock.maxRipples then
        return powShaders[powblock.maxRipples]
    elseif powShaders[count] then
        return powShaders[count]
    else
        local best = powShaders[4]
        local i = 4
        while i < count do
            if i == 0 then
                i = 1
            else
                i = i*2
            end
            best = powShaders[i]
        end
        
        return best
    end
end

local function createRippleCollider(x, y, timer, powdef)
    tableinsert(rippleColliders, {
        collider = Colliders.Circle(x, y, 0),
        timer = timer,
        powdef = powdef,
        hitEntityMap = {}
    })
end

local function npcFilterFunc(other)
    return (
        (not other.friendly)
    and (not other.generator)
    and (other.despawnTimer > 0)
    and (not NPC.config[other.id].nopowblock)
    and (other:mem(0x12C, FIELD_WORD) == 0)
    and (other:mem(0x138, FIELD_WORD) == 0)
    )
end

local function blockFilterFunc(other)
    return (
        (not other.isHidden)
    and (not other:mem(0x5A, FIELD_BOOL))
    )
end

local function hitThingsWithThePow(powdef, collider, hitEntityMap)
    if powdef.dropsCoins then
        for k,n in ipairs(Colliders.getColliding{a = collider, b = NPC.COIN, btype = Colliders.NPC, filter = npcFilterFunc}) do
            if not hitEntityMap[n] then
                hitEntityMap[n] = true
    
                local eventObj = {cancelled = false}
                EventManager.callEvent("onNPCPOWHit", eventObj, n, powdef.type)
    
                if not eventObj.cancelled then
                    if n.ai1 == 0 then
                        n.ai1 = 1
                        n.speedX = RNG.random(-0.5, 0.5)
                        n.speedY = -2.2
                    elseif n.collidesBlockBottom then
                        local y = n.y + n.height
                        n:harm(2)
                        n.y = y - n.height
                    end
                    EventManager.callEvent("onPostNPCPOWHit", n, powdef.type)
                end
            end
        end
    end

    if powdef.npcsHit then
        local npcsHitList = nil
        for k,v in ipairs(powdef.npcsHit) do
            if type(v) == "string" then
                if npcsHitList == nil then
                    npcsHitList = NPC[v]
                else
                    npcsHitList = npcsHitList .. NPC[v]
                end
            end
        end

        for k,n in ipairs(Colliders.getColliding{a = collider, b = npcsHitList, btype = Colliders.NPC, filter = npcFilterFunc}) do
    
            if not hitEntityMap[n] then
                hitEntityMap[n] = true
    
                local eventObj = {cancelled = false}
                EventManager.callEvent("onNPCPOWHit", eventObj, n, powdef.type)
    
                if not eventObj.cancelled then
                    if n.collidesBlockBottom then
                        local y = n.y + n.height
                        n:harm(2)
                        n.y = y - n.height
                    end
                    EventManager.callEvent("onPostNPCPOWHit", n, powdef.type)
                end
            end
        end
    end

    if powdef.blocksHit then
        local blocksHitList = nil
        if powdef.blocksHit then
            for k,v in ipairs(powdef.blocksHit) do
                if type(v) == "string" then
                    if blocksHitList == nil then
                        blocksHitList = Block[v]
                    else
                        blocksHitList = blocksHitList .. Block[v]
                    end
                end
            end
        end
        for k,b in ipairs(Colliders.getColliding{a = collider, b = blocksHitList, btype = Colliders.BLOCK, filter = blockFilterFunc}) do
            if not hitEntityMap[b] then
                hitEntityMap[b] = true
                local wouldRemoveBlock = Block.config[b.id].smashable and Block.config[b.id].smashable >= powdef.smashableStrength
                if ((b:mem(0x52, FIELD_WORD) == 0 and b:mem(0x54, FIELD_WORD) == 0) or (wouldRemoveBlock and b.contentID == 0)) --[[not getting hit]] then
                    local eventObj = {cancelled = false}
                    EventManager.callEvent("onBlockPOWHit", eventObj, b, powdef.type)
                    if not eventObj.cancelled then
                        if wouldRemoveBlock then
                            if b.contentID > 0 then
                                b:hit()
                            else
                                b:remove(true)
                            end
                        else
                            b:hit()
                        end
                        EventManager.callEvent("onPostBlockPOWHit", b, powdef.type)
                    end
                end
            end
        end
    end
end

-- iBlocks (or interesting blocks/blocks of interest according to comments), blocks that are doing something interesting. messing with this so bumps hurt npcs. given to me by MDA
local IBLOCK_COUNT = 0x00B25784 -- iBlocks in source. holds the total amount of iBlocks
local IBLOCK_ADDR = mem(0x00B25798,FIELD_DWORD) -- iBlock in source. the array of iBlocks
 
local function setasIBlock(block) -- sets a block as an iBlock, basic stuff
    mem(IBLOCK_COUNT,FIELD_WORD, mem(IBLOCK_COUNT,FIELD_WORD) + 1)
    mem(IBLOCK_ADDR + mem(IBLOCK_COUNT,FIELD_WORD)*2,FIELD_WORD, block.idx)
end

local function doLegacyPow()

	local iBlockMap = {}
	for i = 0, mem(IBLOCK_COUNT,FIELD_WORD) do
		iBlockMap[mem(IBLOCK_ADDR + i*2,FIELD_WORD)] = true
	end

    for k,c in ipairs(Camera.get()) do
        for k,b in Block.iterateIntersecting(c.x, c.y, c.x + c.width, c.y + c.height) do
            if not b.isHidden then
                b:mem(0x52, FIELD_WORD, -6)
                b:mem(0x54, FIELD_WORD, 6)
                b:mem(0x56, FIELD_WORD, 0)
				
				if not iBlockMap[b.idx] then
					setasIBlock(b)
					iBlockMap[b.idx] = true
				end
            end
        end
    end
    for k,v in NPC.iterate() do
        if v.despawnTimer > 0 then
            if NPC.config[v.id].iscoin then
                v.ai1 = 1
                v.speedX = RNG.random(0, 1) - 0.5
            end
        end
    end
end

function powblock.doPOW(powType, x, y, radius)
	-- Call onPOW event
	local obj = {cancelled = false}
	EventManager.callEvent("onPOW", obj)
	
	-- If the event was cancelled, return immediately
	if obj.cancelled then
		return nil
	end

    
    local broke = false

    if powType == nil then
        powType = "legacy" -- Default to the one that acts like the vanilla one
    end

    powType = string.upper(powType)

    if type(powType) == "string" and powblock.type[powType] then
        powType = powblock.type[powType]
    end

    if typeDefinitions[powType] == nil then
        Misc.dialog("Invalid POW type: ".. powType .. "!")
        return
    end
    local powdef = typeDefinitions[powType]

    if powdef.sound ~= 0 and powdef.sound ~= false then
        SFX.play(powdef.sound)
    end

	Defines.earthquake = math.max(Defines.earthquake, powdef.earthquake)

    if radius ~= nil and radius <= 0 then
        radius = nil
    end

    if powdef.useLegacy then
        doLegacyPow()
        return
    end

    if x == nil or y == nil or radius == nil then
        thisFrameGlobalPow = {x = x, y = y, radius = radius, powdef = powdef, delay = 2}
        return
    end

    for i=0, currentShadersCompiledUpTo-1 do
        if rippleData[i * 4 + 4] == 0 then
            rippleData[i * 4 + 4] = 1
            rippleData[i * 4 + 3] = radius
            rippleData[i * 4 + 2] = y
            rippleData[i * 4 + 1] = x
            activeRippleCount = activeRippleCount + 1
            broke = true
            createRippleCollider( x, y, radius / 12, powdef)
            break;
        end
    end

    if (not broke) and currentShadersCompiledUpTo < powblock.maxRipples then
        tableinsert(rippleData, x)
        tableinsert(rippleData, y)
        tableinsert(rippleData, radius)
        tableinsert(rippleData, 1)
        currentShadersCompiledUpTo = currentShadersCompiledUpTo * 2
        createRippleCollider( x, y, radius / 12, powdef)
        compileNewShaders()
    end
end

powblock.originalDoPOW = Misc.doPOW

Misc.doPOW = powblock.doPOW
Misc.registerPOWType = powblock.registerType
Misc.powType = powblock.type

Misc.registerPOWType("legacy", {useLegacy = true, sound = 37, earthquake = 20})
Misc.registerPOWType("SMB2", {
	blocksHit = {"SOLID, SEMISOLID, SIZEABLE"},
	npcsHit = {"HITTABLE", "UNHITTABLE"},
})
Misc.registerPOWType("SMW", {
	blocksHit = {"SOLID, SEMISOLID, SIZEABLE"},
	npcsHit = {"HITTABLE", "UNHITTABLE"},
	smashableStrength = 3
})

function powblock.onTickEnd()
    if thisFrameGlobalPow then
        thisFrameGlobalPow.delay = thisFrameGlobalPow.delay - 1
        if thisFrameGlobalPow.delay == 0 then
            -- do an instant pow across the screen
            if thisFrameGlobalPow.x and thisFrameGlobalPow.y then
                -- try to find a camera to spawn it on
                for k,v in ipairs(Camera.get()) do
                    if thisFrameGlobalPow.x <= v.x + v.width and thisFrameGlobalPow.x >= v.x and thisFrameGlobalPow.y <= v.y + v.height and thisFrameGlobalPow.y >= v.y then
                        local c = Colliders.Box(v.x, v.y, v.width, v.height)
                        hitThingsWithThePow(thisFrameGlobalPow.powdef, c, {})
                        break
                    end
                end
            else
                -- spawn across both cameras
                for k,v in ipairs(Camera.get()) do
                    local c = Colliders.Box(v.x, v.y, v.width, v.height)
                    hitThingsWithThePow(thisFrameGlobalPow.powdef, c, {})
                end
            end
            thisFrameGlobalPow = nil
        end
    end
    for i=0, currentShadersCompiledUpTo-1 do
        if rippleData[i * 4 + 4] > 0 then
            if rippleData[i * 4 + 4] >= rippleData[i * 4 + 3] / 12 then
                activeRippleCount = activeRippleCount - 1
                rippleData[i * 4 + 4] = -1
            end 
            rippleData[i * 4 + 4] = rippleData[i * 4 + 4] + 1
        end
    end

    for i=#rippleColliders, 1, -1 do
        local rc = rippleColliders[i]
        rc.timer = rc.timer - 1
        rc.collider.radius = rc.collider.radius + 10
        hitThingsWithThePow(rc.powdef, rc.collider, rc.hitEntityMap)
        if rc.timer <= 0 then
            table.remove(rippleColliders, i)
        end
    end
end

function powblock.onCameraDraw(camIdx)
    -- Only run rendering effects when there are active ripples
    if activeRippleCount > 0 then
        local cam = Camera(camIdx)
        cameraCaptureBuffers[camIdx]:captureAt(-5)
        Graphics.drawBox{
            sceneCoords = true,
            x = cam.x,
            y = cam.y, 
            sourceWidth = cam.width,
            sourceHeight = cam.height,
            shader = getBestShader(),
            priority = -5,
            texture = cameraCaptureBuffers[camIdx],
            uniforms = {
                iResolution = {cam.width, cam.height},
                iCameraPosition = {cam.x, cam.y},
                rippleData = rippleData
            }
        }
    end
end

compileNewShaders()

registerEvent(powblock, "onCameraDraw")
registerEvent(powblock, "onTickEnd")

return powblock