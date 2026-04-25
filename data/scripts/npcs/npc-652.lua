local fishbone = {}

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local npcID = NPC_ID

npcManager.registerDefines(npcID, {NPC.HITTABLE})

local seekSound = Misc.resolveSoundFile("extended/fishbone-find.ogg")

-- settings
local config = {
	id = npcID, 
	gfxoffsety = 0, 
	width = 32, 
    height = 32,
    gfxwidth = 50,
    gfxheight = 32,
    frames = 4,
    speed = 1,
    framestyle = 1,
    noiceball = false,
    noyoshi = false,
	noblockcollision = false,
	nowaterphysics = true,
    nogravity = true,
    jumphurt = true,
    spinjumpSafe = true,
    idleframes = 2,
    visionlength = 300,
    visionwidth = 60,
    chaseSpeedMax = 3,
    chaseAcceleration = 0.025,
    usespotlight = true,
    spotpower = 15,
    needswater = false,
    collisionhit = true,
    lightcolor = Color.canary,
    lightbrightness = 1,
    lightradius = 300,
    lightoffsetx = 12,
    lightoffsety = -8,
    ignorewalls=false,
    staticdirection = true
}

npcManager.registerHarmTypes(npcID, {HARM_TYPE_NPC, HARM_TYPE_SWORD, HARM_TYPE_LAVA, HARM_TYPE_PROJECTILE_USED}, {
    [HARM_TYPE_NPC] = 285,
    [HARM_TYPE_SWORD] = 285,
    [HARM_TYPE_PROJECTILE_USED] = 285,
    [HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5}
})

npcManager.setNpcSettings(config)

function fishbone.onInitAPI()
    npcManager.registerEvent(npcID, fishbone, "onTickEndNPC")
    npcManager.registerEvent(npcID, fishbone, "onDrawNPC")
    registerEvent(fishbone, "onPostNPCKill")
end

function fishbone.onPostNPCKill(v, r)
    if v.id == npcID then
        SFX.play(57)
    end
end

local function attack(v, data, settings, target)
    data.aggro = true
    data.timer = 0
    data.startDirection = v.direction

    if target == nil or settings.fixedAngle then
        data.targetAngle = data.angle
    else
        local x = (target.x + 0.5 * target.width) - (v.x + 0.5 * v.width)
        local y = (target.y + 0.5 * target.height) - (v.y + 0.5 * v.height)
        data.targetAngle = math.deg(math.atan2(y, x)) + 90 - 90 * v.direction
    end

    SFX.play(seekSound)
    v.dontMove = true
end

local function setSpotlight(v)
    local cfg = NPC.config[v.id]
    local data = v.data._basegame
    local angle = data.angle or 0
    if v.lightSource ~= nil and cfg.usespotlight then
        v.lightSource.parentoffset = vector(cfg.lightoffsetx, cfg.lightoffsety):rotate(angle * v.direction)
        v.lightSource.type = Darkness.lighttype.SPOT
        v.lightSource.spotangle = config.visionwidth * 0.5
        v.lightSource.spotpower = config.lightbrightness * cfg.spotpower
        v.lightSource.dir = (vector.right2 * v.direction):rotate(angle)
    end
end

local aroundPlayerCollider = Colliders.Box(0,0,0,0)

local function seekTarget(v, data, cfg)
    for k,p in ipairs(Player.get()) do
        if Colliders.collide(data.visionCollider[v.direction], p) and Misc.canCollideWith(v, p) then
            local doAttack = cfg.ignorewalls
            
            if not cfg.ignorewalls then
                local pcx, pcy = p.x + 0.5 * p.width, p.y + 0.5 * p.height
                local vcx, vcy = v.x + 0.5 * v.width, v.y + 0.5 * v.height
                aroundPlayerCollider.x = math.min(vcx, pcx) - 1
                aroundPlayerCollider.y = math.min(vcy, pcy) - 1
                aroundPlayerCollider.width = math.abs(vcx - pcx) + 2
                aroundPlayerCollider.height = math.abs(vcy - pcy) + 2
                local b = Colliders.getColliding{a = aroundPlayerCollider, b = Block.SOLID, btype = Colliders.BLOCK, collisionGroup = v.collisionGroup}
                if #b > 0 then
                    local a,x,c,d = Colliders.linecast(vector(v.x + 0.5 * v.width, v.y + 0.5 * v.height), vector(p.x + 0.5 * p.width, p.y + 0.5 * p.height), b)
                    if not a then
                        return p
                    end
                else
                    return p
                end
            else
                return p
            end
        end
    end
end

function fishbone.onTickEndNPC(v)
    if Defines.levelFreeze then return end

    local data = v.data._basegame

    if v.despawnTimer <= 0 then
        data.init = false
        return
    end

    if v:mem(0x12C, FIELD_WORD) ~= 0 or v:mem(0x138, FIELD_WORD) > 0 then
        data.init = false
        setSpotlight(v)
        return
    end

    local cfg = NPC.config[v.id]
    local settings = v.data._settings

    if not data.init then
        data.init = true
        data.timer = 0
        data.startDirection = v.direction
        data.aggro = false
        data.angle = settings.angle * data.startDirection
        data.lastDir = data.startDirection
        data.targetAngle = 0
        if data.visionCollider == nil then
            data.visionCollider = {
                [-1] = Colliders.Tri(0,0,{0,0},{-cfg.visionlength,-cfg.visionwidth},{-cfg.visionlength,cfg.visionwidth}),
                [1] = Colliders.Tri(0,0,{0,0},{cfg.visionlength,-cfg.visionwidth},{cfg.visionlength,cfg.visionwidth}),
            }

            data.visionCollider[-1]:Rotate(settings.angle * data.startDirection)
            data.visionCollider[1]:Rotate(settings.angle * data.startDirection)
        end
        if settings.startsAggro then
            local target = seekTarget(v,data,cfg)
            attack(v, data, settings, target)
        end
    end

    if (v.dontMove or settings.fixedDirection) and v.direction ~= data.startDirection then
        v.direction = data.startDirection
    end

    if v:mem(0x132, FIELD_WORD) > 0 then
        setSpotlight(v)
        return
    end

    if v:mem(0x136, FIELD_BOOL) or v:mem(0x132, FIELD_WORD) > 0 then
        if data.speedStorage == nil then
            data.speedStorage = vector(v.speedX, v.speedY)
        end
    end

    if (not cfg.needswater) or v.underwater then
        if not data.aggro then
            local currentPos = vector(
                settings.xAmplitude * math.cos(settings.xFrequency * data.timer * 0.1) * -data.startDirection * math.sign(settings.xFrequency),
                settings.yAmplitude * math.sin(settings.yFrequency * data.timer * 0.1)):rotate(settings.angle * data.startDirection)
            data.timer = data.timer + 0.1
            local nextPos = vector(
                settings.xAmplitude * math.cos(settings.xFrequency * data.timer * 0.1) * -data.startDirection * math.sign(settings.xFrequency),
                settings.yAmplitude * math.sin(settings.yFrequency * data.timer * 0.1)):rotate(settings.angle * data.startDirection)

            v.speedX = nextPos.x - currentPos.x
            v.speedY = nextPos.y - currentPos.y
            local dir = math.sign(nextPos.x - currentPos.x)
            if not settings.fixedDirection and dir ~= 0 then
                v.direction = dir
            end

            if data.speedStorage ~= nil then
                v.speedX = v.speedX + data.speedStorage.x
                v.speedY = v.speedY + data.speedStorage.y
                data.speedStorage = data.speedStorage * 0.9

                if data.speedStorage.length < 0.1 then
                    data.speedStorage = nil
                    v.isProjectile = false
                end
            end

            if not v.friendly and not v.isProjectile then
                data.visionCollider[v.direction].x = v.x + 0.5 * v.width
                data.visionCollider[v.direction].y = v.y + 0.5 * v.height
                local target = seekTarget(v, data, cfg)

                if target then
                    attack(v, data, settings, target)
                end
            end
        elseif v.dontMove then
            data.timer = data.timer + 0.05
            data.angle = math.anglelerp(data.angle, data.targetAngle, math.min(data.timer, 1))
            v.speedX = 0
            v.speedY = 0

            if data.timer >= 1.5 then
                v.dontMove = false
            end
        else
            local vec = vector(v.direction, 0):rotate(data.angle) * cfg.chaseSpeedMax
            v.speedX = v.speedX + vec.x * cfg.chaseAcceleration
            v.speedY = v.speedY + vec.y * cfg.chaseAcceleration
        end
    else
        if data.aggro then
            v:kill(3)
        end
        v.speedY = v.speedY + Defines.npc_grav
    end

    if data.lastDir ~= v.direction and data.aggro then
        data.angle = -data.angle
    end

    setSpotlight(v)

    data.lastDir = v.direction
    if v.collidesBlockBottom or v.collidesBlockLeft or v.collidesBlockUp or v.collidesBlockRight or v:mem(0x120,FIELD_BOOL) then
        v:kill(3)
        if data.aggro and NPC.config[v.id].collisionhit then
            for k,n in NPC.iterateIntersecting(v.x + v.speedX, v.y + v.speedY, v.x + v.width + v.speedX, v.y + v.height + v.speedY) do
                if NPC.HITTABLE_MAP[n.id] and n ~= v and n.despawnTimer > 0 and n:mem(0x12C, FIELD_WORD) == 0 and n:mem(0x138, FIELD_WORD) == 0 and n.friendly == false and n.isGenerator == false then
                    n:harm(3)
                end
            end
            for k,b in Block.iterateIntersecting(v.x + v.speedX, v.y + v.speedY, v.x + v.width + v.speedX, v.y + v.height + v.speedY) do
                if not b.isHidden and not b:mem(0x5A, FIELD_BOOL) then
                    b:hit(v.speedY > 0 and v.y + v.height <= b.y)
                end
            end
        end
    end
end

function fishbone.onDrawNPC(v)
    if v.despawnTimer <= 0 then
        return
    end

    local cfg = NPC.config[v.id]
    local settings = v.data._settings

    local data = v.data._basegame

    data.animationFrame = math.floor(lunatime.tick()/cfg.framespeed) % cfg.frames

    local totalframe = data.animationFrame % cfg.idleframes

    if data.aggro then
        totalframe = totalframe + cfg.idleframes
    end

    local totalframes = cfg.frames
    if cfg.framestyle == 1 then
        if v.direction == 1 then
            totalframe = totalframe + cfg.frames
        end
        totalframes = totalframes * 2
    end

    if data.angle == 0 then
        v.animationFrame = totalframe
        return
    end

    local p = -45
    if cfg.foreground then
        p = -15
    end

    local gfxw, gfxh = cfg.gfxwidth * 0.5, cfg.gfxheight * 0.5

    local vt = {
        vector(-gfxw, -gfxh),
        vector(gfxw, -gfxh),
        vector(gfxw, gfxh),
        vector(-gfxw, gfxh),
    }

    local f0 = totalframe / totalframes
    local f1 = (totalframe + 1) / totalframes

    local tx = {
        0, f0,
        1, f0,
        1, f1,
        0, f1,
    }

    local x, y = v.x + 0.5 * v.width + cfg.gfxoffsetx, v.y + 0.5 * v.height + cfg.gfxoffsety

    for k,a in ipairs(vt) do
        vt[k] = a:rotate(data.angle or 0)
    end

    Graphics.glDraw{
        vertexCoords = {
            x + vt[1].x, y + vt[1].y,
            x + vt[2].x, y + vt[2].y,
            x + vt[3].x, y + vt[3].y,
            x + vt[4].x, y + vt[4].y,
        },
        textureCoords = tx,
        primitive = Graphics.GL_TRIANGLE_FAN,
        texture = Graphics.sprites.npc[v.id].img,
        sceneCoords = true,
        priority = p
    }

    npcutils.hideNPC(v)
end

return fishbone