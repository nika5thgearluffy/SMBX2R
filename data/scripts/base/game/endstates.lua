local endstates = {}

local lastEndState = 0
local levelEndTimer = 0

-- A player object that the end sequence player movement runs for
local specificPlayer = nil

local additionalEndStatesList = nil
additionalEndStatesList = {
    [LEVEL_END_STATE_SWITCHPALACE] = {
        lockInputs = true,
        forceInputs = {},
        levelEndDelay = 720,
        pauseGame = false,
        winType = LEVEL_WIN_TYPE_SWITCHPALACE
    },
    [LEVEL_END_STATE_FLAGPOLE] = {
        lockInputs = true,
        forceInputs = {right = true},
        levelEndDelay = 500,
        pauseGame = false,
        winType = LEVEL_WIN_TYPE_FLAGPOLE,
        onTick = function()
            for k,v in BGO.iterateIntersecting(specificPlayer.x, specificPlayer.y, specificPlayer.x + specificPlayer.width, specificPlayer.y + specificPlayer.height) do
                if v.id == 16 or v.id == 17 then
                    local dist = vector(specificPlayer.x + 0.5 * specificPlayer.width - v.x - 0.5 * v.width, specificPlayer.y + specificPlayer.height - v.y - v.height)
                    if dist.length < 6 and specificPlayer:isOnGround() then
                        additionalEndStatesList[9].forceInputs = {}
                        specificPlayer.speedX = 0
                        specificPlayer.forcedState = 8
                    end
                end
            end
        end
    },
    [LEVEL_END_STATE_SMW] = {
        lockInputs = true,
        forceInputs = {},
        levelEndDelay = 900,
        pauseGame = true,
        winType = LEVEL_WIN_TYPE_SMWORB
    }
}


function endstates.setProperties(endState, args)
    for k,v in pairs(args) do
        additionalEndStatesList[endState][k] = args[k]
    end
end

-- Can be used to edit end states
function endstates.get(idx)
    return additionalEndStatesList[idx]
end

function endstates.setPlayer(p)
    specificPlayer = p
end

function endstates.onInputUpdate()
    if additionalEndStatesList[Level.endState()] then
        local e = additionalEndStatesList[Level.endState()]

        if e.pauseGame and not Misc.isPaused() then
            Misc.pause()
        end

        if e.lockInputs then
            for k,p in ipairs(Player.get()) do
                for i, _ in pairs(p.keys) do
                    if specificPlayer == nil or specificPlayer == p then
                        p.keys[i] = e.forceInputs[i] or false
                    else
                        p.keys[i] = false
                    end
                end
            end
        end
        levelEndTimer = levelEndTimer + 1

        if e.onTick then
            e.onTick()
        end

        if levelEndTimer >= e.levelEndDelay then
            Level.exit(e.winType)
        end
    else
        levelEndTimer = 0
    end

    lastEndState = Level.endState()
end

registerEvent(endstates, "onInputUpdate")

return endstates