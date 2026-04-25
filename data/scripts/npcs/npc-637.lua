local npcManager = require("npcManager")
local spawner = require("npcs/ai/spawner")
local npcutils = require("npcs/npcutils")

local respawner = {}

local npcID = NPC_ID

local indices = {}

local cams = {{list = {}}, {list = {}}}

local function fleeRoutine(npc, speedX, speedY)
    while npc.isValid do
        if npc.despawnTimer <= 178 then
            npc:kill(9)
            return
        end
        if npc.speedX ~= 0 then
            npc.direction = math.sign(speedX)
            npc.speedX = math.clamp(npc.speedX + speedX, -8, 8)
        end
        npc.speedY = math.clamp(npc.speedY + speedY, -6, 6)
        Routine.skip()
    end
end

local function onSpawnerTriggered(cam, settings, spawner)
    if settings.npc == 0 or settings.npc == nil then
        if cams[cam.idx].list[settings.idx] then
            local i = cams[cam.idx].list[settings.idx].instance
            if i and i.isValid then
                if settings.despawnMethod == 1 then
                    i:kill(1)
                elseif settings.despawnMethod == 2 then
                    i:kill(3)
                elseif settings.despawnMethod == 3 then
                    i:kill(8)
                elseif settings.despawnMethod == 4 then
                    i:kill(9)
                elseif settings.despawnMethod == 5 then
                    Routine.run(fleeRoutine, i, -0.6, 0)
                elseif settings.despawnMethod == 6 then
                    Routine.run(fleeRoutine, i, 0.6, 0)
                elseif settings.despawnMethod == 7 then
                    Routine.run(fleeRoutine, i, 0, -0.6 - Defines.npc_grav)
                elseif settings.despawnMethod == 8 then
                    Routine.run(fleeRoutine, i, 0, 0.6)
                end
            end
        end
        cams[cam.idx].list[settings.idx] = nil
        for k,v in ipairs(indices) do
            if v == settings.idx then
                table.remove(indices, k)
                break
            end
        end

        return
    end
    if cams[cam.idx].list[settings.idx] == nil then
        table.insert(indices, settings.idx)
    end

    local instance = nil
    if cams[cam.idx].list[settings.idx] then
        instance = cams[cam.idx].list[settings.idx].instance
    else
        settings.timer = 0
    end
    cams[cam.idx].list[settings.idx] = settings
    cams[cam.idx].list[settings.idx].instance = instance
    cams[cam.idx].list[settings.idx].spawner = {x = spawner.x, y = spawner.y, width = spawner.width, height = spawner.height}
    cams[cam.idx].list[settings.idx].timer = cams[cam.idx].list[settings.idx].timer or 0

end

spawner.register(npcID, onSpawnerTriggered)

function respawner.onInitAPI()
    registerEvent(respawner, "onTickEnd")
end

function respawner.onTickEnd()
    if Defines.levelFreeze then return end

    for k,v in ipairs(Camera.get()) do
        local cam = cams[v.idx]
        for k,i in ipairs(indices) do
            local c = cam.list[i]
            if c ~= nil then
                if c.instance == nil or not c.instance.isValid then
                    if c.timer > 0 then
                        c.timer = c.timer - 1
                    else
                        local x = v.x + RNG.random(0, v.width)
                        local y = v.y + RNG.random(0, v.height)
                        if c.freezeX then
                            x = c.spawner.x + 0.5 * c.spawner.width
                        end

                        if c.freezeY then
                            y = c.spawner.y + 0.5 * c.spawner.height
                        end

                        local dir = RNG.irandomEntry{-1, 1}

                        if c.offscreenX then
                            local w = NPC.config[c.npc].gfxwidth
                            if w == 0 then
                                w = NPC.config[c.npc].width
                            end
                            local sign = math.sign(x - v.x + 0.5 * v.width)
                            x = v.x + 0.5 * v.width + sign * v.width + 0.5 * w
                            dir = -sign
                        end

                        if c.offscreenY then
                            local h = NPC.config[c.npc].gfxheight
                            if h == 0 then
                                h = NPC.config[c.npc].height
                            end
                            local sign = math.sign(y - v.y + 0.5 * v.height)
                            y = v.y + 0.5 * v.height + sign * v.height + 0.5 * h
                        end

                        c.instance = NPC.spawn(c.npc,
                            x,
                            y,
                            c.section, false, true)
                        c.timer = c.delay
                        c.instance.layerName = "Spawned NPCs"
                        c.instance.direction = dir
                        if c.sound > 0 then
                            SFX.play(c.sound)
                        end
                    end
                end
            end
        end
    end
end

return respawner;