local pm = require("playerManager")

local tangent = {}

tangent.loaded = false

-- Is Tangent lunging?
local lunging = false

-- Cooldown until Tangent can lunge again.
local lungeCooldown = 0

-- Register events.
registerEvent(tangent,"onDraw")
registerEvent(tangent,"onTick")
registerEvent(tangent,"onPlayerHarm")
registerEvent(tangent,"onKeyboardPress")
registerEvent(tangent,"onControllerButtonPress")
registerEvent(tangent,"onInputUpdate")

function tangent.initCharacter()
    Defines.player_walkspeed = 5
    Defines.player_runspeed = 8
    Defines.jumpheight = 26
    Defines.jumpheight_bounce = 26
end

function tangent.cleanupCharacter()
    Defines.player_walkspeed = 3
    Defines.player_runspeed = 6
    Defines.jumpheight = 20
    Defines.jumpheight_bounce = 32
end

function tangent.onDraw()
    for _,p in ipairs(Player.get()) do
        if p.character == CHARACTER_TANGENT then
            if lunging then
                p.frame = 3
            end
        end
    end
end

function tangent.lungeattack(plr)
    if not (plr.powerup == 5) then
        lungeCooldown = 40
        plr:mem(0x140, FIELD_WORD, 0) --Blinker is 0
        player:mem(0x120, FIELD_BOOL, false) --Making sure Alt Jump isn't pressed until after the attack
        plr:mem(0x172, FIELD_BOOL, false) --No run either, in case
        SFX.play("sound/extended/character/tangent-lunge.ogg")
        if plr.direction == 1 then
            plr.speedX = 5
            plr.speedY = -3
        elseif plr.direction == -1 then
            plr.speedX = -5
            plr.speedY = -3
        end
        lungingTicks = 0
        lunging = true
        if lungingTicks > 15 then
            lunging = false
        end
    end
end

function tangent.onTick()
    for _,plr in ipairs(Player.get()) do
        if plr.character == CHARACTER_TANGENT then
            local hitNPCs = Colliders.getColliding{a = plr, b = hitNPCs, btype = Colliders.NPC}
            if lungeCooldown > 0 then
                lungeCooldown = lungeCooldown - 1
            end
            if lunging then
                plr.keys.left = false
                plr.keys.right = false
                plr.keys.up = false
                plr.keys.down = false
                plr.keys.jump = false
                plr.keys.altJump = false
                plr.keys.run = false
                for _,npc in ipairs(hitNPCs) do
                    if npc ~= v and npc.id > 0 then
                        -- Hurt the NPC, and make sure to not give the automatic score
                        local oldScore = NPC.config[npc.id].score
                        NPC.config[npc.id].score = 0
                        NPC.config[npc.id].score = oldScore
                        
                        local hurtNPC = npc:harmAccurate(HARM_TYPE_NPC)
                        if hurtNPC then
                            Misc.givePoints(0,{x = npc.x+npc.width*1.5,y = npc.y+npc.height*0.5},true)
                        end
                    end
                end
                lungingTicks = lungingTicks + 1

                plr.x = plr.x + 4 * plr.direction

                if lungingTicks > 15 then
                    lunging = false
                    plr:mem(0x140, FIELD_WORD, 50)
                end
            end
        end
    end
end

function tangent.onPlayerHarm(e, p)
    if p.character == CHARACTER_TANGENT then
        if lunging then
            e.cancelled = true
        end
    end
end

function tangent.onInputUpdate()
    for _,p in ipairs(Player.get()) do
        if p.character == CHARACTER_TANGENT then
            if p.keys.altRun == KEYS_PRESSED and not lunging and lungeCooldown == 0 then
                tangent.lungeattack(p)
            end
        end
    end
end

return tangent
