--blockManager.lua
--v1.0.5
--Created by Horikawa Otane, 2016
local expandedDefs = require("expandedDefines");
local eventmanager = require("base/game/blockeventmanager");

local blockManager = {}

function blockManager.setBlockSettings(settingsArray)
	local id = settingsArray.id
	for blockCode, blockValue in pairs(settingsArray) do
		blockCode = blockCode:lower();
		if blockCode ~= "id" then
			Block.config[id]:setDefaultProperty(blockCode, blockValue)
		end
	end
	return Block.config[id]
end

function blockManager.getBlockSettings(id)
	return Block.config[id];
end

function blockManager.registerDefines(id, typelist)
	expandedDefs.registerBlock(id, typelist);
end

function blockManager.deregisterDefines(id, typelist)
	expandedDefs.deregisterBlock(id, typelist);
end

function blockManager.registerEvent(id, tbl, eventName, libEventName)
	libEventName = libEventName or eventName;
	local en = eventName:match("^(.+)Block$");
	if(en == nil or expandedDefs.LUNALUA_EVENTS_MAP[en] == nil) then
		error("No event "..eventName.." was found!", 2);
	end
	
	if(type(id) == "table") then
		for _,v in ipairs(id) do
			eventmanager.register(v, tbl, en, libEventName);
		end
	elseif(type(id) == "number") then
		eventmanager.register(id, tbl, en, libEventName);
	else
		error("No matching overload found. Candidates: registerEvent(int id, table apiTable, string eventName), registerEvent(int id, table apiTable, string eventName, string libEventName), registerEvent(table idList, table apiTable, string eventName), registerEvent(table idList, table apiTable, string eventName, string libEventName)")
	end
	
end
if (Block ~= nil) then
	Block.registerEvent = blockManager.registerEvent
end

blockManager.refreshEvents = eventmanager.refreshEvents;
blockManager.callExternalEvent = eventmanager.callExternalEvent

-- needs to be called from 
local function blockEnvironmentCallback(name, env)
	local id = tonumber(name)
	env.BLOCK_ID = id
	
	env.Block = setmetatable({
		registerEvent = function(arg1, arg2, arg3, arg4)
			if (type(arg1) == "number") then
				blockManager.registerEvent(arg1, arg2, arg3, arg4)
			else
				blockManager.registerEvent(id, arg1, arg2, arg3)
			end
		end
	}, {
		__index = Block,
		__call = function(obj, arg) return Block(arg) end
	})
end

local doneLoadingBlockCode = false
local overriddenIDs = {}

function blockManager.loadBlockCode()
	-- Be sure to only run once
	if (doneLoadingBlockCode) then
		return
	end
	doneLoadingBlockCode = true
	
	local require_utils = require("require_utils")
	local string_gsub = string.gsub
	
	local relEpisodePath = require_utils.normalizeRelPath(Misc.episodePath())
	
	local basegameBlockPath = string_gsub(getSMBXPath(), ";", "<") .. "\\scripts\\blocks\\block-?.lua;"
	local basegameBlockRequire = require_utils.makeRequire(
		basegameBlockPath, -- Path
		Misc.getBasegameEnvironment(),  -- Global table
		{}, -- Loaded Table
		false, -- Share globals
		false,  -- Assign require
		nil, function() return nil end,
		blockEnvironmentCallback
    )
	
	local customBlockPath = (
			string_gsub(__customFolderPath, ";", "<") .. "block-?.lua;" ..
			string_gsub(__episodePath, ";", "<") .. "block-?.lua"
	)

	local customBlockRequire = require_utils.makeRequire(
		customBlockPath, -- Path
		Misc.getCustomEnvironment(),  -- Global table
		{}, -- Loaded Table
		false, -- Share globals
		false,  -- Assign require
		nil, function() return nil end,
		blockEnvironmentCallback,
		nil, true
    )

    local debugstats = require("base\\engine\\debugstats")

    -- Check which IDs have custom files first
    for id = 1, BLOCK_MAX_ID do
        local lib, pth = customBlockRequire(tostring(id))
        if lib ~= nil then
            overriddenIDs[id] = true
            debugstats.add(require_utils.normalizeRelPath(pth, relEpisodePath))
        end
    end

    -- Load blocks, using custom version if available, basegame otherwise
    for id = 1, BLOCK_MAX_ID do
        local lib
        if overriddenIDs[id] then
            -- Use custom file, skip basegame entirely
            lib = customBlockRequire(tostring(id))
        else
            -- No custom file, use basegame
            lib = basegameBlockRequire(tostring(id))
        end

        if (type(lib) == "table") and (lib.onInitAPI ~= nil) then
            lib.onInitAPI()
        end
    end
end

function blockManager.isOverridden(id)
    return overriddenIDs[id] == true
end

function blockManager.getActiveLib(id)
    if overriddenIDs[id] then
        return customBlockRequire(tostring(id))
    end
    return basegameBlockRequire(tostring(id))
end

return blockManager