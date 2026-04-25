local aiextensions = {}

local npcManager = require("npcManager")

local tableinsert = table.insert
local map = {}
local flagList = {}

function aiextensions.bind(flag, aiTable, eventname, eventalias)
    tableinsert(flagList, flag)
    map[flag] = {e = eventname, ea = eventalias, t = aiTable}
end

function aiextensions.onStart()
    local cfg
    local flagIDs = {}
    for i=1, NPC_MAX_ID do
        cfg = NPC.config[i]
        for k,v in ipairs(flagList) do
            if cfg[v] then
                flagIDs[v] = flagIDs[v] or {}
                tableinsert(flagIDs[v], i)
            end
        end
    end

    for k,v in ipairs(flagList) do
        npcManager.registerEvent(flagIDs[v], map[v].t, map[v].e, map[v].ea)
    end
end

registerEvent(aiextensions, "onStart", "onStart", true)

return aiextensions