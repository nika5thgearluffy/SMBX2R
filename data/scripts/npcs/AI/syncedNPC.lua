local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local synced = require("blocks/ai/synced")

local syncedNPC = {}


syncedNPC.idList = {}
syncedNPC.idMap  = {}

syncedNPC.idSettingsMap = {}

function syncedNPC.register(npcID,switchstate)
    if switchstate == true then
        switchstate = 2
    elseif switchstate == false then
        switchstate = 1
    end
    npcManager.registerEvent(npcID,syncedNPC,"onTickNPC")
    npcManager.registerEvent(npcID,syncedNPC,"onDrawNPC")

    table.insert(syncedNPC.idList,npcID)
    syncedNPC.idMap[npcID] = true

    -- Set up settings
    local config = NPC.config[npcID]

    syncedNPC.idSettingsMap[npcID] = {
        switchstate = switchstate,
        defaultTangible = switchstate == 1,

        playerblock = config.playerblock,
        playerblocktop = config.playerblocktop,
        npcblock = config.npcblock,
        npcblocktop = config.npcblocktop,
    }
end


local function isIntangible(id)
    return syncedNPC.idSettingsMap[id].switchstate ~= synced.state
end


function syncedNPC.onTickNPC(v)
    if v.despawnTimer <= 0 then
        return
    end

    -- Set the friendly flag if intangible
    local data = v.data._basegame

    if data.defaultFriendly == nil then
        data.defaultFriendly = v.friendly
    end

    v.friendly = (data.defaultFriendly or isIntangible(v.id))
end


function syncedNPC.onDrawNPC(v)
    if v.despawnTimer <= 0 then
        return
    end

    -- Add to the frames if currently intangible. npcutils.restoreAnimation will reset it in onDrawEnd
    npcutils.restoreAnimation(v)

    if isIntangible(v.id) then
        v.animationFrame = v.animationFrame + npcutils.getTotalFramesByFramestyle(v)
    end
end


-- For setting NPC config flags depending on state,
-- because for some reason NPC's still interact with platforms that are friendly,
-- while the player just doesn't. Cool!
local function updateConfigFlags()
    for _,npcID in ipairs(syncedNPC.idList) do
        local settings = syncedNPC.idSettingsMap[npcID]
        local config = NPC.config[npcID]

        if isIntangible(npcID) then
            config.playerblock = false
            config.playerblocktop = false
            config.npcblock = false
            config.npcblocktop = false
        else
            config.playerblock = settings.playerblock
            config.playerblocktop = settings.playerblocktop
            config.npcblock = settings.npcblock
            config.npcblocktop = settings.npcblocktop
        end
    end
end


function syncedNPC.onSyncSwitch(state)
    updateConfigFlags()
end

function syncedNPC.onStart()
    updateConfigFlags()
end


function syncedNPC.onInitAPI()
    registerEvent(syncedNPC,"onSyncSwitch")
    registerEvent(syncedNPC,"onStart")
end


return syncedNPC