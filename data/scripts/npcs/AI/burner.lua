local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local lineguide = require("lineguide")

local burnerTop = {}
local npcID = NPC_ID

local sharedSettings = {
	gfxheight = 32,
	gfxwidth = 32,
	width = 32,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,
	frames = 1,
	framestyle = 0,
	framespeed = 8,
	speed = 1,
	
	npcblock = true,
	npcblocktop = false,
	playerblock = true,
	playerblocktop = true,

	nohurt=true,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,
	nowalldeath = true,
	notcointransformable = true,

    spawndelay = 1,
    stepactivated = false,
    fireid = 547,
    burnerframes = 0,
    burnerframestyle = 0
}

local tableinsert = table.insert

burnerTop.DIRECTION = {
    UP = vector(0, -1),
    DOWN = vector(0, 1),
    LEFT = vector(-1, 0),
    RIGHT = vector(1, 0)
}

local burnerMap = {}
local burnerFireMap = {}

local function burnerFireCustomBlockCollision(npc, b, btype, filter)
    if npc.data._basegame.collider and not npc.data._basegame.appliedFriendly then
        if b then
            return Colliders.collide(npc.data._basegame.collider, b)
        else
            return Colliders.getColliding{a = npc.data._basegame.collider, btype = btype, filter = filter, collisionGroup = npc.collisionGroup}
        end
    end
end

function burnerTop.registerBurner(id, settings)
	npcManager.registerEvent(id, burnerTop, "onTickNPC", "onTickBurner")
    burnerMap[id] = true
    npcManager.registerDefines(id, {NPC.UNHITTABLE})
    npcManager.setNpcSettings(table.join(settings, sharedSettings))
    lineguide.registerNpcs(id)
    registerEvent(burnerTop, "onPostNPCKill")
end

function burnerTop.onPostNPCKill(v, r)
    if burnerMap[v.id] then
        local data = v.data._basegame
        if data.fires then
            for k,n in ipairs(data.fires) do
                if n.isValid then
                    n:kill(r)
                end
            end
        end
    end
end

function burnerTop.registerFire(id)
    burnerFireMap[id] = true
	npcManager.registerEvent(id, burnerTop, "onTickEndNPC", "onTickEndFire")

    npcManager.registerCustomCollisionFunction(id, burnerFireCustomBlockCollision)
end

local function shouldSpawnFire(settings, timer)
    local tps = Misc.GetEngineTPS()
    local lifetimeTicks = math.floor(tps * settings.fireLifetime)
    local downtimeTicks = math.floor(tps * settings.downtime)
    return (timer-10) % ((lifetimeTicks + downtimeTicks) * settings.cycleCount) == (lifetimeTicks + downtimeTicks) * (settings.cycleIndex-1)
end

function burnerTop.onTickBurner(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	local settings = v.data._settings

    local config = NPC.config[v.id]

    if not data.initialized then

        if settings.speedMultiplier == nil then
            settings.speedMultiplier = 0
        end
        data.bop = 0
        data.initialized = true
        if v:mem(0x12C, FIELD_WORD) ~= 0 or v:mem(0x138, FIELD_WORD) > 0 then
            settings.isGlobal = false
        end
        if not settings.isGlobal then
            data.angle = settings.startAngle
            data.spawnFireCooldown = 0
            data.fires = nil
        else
            data.angle = data.angle or settings.startAngle
            data.spawnFireCooldown = data.spawnFireCooldown or 0
        end
        data.spawndelay = 0
        data.timer = 0

        if settings.fireLifetime == 0 or settings.fireLifetime == math.huge then
            settings.fireLifetime = math.huge
            data.spawndelay = 1
        end
    end

    local despawned = true
    for k,s in ipairs(Section.getActiveIndices()) do
        if v.section == s then
            despawned = false
        end
    end
	if v.despawnTimer <= 0 or despawned then
        if settings.isGlobal and not config.stepactivated then
            if despawned then
                if data.spawnFireCooldown > 0 then
                    data.spawnFireCooldown = data.spawnFireCooldown - 1
                end
                if shouldSpawnFire(settings, lunatime.tick()) then
                    data.spawnFireCooldown = math.floor(settings.fireLifetime * Misc.GetEngineTPS()) + config.spawndelay
                end
                data.angle = data.angle + settings.speedMultiplier * v.direction
                data.fires = nil
                return
            end
        else
		    data.initialized = false
            return
        end
	end

	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or (v:mem(0x138, FIELD_WORD) > 0 and v:mem(0x138, FIELD_WORD) ~= 5)   --Contained within
	then
		return
	end

    if config.iswalker then
        data.angle = settings.startAngle * -v.direction
    else
        data.angle = data.angle + settings.speedMultiplier * v.direction
    end

    local timer
    if config.stepactivated then
        if data.fires == nil then
            data.timer = data.timer + 1
        end
        timer = data.timer
    else
        if not settings.isGlobal then
            data.timer = data.timer + 1
            timer = data.timer
        else
            timer = lunatime.tick()
        end
    end

    if config.stepactivated then
        if data.timer >= 0 then
            if not config.ignoreplayers then
                for k,p in ipairs(Player.get()) do
                    if p.standingNPC == v and p:getWeight() >= config.triggerweight then
                        data.spawndelay = config.spawndelay
                        data.timer = -math.floor((settings.fireLifetime + settings.downtime) * Misc.GetEngineTPS())
                        break
                    end
                end
            end
            if data.state ~= 1 and not config.ignorenpcs then
                for k,n in NPC.iterateIntersecting(v.x, v.y - 1, v.x + v.width, v.y) do
                    if n:getWeight() >= config.triggerweight and n.collidesBlockBottom and n.despawnTimer > 0 and n.y + n.height <= v.y and n.forcedState == 0 and n.heldIndex == 0 then
                        data.spawndelay = config.spawndelay
                        data.timer = -math.floor((settings.fireLifetime + settings.downtime) * Misc.GetEngineTPS())
                        break
                    end
                end
            end
        end
    else
        if shouldSpawnFire(settings, timer) then
            data.spawndelay = config.spawndelay
        elseif data.spawnFireCooldown > 0 then
            data.spawndelay = 1
            data.spawnFireCooldown = data.spawnFireCooldown - 1
        end
    end

    data.spawndelay = data.spawndelay - 1

    if data.fires == nil and data.spawndelay == 0 and data.spawnFireCooldown <= math.floor(settings.fireLifetime * Misc.GetEngineTPS()) then
        if v.despawnTimer > 20 then
            SFX.play(42)
        end
        if data.spawnFireCooldown == 0 then
            data.spawnFireCooldown = math.floor(settings.fireLifetime * Misc.GetEngineTPS())
        end
        local dir = v.direction
        local fireConfig = NPC.config[config.fireID]
        data.fires = {}
        for i = 360/(config.flames), 360, 360/(config.flames) do
            local f = NPC.spawn(config.fireid, v.x, v.y, v.section, false, true)
            local fireData = f.data._basegame
            fireData.originalSize = vector(f.width, f.height * settings.fireScale)
            fireData.scale = settings.fireScale
            f.width = fireData.originalSize.y + v.width
            f.height = f.width
            f.x = v.x + 0.5 * v.width - 0.5 * fireData.originalSize.y - 0.5 * v.width
            f.y = v.y + 0.5 * v.height - 0.5 * fireData.originalSize.y - 0.5 * v.height
            fireData.pivot = vector(v.x + 0.5 * v.width, v.y + 0.5 * v.height)
            fireData.offset = vector(0, -0.5 * v.height)
            fireData.angle = data.angle + i
            fireData.speedMultiplier = 0
            f.direction = v.direction
            fireData.friendly = v.friendly
            if data.spawnFireCooldown > 0 and settings.fireLifetime ~= math.huge then
                fireData.timer = math.floor(settings.fireLifetime * Misc.GetEngineTPS()) - data.spawnFireCooldown
            else
                fireData.timer = 0
            end
            fireData.lifetime = math.floor(settings.fireLifetime * Misc.GetEngineTPS())
            f.layerName = v.layerName
            f.friendly = true
            f.despawnTimer = 100
            fireData.angleOffset = i
            fireData.setByParent = true

            tableinsert(data.fires, f)
        end
    end

    if v.data._settings.isGlobal then
		v.despawnTimer = math.max(v.despawnTimer, 20)
	end
	if data.fires then
        local allInvalid = true
        for k,f in ipairs(data.fires) do
            if f.isValid then
                v.despawnTimer = math.max(f.despawnTimer, v.despawnTimer)
                f.despawnTimer = v.despawnTimer
                f.data._basegame.pivot = vector(v.x + 0.5 * v.width, v.y + 0.5 * v.height)
                f.data._basegame.angle = data.angle + f.data._basegame.angleOffset
                f.isHidden = v.isHidden
                allInvalid = false
            end
        end
        if allInvalid then
            data.fires = nil
        end
    end
	
	--make this thing movable, shall we?
    if not config.iswalker then
        v.speedX,v.speedY = npcutils.getLayerSpeed(v)
    end
end

local function rotate(x,y,d)
    local r = math.rad(d);
    local sr = math.sin(r);
    local cr = math.cos(r);
    return x*cr - y*sr, x*sr + y*cr;
end

function burnerTop.onTickEndFire(v)
    if Defines.levelFreeze then return end
    
    if v.despawnTimer <= 0 then return end

    local data = v.data._basegame
    local settings = v.data._settings


	local cfg = NPC.config[v.id]
    if not data.initialized then
        data.initialized = true
		data.frame = 0
        if not data.setByParent then
            data.angle = settings.startAngle
            data.speedMultiplier = settings.speedMultiplier
            data.lifetime = math.floor(settings.lifetime * Misc.GetEngineTPS())
            data.timer = 0
            data.offset = vector.zero2
            data.friendly = v.friendly
            data.pivot = vector(v.x + 0.5 * v.width, v.y + v.height)
            data.originalSize = vector(v.width, v.height * settings.fireScale)
            data.scale = settings.fireScale
            v.width = data.originalSize.y * 2
            v.height = v.width
        end
        if data.liftime == 0 then
            data.lifetime = math.huge
        end
        v.friendly = true
        data.appliedFriendly = true
        data.collider = data.collider or Colliders.Rect(0, 0, data.originalSize.x, data.originalSize.y)
    end
    v.x = data.pivot.x - 0.5 * v.width
    v.y = data.pivot.y - 0.5 * v.height
    data.angle = data.angle + data.speedMultiplier * v.direction
    local cx, cy = rotate(data.offset.x, data.offset.y - 0.5 * data.originalSize.y, data.angle)
    data.collider.x = data.pivot.x + cx
    data.collider.y = data.pivot.y + cy
    data.collider.rotation = data.angle

    if v.lightSource then
        v.lightSource.type = Darkness.lighttype.LINE
        v.lightSource.parentoffset = vector(cfg.lightoffsetx, cfg.lightoffsety):rotate(data.angle)
        v.lightSource.dir = (vector.up2 * -data.originalSize.y):rotate(data.angle)
    end

	local framesets = cfg.framesets or 4
	local duration = data.lifetime
	local frames = cfg.frames or 2
	
	-- hardcoded animation time baybee
	-- i want to clean this up but at the same time i have no idea how i'd do it lol
	data.timer = data.timer + 1;

	data.frame = math.floor(data.timer / cfg.framespeed) % cfg.frames

	local frame = data.frame
	local t = data.timer

	local extendTime = math.min(cfg.framespeed * frames * 2, duration * 0.5 / ((framesets) * 2))

	if duration ~= math.huge and data.timer >= duration * 0.5 then
		t = duration - data.timer
    end
    local frameset = math.floor(math.lerp(1, framesets, math.clamp(t/(extendTime), 0, 1)))

	if data.timer >= data.lifetime then
		v:kill(9)
	end
	
	-- update animations
	v.animationTimer = 500
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = frame + (frameset - 1) * frames,
		frames = NPC.config[v.id].frames * framesets,
	});

	if frameset == framesets then
		data.appliedFriendly = data.friendly;
	else
		data.appliedFriendly = true;
	end

    if not data.appliedFriendly and not v.isHidden then
        -- y both times is intended. this is for the bounding box of the fire rotation
        local cx, cy = data.pivot.x + data.offset.x, data.pivot.y + data.offset.y
        for k,p in ipairs(Player.getIntersecting(cx - data.originalSize.y, cy - data.originalSize.y, cx + data.originalSize.y, cy + data.originalSize.y)) do
            if Misc.canCollideWith(v, p) and Colliders.collide(data.collider, p) then
                p:harm()
            end
        end
    end

end

local drawCalls = {}
local drawCallMap = {}
function burnerTop.onCameraDraw(idx)
    local cam = Camera.get()[idx]

    local thisFrameDrawCalls = {}

    local index = 0
    local x1, x2, x3, x4, y1, y2, y3, y4, center, angle, gfxoffsetx, gfxoffsety, maxFrames, cx, cy, halfw, halfh, offX, offY, cfg, f, f1, dc, idx
    for k,v in NPC.iterateIntersecting(cam.x, cam.y, cam.x + cam.width, cam.y + cam.height) do
        if (burnerMap[v.id] or burnerFireMap[v.id]) and v.data._basegame.initialized and v.forcedState == 0 and not v.isHidden then
            cfg = NPC.config[v.id]
            drawCallMap[v.id] = drawCallMap[v.id] or #drawCalls + 1
            drawCalls[drawCallMap[v.id]] = drawCalls[drawCallMap[v.id]] or {
                vertexCoords = {},
                textureCoords = {},
                foreground = NPC.config[v.id].foreground,
                id = v.id,
                index = 0
            }

            thisFrameDrawCalls[v.id] = true


            maxFrames = cfg.frames
            if cfg.framestyle == 1 then
                maxFrames = maxFrames + cfg.frames
            end
            gfxoffsetx, gfxoffsety = cfg.gfxoffsetx, cfg.gfxoffsety
            angle = v.data._basegame.angle
            if burnerMap[v.id] then
                maxFrames = maxFrames + cfg.burnerframes
                if cfg.burnerframestyle == 1 then
                    maxFrames = maxFrames + cfg.burnerframes
                end
                cx, cy = v.x + 0.5 * v.width, v.y + 0.5 * v.height + v.data._basegame.bop

                halfw, halfh = 0.5 * cfg.gfxwidth, 0.5 * cfg.gfxheight
                offX, offY = rotate(-halfw + gfxoffsetx, -halfh + gfxoffsety, angle)
                x1, y1 = cx + offX, cy + offY
                offX, offY = rotate(halfw + gfxoffsetx, -halfh + gfxoffsety, angle)
                x2, y2 = cx + offX, cy + offY
                offX, offY = rotate(-halfw + gfxoffsetx, halfh + gfxoffsety, angle)
                x3, y3 = cx + offX, cy + offY
                offX, offY = rotate(halfw + gfxoffsetx, halfh + gfxoffsety, angle)
                x4, y4 = cx + offX, cy + offY
            else
                maxFrames = maxFrames * cfg.framesets
                offX, offY = rotate(v.data._basegame.offset.x, v.data._basegame.offset.y, angle)
                cx, cy = v.data._basegame.pivot.x + offX, v.data._basegame.pivot.y + offY

                halfw, halfh = 0.5 * cfg.gfxwidth, cfg.gfxheight * v.data._basegame.scale
                offX, offY = rotate(-halfw + gfxoffsetx, -halfh + gfxoffsety, angle)
                x1, y1 = cx + offX, cy + offY
                offX, offY = rotate(halfw + gfxoffsetx, -halfh + gfxoffsety, angle)
                x2, y2 = cx + offX, cy + offY
                offX, offY = rotate(-halfw + gfxoffsetx, gfxoffsety, angle)
                x3, y3 = cx + offX, cy + offY
                offX, offY = rotate(halfw + gfxoffsetx, gfxoffsety, angle)
                x4, y4 = cx + offX, cy + offY
            end
            f = v.animationFrame/maxFrames
            f1 = f + 1/maxFrames

            dc = drawCalls[drawCallMap[v.id]]
            idx = dc.index
            dc.vertexCoords[idx] = x1
            dc.vertexCoords[idx+1] = y1
            dc.textureCoords[idx] = 0
            dc.textureCoords[idx+1] = f
            idx = idx + 2

            for i=1, 2 do
                dc.vertexCoords[idx] = x2
                dc.vertexCoords[idx+1] = y2
                dc.textureCoords[idx] = 1
                dc.textureCoords[idx+1] = f
                idx = idx + 2

                dc.vertexCoords[idx] = x3
                dc.vertexCoords[idx+1] = y3
                dc.textureCoords[idx] = 0
                dc.textureCoords[idx+1] = f1
                idx = idx + 2
            end

            dc.vertexCoords[idx] = x4
            dc.vertexCoords[idx+1] = y4
            dc.textureCoords[idx] = 1
            dc.textureCoords[idx+1] = f1
            idx = idx + 2
            dc.index = dc.index + 12

            npcutils.hideNPC(v)

        end
    end

    for k,v in ipairs(drawCalls) do
        if thisFrameDrawCalls[v.id] then
            local p = -45
            if v.foreground then
                p = -15
            end
            for i=#v.vertexCoords, v.index, -1 do
                v.vertexCoords[i] = nil
                v.textureCoords[i] = nil
            end
            Graphics.glDraw{
                texture = Graphics.sprites.npc[v.id].img,
                vertexCoords = v.vertexCoords,
                textureCoords = v.textureCoords,
                sceneCoords = true,
                priority = p,
                primitive = Graphics.GL_TRIANGLES
            }
            
            v.index = 0
        end
    end
end

registerEvent(burnerTop, "onCameraDraw")

--Gotta return the library table!
return burnerTop