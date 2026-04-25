--[[

	From MrDoubleA's NPC Pack
	Credit to Novarender for vastly improving the font used for character names

]]

local endstates = require("game/endstates")
local npcManager = require("npcManager")

local megashroom = require("npcs/ai/megashroom")
local starman = require("npcs/ai/starman")

local playerManager = require("playerManager")
local textplus = require("textplus")

local goalTape = {}

goalTape.idList = {}
goalTape.idMap = {}

goalTape.playerInfo = {}

goalTape.victoryPoses = {}


goalTape.COLLISION_TYPE_TOUCH        = 0 -- (SMM)  Needs to touch the actual NPC to trigger the level exit.
goalTape.COLLISION_TYPE_TOUCH_REGION = 1 -- (SMM2) Needs to touch its "patrolling" region to trigger the level exit.
goalTape.COLLISION_TYPE_TOUCH_ABOVE  = 2 -- (SMW)  Needs to touch anywhere above the bottom of the "patrolling" region to trigger the level exit.


local STATE_RAISING  = 0
local STATE_LOWERING = 1


local colBox = Colliders.Box(0,0,0,0)

local irisShader = Shader()
irisShader:compileFromFile(nil, Misc.resolveFile("shaders/npc/goalTape_irisOut.frag"))


local collisionTypes = {
    [goalTape.COLLISION_TYPE_TOUCH]        = (function(v,p) return Colliders.collide(v,p) end),
    [goalTape.COLLISION_TYPE_TOUCH_REGION] = (function(v,p)
        local data = v.data._basegame

        colBox.x = v.x
        colBox.y = data.top
        colBox.width = v.width
        colBox.height = data.bottom - data.top

        return Colliders.collide(colBox,p)
    end),
    [goalTape.COLLISION_TYPE_TOUCH_ABOVE]  = (function(v,p)
        local data = v.data._basegame
        return (p.x+p.width > v.x and p.x < v.x+v.width and p.y <= data.bottom)
    end),
}

--local exitTypes = {[0] = 1,[1] = 2,[2] = 3,[3] = 4,[4] = 6,[5] = 7} -- From extra settings field to win state

goalTape.powerupNPCIDs = {
	[1] = {},
	[2] = {185,9,185,249},
	[3] = {183,14,182},
	[4] = {34},
	[5] = {160},
	[6] = {170},
	[7] = {264},

	extraLife = 187,

	starman = 293,
	mega = 425,
}

goalTape.text = {
    results = {
        font = textplus.loadFont("textplus/font/1.ini"),
        xscale = 1,yscale = 1,

        courseClear = "COURSE CLEAR!",
        timeCountdown = "@%d*%d=%d", -- The first "%d" is replaced by the amount of time, the second is replaced by the time multiplier, and the third is replaced by the score. @ is the clock in the default font used for the results.
    },

    characterNames = {
        font = textplus.loadFont("textplus/font/smw-results.ini"),
        xscale = 2,yscale = 2,

        useCostumeName = false, -- When enabled, the name of the player's costume will be used if they're using one.

        [CHARACTER_MARIO          ] = {name = "MARIO"           ,color = Color.fromHexRGBA(0xD83818FF)}, -- Red
        [CHARACTER_LUIGI          ] = {name = "LUIGI"           ,color = Color.fromHexRGBA(0x58F858FF)}, -- Green
        [CHARACTER_PEACH          ] = {name = "PEACH"           ,color = Color.fromHexRGBA(0xF85858FF)}, -- Pink-ish
        [CHARACTER_TOAD           ] = {name = "TOAD"            ,color = Color.fromHexRGBA(0xD83818FF)}, -- Red
        [CHARACTER_LINK           ] = {name = "LINK"            ,color = Color.fromHexRGBA(0x58F858FF)}, -- Green
        [CHARACTER_MEGAMAN        ] = {name = "MEGAMAN"         ,color = Color.fromHexRGBA(0x58A8F0FF)}, -- Blue
        [CHARACTER_WARIO          ] = {name = "WARIO"           ,color = Color.fromHexRGBA(0xF8D870FF)}, -- Yellow
        [CHARACTER_BOWSER         ] = {name = "BOWSER"          ,color = Color.fromHexRGBA(0x58F858FF)}, -- Green
        [CHARACTER_KLONOA         ] = {name = "KLONOA"          ,color = Color.fromHexRGBA(0x58A8F0FF)}, -- Blue
        [CHARACTER_NINJABOMBERMAN ] = {name = "NINJA BOMBERMAN" ,color = Color.fromHexRGBA(0xF85858FF)}, -- Pink-ish
        [CHARACTER_ROSALINA       ] = {name = "ROSALINA"        ,color = Color.fromHexRGBA(0x58A8F0FF)}, -- Blue
        [CHARACTER_SNAKE          ] = {name = "SNAKE"           ,color = Color.fromHexRGBA(0x58F858FF)}, -- Green
        [CHARACTER_ZELDA          ] = {name = "ZELDA"           ,color = Color.fromHexRGBA(0xF8D870FF)}, -- Yellow
        [CHARACTER_ULTIMATERINKA  ] = {name = "ULTIMATE RINKA"  ,color = Color.fromHexRGBA(0xD8A038FF)}, -- Gold
        [CHARACTER_UNCLEBROADSWORD] = {name = "UNCLE BROADSWORD",color = Color.fromHexRGBA(0xD8A038FF)}, -- Gold
        [CHARACTER_SAMUS          ] = {name = "SAMUS"           ,color = Color.fromHexRGBA(0xD8A038FF)}, -- Gold
        
        -- A2XT names
        --[CHARACTER_MARIO          ] = {name = "DEMO"            ,color = Color.fromHexRGBA(0x58A8F0FF)}, -- Blue
        --[CHARACTER_LUIGI          ] = {name = "IRIS"            ,color = Color.fromHexRGBA(0x58F858FF)}, -- Green
        --[CHARACTER_PEACH          ] = {name = "KOOD"            ,color = Color.fromHexRGBA(0xD8A038FF)}, -- Gold
        --[CHARACTER_TOAD           ] = {name = "RAOCOW"          ,color = Color.fromHexRGBA(0x58A8F0FF)}, -- Blue
        --[CHARACTER_LINK           ] = {name = "SHEATH"          ,color = Color.fromHexRGBA(0x58A8F0FF)}, -- Blue
    },
}

local textLayoutCache = {}
local function getTextLayout(text,font,xscale,yscale)
    textLayoutCache[text]                       = textLayoutCache[text]                       or {}
    textLayoutCache[text][font]                 = textLayoutCache[text][font]                 or {}
    textLayoutCache[text][font][xscale]         = textLayoutCache[text][font][xscale]         or {}
    textLayoutCache[text][font][xscale][yscale] = textLayoutCache[text][font][xscale][yscale] or textplus.layout(textplus.parse(text,{font = font,xscale = xscale,yscale = yscale}))

    return textLayoutCache[text][font][xscale][yscale]
end

local function stopSounds(info)
    if info.mainSound then
        info.mainSound:stop()
    end
    if info.irisOutSound then
        info.irisOutSound:stop()
    end

    if info.countdownStartSound then
        info.countdownStartSound:stop()
    end
    if info.countdownLoopSound then
        info.countdownLoopSound:stop()
    end
    if info.countdownEndSound then
        info.countdownEndSound:stop()
    end
end

local function resetPlayerInfo(k)
    local info = goalTape.playerInfo[k]

    if info then
        Defines.player_walkspeed = nil
        Defines.player_runspeed = nil

        stopSounds(info)

        Section(info.originalSection).musicID = info.originalSectionMusic

        Timer.hurryTime = info.priorHurryTime

        goalTape.playerInfo[k] = nil
    end
end


local configSettingsToCopy = {
    "doDarken","doIrisOut","useVictoryPoses","mainSFX","irisOutSFX","heldNPCsTransform",
    "displayCharacterName","displayCourseClear","doTimerCountdown","timerScoreMultiplier","timerCountdownSpeed",
    "countdownStartSFX","countdownLoopSFX","countdownEndSFX",
    "poseTime","startExitTime","pausesGame","isOrb",
}

function goalTape.startExit(args)
    if Level.winState() > 0 then
        return
    end


    local p = (args.player or player)

    local info = {}
    goalTape.playerInfo[p.idx] = info


    info.id = args.id or goalTape.idList[1]

    local config = NPC.config[info.id]

    -- Set up all the settings
    for _,name in ipairs(configSettingsToCopy) do
        if args[name] == nil then
            info[name] = config[name]
        else
            info[name] = args[name]
        end
    end

    info.direction = args.direction or DIR_RIGHT
    info.stopBehind = args.stopBehind or false

    info.exitType = (args.exitType or (info.isOrb and LEVEL_WIN_TYPE_SMB3ORB) or LEVEL_WIN_TYPE_TAPE)

    info.mainSFX = args.mainSFX or config.mainSFX
    info.irisOutSFX = args.irisOutSFX or config.irisOutSFX


    -- Some variables just for actually handling the exit
    info.timer = 0
    info.darkness = 0
    info.fadeOut = 0

    info.startX = args.startX or (p.x + p.width*0.5)

    info.mainSound = SFX.play(info.mainSFX)
    SFX.play(37)

    -- Mute music
    info.originalSection = p.section
    info.originalSectionMusic = p.sectionObj.musicID
    p.sectionObj.musicID = 0

    -- Timer stuff
    info.timerStart = Timer.getValue()
    info.timerScore = 0
    info.priorHurryTime = Timer.hurryTime


    if p.holdingNPC and info.heldNPCsTransform then -- If the player is holding an NPC, transform it into a something else
        -- Determine the ID that it should be transformed into (this should be fairly accurate to the original)
        local id
        if table.ifind(goalTape.powerupNPCIDs[p.powerup],p.reservePowerup) then -- If the player has their current powerup in the reserve box, give an extra life
            id = goalTape.powerupNPCIDs.extraLife or 90
        elseif #goalTape.powerupNPCIDs[p.powerup] > 0 then -- Give the player another of their current powerup, if we have one
            id = goalTape.powerupNPCIDs[p.powerup][1]
        else -- Otherwise, give them a mushroom
            id = goalTape.powerupNPCIDs[2][1] or 9
        end

        if id then
            local e = Effect.spawn(10,0,0)
            e.x,e.y = (p.holdingNPC.x+(p.holdingNPC.width/2)-(e.width/2)),(p.holdingNPC.y+(p.holdingNPC.height/2)-(e.height/2))

            SFX.play(34)

            p.holdingNPC:transform(id,true,false)

            p.holdingNPC.direction = info.direction
            p.holdingNPC.dontMove = true

            p.holdingNPC.speedX = info.direction*0.9
            p.holdingNPC.speedY = -10

            -- Reset a bunch of different NPC values related to being grabbed
            p.holdingNPC:mem(0x12C,FIELD_WORD,0)
            --p.holdingNPC:mem(0x12E,FIELD_WORD,0)
            --p.holdingNPC:mem(0x130,FIELD_WORD,0)
            --p.holdingNPC:mem(0x132,FIELD_WORD,0)
            p.holdingNPC:mem(0x134,FIELD_WORD,0)
            p.holdingNPC:mem(0x136,FIELD_BOOL,true)

            p:mem(0x154,FIELD_WORD,0)
        end
    end

    megashroom.StopMega(p,true)
    starman.stop(p)

    
    endstates.setProperties(LEVEL_END_STATE_SMW, {
        pauseGame = info.pausesGame,
        levelEndDelay = 9999999 -- done manually
    })
    Level.endState(LEVEL_END_STATE_SMW)

    if info.pausesGame then
        Misc.pause(true)
    elseif not info.isOrb then
        Misc.npcToCoins()
    end

    -- boring thing to "remove" other players, replicated from the source code
    for _,o in ipairs(Player.get()) do
        if o.idx ~= p.idx then
            o.section = p.section
            o.x = (p.x+(p.width/2)-(o.width/2))
            o.y = (p.y+p.height-o.height)
            o.speedX,o.speedY = 0,0
            o.forcedState,o.forcedTimer = 8,-p.idx
        else -- reset speed like in smw
            o.speedX = 0
        end
    end

    return info
end


local function updatePlayerStuff(p,fromOnDraw)
    local info = goalTape.playerInfo[p.idx]

    if info == nil then
        return
    end

    if info.pausesGame ~= fromOnDraw then
        return
    end

    if (p.deathTimer > 0 or p:mem(0x13c,FIELD_BOOL)) and not info.pausesGame then
        stopSounds(info)
        return
    end


    info.timer = info.timer + 1

    -- Disable player input
    for w,_ in pairs(p.keys) do
        p.keys[w] = false
    end


    if info.timer > info.poseTime and info.timer < info.startExitTime then
        if not info.pausesGame then
            p.speedX = 0
        end
    elseif info.timer == info.startExitTime then
        if info.doIrisOut then
            info.irisOutSound = SFX.play(info.irisOutSFX)
            info.irisOutRadius = math.max(camera.width,camera.height)
        end
        
        info.savedCameraPos = {camera.x,camera.y}
    else
        if info.timer > info.startExitTime then
            if info.doIrisOut then
                info.irisOutRadius = math.max(0,info.irisOutRadius - 10)
            else
                info.fadeOut = math.min(1, info.fadeOut + 0.03)
            end

            if info.fadeOut >= 1 or (info.doIrisOut and info.irisOutRadius < 2) then
                -- Exit level
                Level.exit(info.exitType)
                Misc.unpause()

                Checkpoint.reset()
            end

            Defines.player_walkspeed = nil
            Defines.player_runspeed = nil
        else
            if playerManager.getBaseID(p.character) == CHARACTER_LINK then
                Defines.player_runspeed = 1.5
            else
                Defines.player_walkspeed = 1.5
            end
        end

        if not info.pausesGame then
            if not info.stopBehind or ((info.direction == DIR_RIGHT and (p.x+(p.width/2)) < info.startX+160) or (info.direction == DIR_LEFT and (p.x+(p.width/2)) > info.startX-160)) then
                if info.direction == DIR_LEFT then
                    p.keys.left = KEYS_DOWN
                elseif info.direction == DIR_RIGHT then
                    p.keys.right = KEYS_DOWN
                end

                p.speedX = p.speedX * 0.9 -- slower walk speed
            else
                p.direction = -info.direction
                p.speedX = 0
            end
        end
    end

    -- Timer countdown
    if info.doTimerCountdown and info.timer > 224 and Timer.isActive() then
        Timer.hurryTime = -1

        local speed = math.ceil(info.timerStart / info.timerCountdownSpeed)
        local score = (info.timerScoreMultiplier*math.min(speed,Timer.getValue()))

        SaveData._basegame.hud.score = SaveData._basegame.hud.score + score
        info.timerScore = info.timerScore + score

        Timer.set(math.max(0,Timer.getValue()-speed))

        -- Sound effect logic
        if info.countdownStartSFX and info.countdownLoopSFX and info.countdownEndSFX then
            if not info.countdownStartSound then
                info.countdownStartSound = SFX.play{sound = info.countdownStartSFX}
            elseif not info.countdownStartSound:isPlaying() and not info.countdownLoopSound then
                info.countdownLoopSound = SFX.play{sound = info.countdownLoopSFX,loops = 0}
            elseif info.countdownLoopSound and not info.countdownEndSound and Timer.getValue() == 0 then
                info.countdownLoopSound:stop()
                info.countdownEndSound = SFX.play{sound = info.countdownEndSFX}
            end
        end
    end

    -- Darken
    if info.doDarken and info.timer > 464 and not info.pausesGame then
        info.darkness = math.max(0,info.darkness - 0.006)
    elseif info.doDarken then
        info.darkness = math.min(1,info.darkness + 0.0075)
    end

    -- Victory pose!
    local victoryPoses = goalTape.victoryPoses[p:getCostume()] or goalTape.victoryPoses[p.character]

    if info.timer > info.poseTime and victoryPoses ~= nil and info.useVictoryPoses and not p:mem(0x12E,FIELD_BOOL) and (p.speedX == 0 or info.pausesGame) and (p:isOnGround() or p.mount == MOUNT_CLOWNCAR or info.pausesGame) then
        if p.mount == MOUNT_YOSHI then
            if victoryPoses.frameOnYoshi ~= nil then
                p:setFrame(victoryPoses.frameOnYoshi)
            end
        else
            if victoryPoses.normalFrame ~= nil then
                p:setFrame(victoryPoses.normalFrame)
            end
        end
    end
end



function goalTape.registerVictoryPose(characterOrCostume, normalFrame,frameOnYoshi)
    if type(characterOrCostume) == "string" then -- costume
        characterOrCostume = characterOrCostume:upper()
    end

    goalTape.victoryPoses[characterOrCostume] = {
        normalFrame = normalFrame,
        frameOnYoshi = frameOnYoshi,
    }
end


function goalTape.register(id)
    npcManager.registerEvent(id,goalTape,"onTickNPC")

    table.insert(goalTape.idList,id)
    goalTape.idMap[id] = true
end

function goalTape.onInitAPI()
    registerEvent(goalTape,"onTick")
    registerEvent(goalTape,"onCameraUpdate","onCameraUpdate",false)
    registerEvent(goalTape,"onDraw")
    registerEvent(goalTape,"onFramebufferResize")
end


function goalTape.onTick()
    for k,v in ipairs(Player.get()) do
        updatePlayerStuff(v,false)
    end
end


function goalTape.onCameraUpdate()
    for k,v in ipairs(Player.get()) do
        local info = goalTape.playerInfo[k]

        if info and info.savedCameraPos then
            camera.x = info.savedCameraPos[1]
            camera.y = info.savedCameraPos[2]
        end
    end
end


function goalTape.onDraw()
    for k,v in ipairs(Player.get()) do
        local info = goalTape.playerInfo[k]

        if info then
            updatePlayerStuff(v,true)

            if info.darkness > 0 then
                local darknessPriority = (info.pausesGame and 0.5) or -6

                Graphics.drawBox{x=0,y=0,width=camera.width,height=camera.height,color=Color.black.. info.darkness,priority = darknessPriority - 0.1}
                v:render{color=Color.white.. info.darkness,priority = darknessPriority}
            end

            if info.irisOutRadius and info.doIrisOut then
                local center = vector(v.x + v.width*0.5 - camera.x,v.y + v.height*0.5 - camera.y)

                if v.mount == 2 then
                    center.y = (v.y-camera.y)
                end


                Graphics.drawBox{
                    width = camera.width,height = camera.height,
                    x = 0,y = 0,
                    
                    priority = 6,shader = irisShader,
                    color = Color.black,
                    
                    uniforms = {
                        radius = info.irisOutRadius,
                        center = center,
                    },
                }
            elseif info.fadeOut > 0 then
                Graphics.drawScreen{priority = 6,color = Color.black.. info.fadeOut}
            end

            if info.timer > 160 then
                local y = 160

                if goalTape.text.characterNames and info.displayCharacterName then
                    local color = Color.white
                    local text = "PLAYER"
                    
                    if goalTape.text.characterNames.useCostumeName and Player.getCostume(v.character) ~= nil then
                        color = goalTape.text.characterNames[v.character].color or color
                        text = Player.getCostume(v.character)
                    elseif goalTape.text.characterNames[v.character] then
                        color = goalTape.text.characterNames[v.character].color or color
                        text = goalTape.text.characterNames[v.character].name or text
                    end

                    local layout = getTextLayout(text,goalTape.text.characterNames.font,goalTape.text.characterNames.xscale,goalTape.text.characterNames.yscale)

                    textplus.render{
                        layout = layout,color = color,priority = 5,
                        x = (camera.width/2)-(layout.width/2),y = y,
                    }

                    y = y + layout.height + (8*(goalTape.text.characterNames.yscale or 1))
                end

                if goalTape.text.results and goalTape.text.results.courseClear and info.displayCourseClear then
                    local layout = getTextLayout(goalTape.text.results.courseClear,goalTape.text.results.font,goalTape.text.results.xscale,goalTape.text.results.yscale)

                    textplus.render{
                        layout = layout,color = color,priority = 5,
                        x = (camera.width/2)-(layout.width/2),y = y,
                    }

                    y = y + layout.height + (16*(goalTape.text.characterNames.yscale or 1))
                end
                if goalTape.text.results and goalTape.text.results.timeCountdown and (info.doTimerCountdown and Timer.isActive()) then
                    local layout = getTextLayout(goalTape.text.results.timeCountdown:format(info.timerStart,info.timerScoreMultiplier,info.timerScore),goalTape.text.results.font,goalTape.text.results.xscale,goalTape.text.results.yscale)

                    textplus.render{
                        layout = layout,color = color,priority = 5,
                        x = (camera.width/2)-(layout.width/2),y = y,
                    }
                end
            end
        end
    end
end


function goalTape.onTickNPC(v)
	if Defines.levelFreeze then return end
    
    local config = NPC.config[v.id]
    local data = v.data._basegame
    
    local settings = v.data._settings
	
	if v:mem(0x12A, FIELD_WORD) <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
        data.initialized = true
        
        if config.isOrb then
            data.oldSpeedY = 0

            if settings.noGravity then
                v.noblockcollision = true
            end
        else
            data.state = STATE_LOWERING
            
            data.top = (v.y+v.height)

            -- Get position of bottom. Goes down in intervals of 8 and will stop upon reaching the bottom of the section.
            for y=(v.y+v.height),Section(v.section).boundary.bottom,8 do
                colBox.x,colBox.y = v.x,y-8
                colBox.width,colBox.height = v.width,8

                for _,w in ipairs(Colliders.getColliding{
                    a = colBox,
                    b = Block.SOLID.. Block.SEMISOLID.. Block.PLAYER.. Block.SLOPE,
                    btype = Colliders.BLOCK,
                }) do
                    data.bottom = w.y
                    break
                end

                if data.bottom then break end -- Stop if a block was hit
            end

            data.bottom = data.bottom or Section(v.section).boundary.bottom
        end
    end



    if config.isOrb then
        if RNG.randomInt(1,30) == 1 then
            local e = Effect.spawn(80, v.x + RNG.randomInt(0,v.width), v.y + RNG.randomInt(0,v.height))

            e.x = e.x - e.width *0.5
            e.y = e.y - e.height*0.5
        end
    end


	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then return end


    -- Move with layers
    local layerObj = v.layerObj

    if layerObj ~= nil and not layerObj:isPaused() and (not config.isOrb or settings.noGravity) then
        v.x = v.x + layerObj.speedX
        v.y = v.y + layerObj.speedY

        if not config.isOrb then
            data.top    = data.top    + layerObj.speedY
            data.bottom = data.bottom + layerObj.speedY
        end
    end

	
    -- Up/down movement
    if not config.isOrb then
        if data.state == STATE_RAISING then
            v.speedY = -config.movementSpeed

            if (v.y+v.height) <= data.top then
                data.state = STATE_LOWERING
            end
        elseif data.state == STATE_LOWERING then
            v.speedY = config.movementSpeed

            if (v.y+v.height) >= data.bottom then
                data.state = STATE_RAISING
            end
        end
    else
        if not settings.noGravity then
            if v.collidesBlockBottom then
                if data.oldSpeedY > 1 then
                    v.speedX = v.speedX * 0.4
                    v.speedY = -data.oldSpeedY*0.4
                else
                    v.speedX = 0
                end
            end

            data.oldSpeedY = v.speedY
        else
            if v.underwater then
                v.speedY = -Defines.npc_grav*0.2
            else
                v.speedY = -Defines.npc_grav
            end
        end
    end



    if v.friendly then return end
    for k,p in ipairs(Player.get()) do
        if (p.forcedState == 0 and p.deathTimer == 0 and not p:mem(0x13C,FIELD_BOOL)) then
            if (not config.isOrb and collisionTypes[config.requiredCollisionType](v,p)) or (config.isOrb and Colliders.collide(v,p)) then
                goalTape.startExit{id = v.id,direction = v.direction,player = p,startX = v.x + v.width*0.5,stopBehind = settings.stopBehind,exitType = config.winType}

                if not config.isOrb then
                    if (p.y + p.height >= v.y and p.y <= v.y + config.height) then
                        local tapeHitHeight = math.invlerp(data.bottom, data.top, v.y)
                        local score = math.ceil(tapeHitHeight * 9)
                        Misc.givePoints(score, vector(v.x + 0.5 * v.width, v.y), false)
                    elseif not config.pausesGame then
                        -- Turn into a coin
                        local e = Effect.spawn(10, v.x + v.width*0.5, v.y + v.height*0.5)

                        e.x = e.x - e.width *0.5
                        e.y = e.y - e.height*0.5

                        local e = Effect.spawn(11, v.x + v.width*0.5, v.y + v.height*0.5)

                        --e.x = e.x - e.width *0.5
                        e.y = e.y - e.height*0.5

                        -- Grant a coin
                        Misc.coins(1)
                        SFX.play(14)
                    end
                end

                v:kill(HARM_TYPE_VANISH)
            end
        end
    end
end


return goalTape