--made by core
--THANKS TO MDA FOR FEATURE SUGGESTIONS AND ALLLL FIELDS

local Events = {__type = "Events"}

local mem = mem
local readmem = readmem

local ffi_utils = require("ffi_utils")

----------------------
-- MEMORY ADDRESSES --
----------------------
local GM_EVENTS_ADDR = mem(0x00B2C6CC,FIELD_DWORD)
local GM_EVENTS_STRUCT_SIZE = 0x588
local MAX_EVENTS = (255 - 1)

-----------------------------
-- CONVERSIONS AND GETTERS --
-----------------------------
local function eventGetIdx(event)
	return event._idx
end

local function eventGetIsValid(event)
	if (mem(event._ptr + 0x04, FIELD_STRING) == "") then return false end
	
	local idx = event._idx

	if (idx >= 0) and (idx <= MAX_EVENTS) then
		return true
	end

	return false
end

local function moveLayerToObj(layerName)
	if (layerName == "") then return Layer(Layer.count()) end
	
	return Layer.get(layerName)
end

local function moveObjToLayer(layerObj)
	if (layerObj == nil) then
		return ""
	end
	
	return layerObj.layerName
end

local function sectionToSectionObj(idx)
	if (idx >= 21) then
		return nil
	end
	return Section(idx)
end

local function newTable(offset, dtype, pos, mult)
	local ev = {}
	
	return function(event)
		if not ev[event._idx] then
			local address = (event._ptr + offset)
			local pos = (pos or 0)
			local mult = (mult or 1)
			
			ev[event._idx] = setmetatable({}, {
				__index = function(_, idx)
					return mem(address + (idx + pos) * mult, dtype)
				end,
				
				__newindex = function(_, idx, value)
					return mem(address + (idx + pos) * mult, dtype, value)
				end,
			})
		end
		
		return ev[event._idx]
	end
end

local layersToHideTable   = newTable(0x0C, FIELD_STRING, -1, 4)
local layersToShowTable   = newTable(0x60, FIELD_STRING, -1, 4)
local layersToToggleTable = newTable(0xB4, FIELD_STRING, -1, 4)

local getMusicSections    = newTable(0x108, FIELD_WORD, 0, 2)
local getBgSections       = newTable(0x132, FIELD_WORD, 0, 2)
local getMusicPaths
do
	local ev = {}
	
	getMusicPaths = function(event)
		if not ev[event._idx] then
			ev[event._idx] = setmetatable({}, {
				__index = function(self, idx)
					return Section(idx).musicPath
				end,
			})
		end
		
		return ev[event._idx]
	end
end

local getPositionLeft   = newTable(0x15C, FIELD_DFLOAT, 0, 48)
local getPositionTop    = newTable(0x15C + 8, FIELD_DFLOAT, 0, 48)
local getPositionRight  = newTable(0x15C + 16, FIELD_DFLOAT, 0, 48)
local getPositionBottom = newTable(0x15C + 24, FIELD_DFLOAT, 0, 48)

local getActions

do
	local ev = {}
	
	getActions = function(event)
		if not ev[event._idx] then
			ev[event._idx] = {}
		end
		
		return ev[event._idx]
	end
end

local function getName(event)
	return mem(event._ptr + 0x04, FIELD_STRING)
end

local function setName(self, newName)
	for _, event in ipairs(Events.get()) do
		if mem(event._ptr + 0x04, FIELD_STRING) == newName then
			Misc.warn('Could not set Event name. "' .. newName .. '" is already taken.')
			break
		end
	end
	
	return mem(self._ptr + 0x04, FIELD_STRING, newName)
end

local getPosition

do
	local keys = {
		left = 'positionLeft',
		right = 'positionRight',
		top = 'positionTop',
		bottom = 'positionBottom',
	}
	
	getPosition = function(event)
		local pos = rawget(event, 'position')
		
		if pos then
			return pos
		end
		
		local sections = setmetatable({}, {
			__index = function(self, idx)
				local positionMT = {
					__index = function(self, key)
						return event[keys[key]][idx]
					end,
					
					__newindex = function(self, key, val)
						event[keys[key]][idx] = val
					end,
				}
				
				rawset(self, idx, setmetatable({}, positionMT))
				return rawget(self, idx)
			end,
			
			__newindex = function(self, idx, val)
				if type(val) == 'table' then
					event.positionLeft[idx] = val.left or val[1]
					event.positionRight[idx] = val.right or val[3]
					event.positionTop[idx] = val.top or val[2]
					event.positionBottom[idx] = val.bottom or val[4]
				else
					error("Cannot set `position` to other type!")
				end
			end,
		})
		
		rawset(event, 'position', sections)
		return sections
	end
end

------------------------
-- FIELD DECLARATIONS --
------------------------
local EventsFields = {
	idx                     = {get = eventGetIdx, readonly = true, alwaysValid = true},
	isValid                 = {get = eventGetIsValid, readonly = true, alwaysValid = true},
	name                    = {get = getName, set = setName},
	
	noSmok                  = {0x00, FIELD_BOOL},
	soundID                 = {0x02, FIELD_WORD},
	msg                     = {0x08, FIELD_STRING},
	endGameType             = {0x54C, FIELD_WORD},
	
	moveLayer               = {0x570, FIELD_STRING},
	moveLayerObj            = {0x570, FIELD_STRING, decoder = moveLayerToObj, encoder = moveObjToLayer},
	moveLayerSpeedX         = {0x574, FIELD_FLOAT},
	moveLayerSpeedY         = {0x578, FIELD_FLOAT},
	
	layersToHide            = {get = layersToHideTable, readonly = true},
	layersToShow            = {get = layersToShowTable, readonly = true},
	layersToToggle          = {get = layersToToggleTable, readonly = true},
	
	triggerEvent            = {0x550, FIELD_STRING},
	triggerDelay            = {0x554, FIELD_DFLOAT},
	autostart               = {0x586, FIELD_BOOL},
	autorun                 = {0x586, FIELD_BOOL}, -- alias
	
	controlUp               = {0x55C, FIELD_BOOL},
	controlDown             = {0x55C + 2, FIELD_BOOL},
	controlLeft             = {0x55C + 4, FIELD_BOOL},
	controlRight            = {0x55C + 6, FIELD_BOOL},
	controlJump             = {0x55C + 8, FIELD_BOOL},
	controlAltJump          = {0x55C + 10, FIELD_BOOL},
	controlAltRun           = {0x55C + 12, FIELD_BOOL},
	controlDropItem         = {0x55C + 14, FIELD_BOOL},
	controlPause            = {0x55C + 16, FIELD_BOOL},
	
	sectionMusicPath        = {get = getMusicPaths, readonly = true},
	sectionMusic            = {get = getMusicSections, readonly = true},
	sectionBg               = {get = getBgSections, readonly = true},
	
	position                = {get = getPosition, readonly = true},
	positionLeft            = {get = getPositionLeft, readonly = true},
	positionTop             = {get = getPositionTop, readonly = true},
	positionRight           = {get = getPositionRight, readonly = true},
	positionBottom          = {get = getPositionBottom, readonly = true},
	
	autoscrollSection       = {0x584, FIELD_WORD},
	autoscrollSectionObj    = {0x584, FIELD_WORD, decoder = sectionToSectionObj, readonly = true},
	autoscrollSpeedX        = {0x57c, FIELD_FLOAT},
	autoscrollSpeedY        = {0x580, FIELD_FLOAT},
	
	actions                 = {get = getActions, readonly = true},
}

-----------------------
-- CLASS DECLARATION --
-----------------------
local EventsMT = ffi_utils.implementClassMT("Events", Events, EventsFields, eventGetIsValid)
local EventsCache = {}

-- Constructor
setmetatable(Events, {__call = function(_, idx)
	if EventsCache[idx] then
		return EventsCache[idx]
	end
	
	local event = {_idx = idx, _ptr = GM_EVENTS_ADDR + (idx * GM_EVENTS_STRUCT_SIZE), __type = Events.__type}
	setmetatable(event, EventsMT)
	
	EventsCache[idx] = event
	return event
end})

-------------------------
-- METHOD DECLARATIONS --
-------------------------

-- 'mem' implementation
function Events:mem(offset, dtype, val)
	if not eventGetIsValid(self) then
		error("Invalid Event")
	end
	
	return mem(self._ptr + offset, dtype, val)
end

function Events:addAction(f, ...)
	local args = {...}
	
	self.actions[#self.actions + 1] = function()
		return f(unpack(args))
	end
end

function Events:addRoutine(f, ...)
    self:addAction(function(...)
        Routine.run(f, ...)
    end, ...)
end

function Events:positionSection(idx, x1, y1, x2, y2)
	self.positionLeft[idx] = x1
	self.positionTop[idx] = y1
	self.positionRight[idx] = x2
	self.positionBottom[idx] = y2
end

function Events:trigger()
	return triggerEvent(self.name)
end

Events.run = Events.trigger -- alias

--------------------
-- STATIC METHODS --
--------------------
function Events.count()
	for idx = 0, MAX_EVENTS do
		if readmem(GM_EVENTS_ADDR + (idx * GM_EVENTS_STRUCT_SIZE) + 0x04, FIELD_STRING) == "" then 
			return idx
		end
	end
	
	return 0
end

function Events.add(name, triggerEvent, triggerDelay, autorun)
	assert(name ~= nil, "Could not create Event with name of type nil.")
	local count = Events.count()

	if count <= MAX_EVENTS then
		local ev = Events(count)
		
		ev.name = name
		ev.triggerEvent = triggerEvent or ""
		ev.triggerDelay = triggerDelay or 0
		ev.autorun = autorun or false
		
		return ev
	else
		Misc.warn("Could not create Event. Event limit " .. (MAX_EVENTS + 1) .. " exceeded.")
	end
end

do
	local getMT = {__pairs = ipairs}

	-- THANKS RED
	
	function Events.get(name)
		if (name == nil) then
			local ret = {}
			
			for idx = 0, Events.count() - 1 do
				ret[#ret + 1] = Events(idx)
			end
			
			setmetatable(ret, getMT)
			return ret
		else
			for idx = 0, Events.count() - 1 do
				local event = Events(idx)
				
				if event.name == name then
					return event
				end
			end
			return nil
		end
	end
end

------------------------------
-- RELATED ARRAYS --
------------------------------
do
	local WAITING_EVENT_NAMES = mem(0xB2D6E8, FIELD_DWORD)
	local WAITING_EVENT_TIMERS = mem(0xB2D704, FIELD_DWORD)

	local function checkIndex(index)
		if (not (index >= 1 and index <= 100)) then
			error("Cannot access waiting Event from outside the Event range.")
		end
	end
	
	local function array(address, dtype, mult)
		return setmetatable({}, {
			__index = function(self, index)
				checkIndex(index)
				index = (index - 1)
				
				return mem(address + index * mult, dtype)
			end,
			
			__newindex = function(self, index, val)
				checkIndex(index)
				index = (index - 1)
				
				return mem(address + index * mult, dtype, val)
			end,
			
			__len = function()
				return mem(0xB2D710, FIELD_WORD)
			end,
		})
	end

	Events.waitingNames = array(WAITING_EVENT_NAMES, FIELD_STRING, 4)
	Events.waitingTimers = array(WAITING_EVENT_TIMERS, FIELD_WORD, 2)
end

------------------------------
-- ACTIONS --
------------------------------
local eventsListener = {}

local function customMusic(ev)
	for k, sect in ipairs(Section.get()) do
		local idx = sect.idx
		local customPath = rawget(ev.sectionMusicPath, idx)
		
		if ev.sectionMusic[idx] == 24 and customPath then -- custom
			Audio.MusicChange(idx, customPath)
		end
	end
end

function eventsListener.onPostEventDirect(name)
	if type(name) ~= 'string' or name == "" then return end
	
	local ev = Events.get(name)
	
	if ev then
		customMusic(ev)

		for _, action in ipairs(ev.actions) do
			action()
		end
	end
end

registerEvent(eventsListener, "onPostEventDirect", "onPostEventDirect", true)
---------------------------
-- SET GLOBAL AND RETURN --
---------------------------
_G.Events = Events
return Events