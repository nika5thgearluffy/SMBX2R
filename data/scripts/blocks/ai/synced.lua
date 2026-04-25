local switch = {}
local blockutils = require("blocks/blockutils")
local blockmanager = require("blockmanager")

local tableinsert = table.insert

local spiketimer = 0

switch.state = 1
switch.timedspikestate = true

switch.spikeeffectid = 269

local beatIDMap = {}
local beatIDs = {}

local switchIDs = {}
local switchIDMap = {}

local lastState = 0

local switchableIDs = {}

local switchableSpikeIDs = {}

local switchSpikeIDMap = {}

local spikeIDs = {}
local spikeIDMap = {}

local spikeEffects = {}

local bpm
local beattimer
local numbeeps = 3
local timesig = 4
local beepstartpoint = 0.5
local spikeendpoint = 0.25
switch.beatwarnsfx = Misc.resolveSoundFile("beat-warn")
switch.beatswitchsfx = Misc.resolveSoundFile("beat-switch")
switch.timedstate = 1
switch.timedActiveStateCount = 1
local timedMaxStates = 0

local ids = {}

local function checkActive(a, b)
	local checks = switch.timedActiveStateCount - 1
	while checks >= 0 do
		if a - checks == b or a + timedMaxStates - checks == b then
			return true
		end
		checks = checks - 1
	end
	return false
end

function switch.registerBlinkingBlock(id, state)
	timedMaxStates = math.max(state, timedMaxStates)
	f = 0
	if checkActive(switch.timedstate, state) then
		f = 1
	end
	Block.config[id].passthrough = f == 1
	blockutils.setBlockFrame(id, f)
	beatIDMap[id] = state
	tableinsert(beatIDs, id)
    blockmanager.registerEvent(id, switch, "onCameraDrawBlock")
end

function switch.registerSwitch(id)
	if state == false then
		state = 1
	elseif state == true then
		state = 2
	end
	tableinsert(switchIDs, id)
	switchIDMap[id] = true
	blockutils.setBlockFrame(id, switch.state - 1)
end

local origFloorSlope = {}
local origCeilingSlope = {}

function switch.registerSwitchableBlock(id, state)
	if state == false then
		state = 2
	elseif state == true then
		state = 1
	end
	while switchableIDs[state] == nil do
		table.insert(switchableIDs, {})
	end
	origFloorSlope[id] = Block.config[id].floorslope
	origCeilingSlope[id] = Block.config[id].ceilingslope
	tableinsert(switchableIDs[state], id)
	if state == switch.state then
		blockutils.setBlockFrame(id, 0)
	else
		blockutils.setBlockFrame(id, 1)
	end
	blockmanager.setBlockSettings({id = id, switchstate = state})
end

function switch.registerSwitchableSpike(id, state)
	if state == false then
		state = 1
	elseif state == true then
		state = 2
	end
	while switchableSpikeIDs[state] == nil do
		table.insert(switchableSpikeIDs, {})
		table.insert(switchSpikeIDMap, {})
	end
	tableinsert(switchableSpikeIDs[state] ,id)
	switchSpikeIDMap[state][id] = true
	
    blockmanager.registerEvent(id, switch, "onCollideBlock")
    blockmanager.registerEvent(id, switch, "onCameraDrawBlock")
	blockmanager.setBlockSettings({id = id, switchstate = state})
end

function switch.registerSpike(id)
	tableinsert(spikeIDs, id)
	spikeIDMap[id] = true
    blockmanager.registerEvent(id, switch, "onCollideBlock")
    blockmanager.registerEvent(id, switch, "onCameraDrawBlock")
end


-- Adjusts the number of beeps and how early they start based on the beat timer
local function setbeeps()	

	if beattimer/timesig >= 5/4 and timesig > 1 then
		beepstartpoint = 1-(1/timesig)
		numbeeps = math.max(timesig - 1, 1)
		
	elseif beattimer/timesig >= 1.5/4 and timesig > 2 then
		beepstartpoint = 1-(2/timesig)
		numbeeps = math.max(timesig - 1, 1)
	elseif beattimer/timesig >= 1/4 and timesig > 2  then
		beepstartpoint = 1-(2/timesig)
		numbeeps = 1
		
	else
		beepstartpoint = 0
		numbeeps = 0
	end
	
end

-- starttime is like, between 0 and 1
-- beeps is num of beeps
function Misc.setBeepCount(startTime, beeps)
	beepstartpoint = startTime or beepstartpoint
	numbeeps = beeps or numbeeps
end

function Misc.setBPM(b)
	bpm = b
	beattimer = (60/bpm) * timesig
	
	setbeeps()
end

function Misc.getBPM()
	return bpm
end

function Misc.setBeatTime(t)
	beattimer = t
	bpm = (60/t) * timesig
	
	setbeeps()
end

function Misc.getBeatTime()
	return beattimer
end

function Misc.setBeatSignature(s)
	timesig = s
	Misc.setBPM(bpm)
end

function Misc.getBeatSignature()
	return timesig
end
Misc.beatUsesMusicClock = false

Misc.beatOffset = 0

Misc.setBeatTime(6)

switch.spikesfx = Misc.resolveSoundFile("spike-block")

-- Updates the frame and configs for relevant blocks
local function refreshFrame()
	for k,i in ipairs(switchableIDs) do
		for k,v in ipairs(i) do
			local f = 0
			if switch.state == Block.config[v].switchstate then
				Block.config[v].floorslope = origFloorSlope[v]
				Block.config[v].ceilingslope = origCeilingSlope[v]
			else
				Block.config[v].floorslope = 0
				Block.config[v].ceilingslope = 0
				f = 1
			end
			Block.config[v].passthrough = f ~= 0
			blockutils.setBlockFrame(v, f)
		end
	end
	
	for k,v in ipairs(switchIDs) do
		blockutils.setBlockFrame(v, switch.state - 1)
	end

	for k,v in ipairs(beatIDs) do
		local f = 1
		local active = checkActive(switch.timedstate, beatIDMap[v])
		if active then
			f = 0
		end
		Block.config[v].passthrough = not active
		blockutils.setBlockFrame(v, f)
	end
end

function switch.onInitAPI()
	registerEvent(switch, "onStart")
	registerEvent(switch, "onTick")
	registerEvent(switch, "onBlockHit")
	registerEvent(switch, "onPostBlockHit")
	registerEvent(switch, "onDraw")
	registerEvent(switch, "onCameraDraw", "onCameraDraw", false)
	registerEvent(switch, "onCameraDraw", "lateCameraDraw", false)
end

function switch.onStart()
	refreshFrame()
end

local switched = false

local lastClock = 0

-- Gets the current timer time in seconds
local function getTime()
	if Misc.beatUsesMusicClock then
		if Audio.MusicIsPlaying() then
			lastClock = math.max(Audio.MusicClock() - Misc.beatOffset, 0)
		end
		return lastClock
	else
		return math.max(lunatime.time() - Misc.beatOffset, 0)
	end
end

Misc.getBeatClock = getTime


-- Plays a sound, if blocks are on screen
local function playSound(sids, sound)
	for _,v in ipairs(sids) do
		blockutils.playSound(v, sound)
	end
end

-- Plays a sound, if blocks are on screen
local function playSounds(soundsmap)

	for _,v in ipairs(soundsmap) do
		playSound(v.ids, v.sfx)
	end
end

function switch.tryToggle(state)
	if switched then return false end
	switched = true
	switch.toggle(state)
	return true
end

-- Toggles the switchable blocks
function switch.toggle(state)
	if state == nil then
		state = (switch.state % math.max(#switchableIDs, #switchableSpikeIDs)) + 1
	end
	lastState = switch.state
	switch.state = state
	
	local map = switchableSpikeIDs[state]
	
	playSound(map, switch.spikesfx)
	
	refreshFrame()
	spiketimer = 8
	EventManager.callEvent("onSyncSwitch", switch.state)
end

Misc.toggleSyncSwitch = switch.toggle

local timerperiod = 0
local lastTime = 0

-- One tick expressed in the local 0-1 timer
local function tickrate()
	return 1/lunatime.toTicks(beattimer)
end

local function norm(a)
	return (a + timedMaxStates) % timedMaxStates
end

function switch.onTick()
	-- switched stops synced switches being changed more than once per tick
	switched = false
	
	if spiketimer > 0 then
		spiketimer = spiketimer - 1
	end
	
	
	-----------------
	-- TIMED STUFF --
	-----------------
	
	
	-- Get a local timer between 0 and 1 to sync timed changes to
	local t = (getTime() % beattimer)/beattimer
	
	-- timerperiod counts beeps, if a beep needs to be played, play it and increase the period 
	if timerperiod < numbeeps and t >= (beepstartpoint)+((1-beepstartpoint)/numbeeps)*timerperiod then
		timerperiod = timerperiod + 1

		local ids = {}
		for k,v in ipairs(beatIDs) do
			if norm(switch.timedstate) == norm(beatIDMap[v] - 1) then
				tableinsert(ids, v)
			elseif norm(switch.timedstate) == norm(beatIDMap[v] - 1 - switch.timedActiveStateCount) then
				tableinsert(ids, v)
			end
		end
		playSound(ids, switch.beatwarnsfx)
		playSound(beatIDs, switch.beatwarnsfx)
		
		EventManager.callEvent("onBeatWarn", numbeeps-timerperiod)
	end
	
	-- Retract timed spikes
	if switch.timedspikestate and t > spikeendpoint then
		switch.timedspikestate = false
	end
	
	
	-- If the local timer decreased, it means the timer state needs to flip
	if t < lastTime then
	
		-- Flip switches and extend spikes
		switch.timedstate = (switch.timedstate % timedMaxStates) + 1
		local ids = {}
		for k,v in ipairs(beatIDs) do
			if norm(switch.timedstate) == norm(beatIDMap[v]) then
				tableinsert(ids, v)
			elseif norm(switch.timedstate) == norm(beatIDMap[v] - switch.timedActiveStateCount) then
				tableinsert(ids, v)
			end
		end


		switch.timedspikestate = true
		
		-- Play sound effects

		playSounds(
					{ {ids = spikeIDs, sfx = switch.spikesfx}, {ids = beatIDs, sfx = switch.beatswitchsfx} }
				   )
				
		-- Update visuals
		refreshFrame()
		
		-- Reset beep counter
		timerperiod = 0
		
		EventManager.callEvent("onBeatStateChange", switch.timedstate)
	end
	
	-- Update last tick counter
	lastTime = t
	
	-- Update harm filters
	do
		for k,i in ipairs(switchableSpikeIDs) do
			for k,v in ipairs(i) do
				ids[v] = switch.state == Block.config[v].switchstate or (lastState == Block.config[v].switchstate and spiketimer > 0)
			end
		end

		local cond = switch.timedspikestate
		for k,v in ipairs(spikeIDs) do
			ids[v] = cond
		end
	end
end

function switch:onCollideBlock(obj)
	if type(obj) == "Player" and ids[self.id] and (obj.mount == 0 or self:collidesWith(obj) ~= 1) then
		obj:harm()
	end
end

function switch.onBlockHit(eventObj, v, fromUpper, playerOrNil)
	if switchIDMap[v.id] and not switched and v:mem(0x56,FIELD_WORD) ~= 0 then
		eventObj.cancelled = true
	end
end

function switch.onPostBlockHit(v, fromUpper, playerOrNil)
	if switchIDMap[v.id] and not switched and v:mem(0x56,FIELD_WORD) == 0 then
		switch.toggle()
		SFX.play(32)
		switched = true
	end
end
	
local fgverts = {}
local fgtx = {}
local bgverts = {}
local bgtx = {}
	
local beatverts = {}

local vertIdx = { [fgverts] = 1, [fgtx] = 1, [bgverts] = 1, [bgtx] = 1, [beatverts] = 1}

local function addVerts(verts, x1, y1, x2, y2)
	verts[vertIdx[verts]]    = x1
	verts[vertIdx[verts]+1]  = y1
	verts[vertIdx[verts]+2]  = x2
	verts[vertIdx[verts]+3]  = y1
	verts[vertIdx[verts]+4]  = x1
	verts[vertIdx[verts]+5]  = y2
		
	verts[vertIdx[verts]+6]  = x1
	verts[vertIdx[verts]+7]  = y2
	verts[vertIdx[verts]+8]  = x2
	verts[vertIdx[verts]+9]  = y1
	verts[vertIdx[verts]+10] = x2
	verts[vertIdx[verts]+11] = y2
	
	vertIdx[verts] = vertIdx[verts] + 12
end


function switch:onCameraDrawBlock(idx)
	local c = Camera(idx)
	local id = self.id	
	
	local bw, bh = self.width, self.height
	
	local x1, y1 = self.x, self.y
	
	if self.isHidden or not ids[id] or not blockutils.visible(c, x1 - 32, y1 - 32, bw + 64, bh + 64) then return end
	
	local x2, y2 = x1+bw, y1+bh
	
	
	local img = Graphics.sprites.effect[switch.spikeeffectid].img
	local iw, ih = img.width, img.height
	
	if (x1 < c.x + c.width + iw) and (x2 > c.x - iw) and (y1 < c.y + c.height + ih/3) and (y2 > c.y - ih/3) then
		
		if beatIDMap[id] then
			
			-- Add beat block flashes
			if norm(switch.timedstate) == norm(beatIDMap[id] - 1) then
				-- Add beat block flashes
				addVerts(beatverts, x1, y1, x2, y2)
			elseif norm(switch.timedstate) == norm(beatIDMap[id] - 1 - switch.timedActiveStateCount) then
				-- Add beat block flashes
				addVerts(beatverts, x1, y1, x2, y2)
			end
		else
		
			--Add spikes
			addVerts(fgverts, x1, y1, x2, y2)
			
			local dw = (iw-bw)/(2*iw)
			local dh = ((ih/3)-bh)/(2*ih)
			
			
			local f = 2
			
			if spikeIDMap[id] then
			
				-- If this is a timed spike, choose the frame based on the global timer (lastTime)
				-- tickrate() holds the value of one tick in the units of the global timer, used to adjust for animation
				if not switch.timedspikestate then
					if lastTime >= (1-(tickrate()*4)) then
						f = 1
					else
						f = 0
					end
				end
				
			else
				
				-- If this is a regular spike, use the global spiketimer to adjust frames
				if 	(spiketimer > 4) or lastState == Block.config[id].switchstate then
					f = 0
				elseif spiketimer > 0 then
					f = 1
				end
				
			end
			
			
			-- Add spike vertices
			
			f = f/3
			
			addVerts(fgtx, dw, dh + f, 1-dw, (1/3)-dh+f)
			
			dw = (iw-bw)/2
			dh = ((ih/3)-bh)/2
			x1 = x1 - dw
			x2 = x2 + dw
			y1 = y1 - dw
			y2 = y2 + dw
			
			addVerts(bgverts, x1, y1, x2, y2)
			
			addVerts(bgtx, 0, f, 1, (1/3)+f)
			
		end
	end
end

function switch.onDraw()
	do
		for k,i in ipairs(switchableSpikeIDs) do
			for k,v in ipairs(i) do
				ids[v] = switch.state == Block.config[v].switchstate or (lastState == Block.config[v].switchstate and spiketimer > 0)
			end
		end

		local cond = switch.timedspikestate or lastTime > beepstartpoint or lastTime < (spikeendpoint + tickrate()*8)
		for k,v in ipairs(spikeIDs) do
			ids[v] = cond
		end
		cond = lastTime >= beepstartpoint
		for k,v in ipairs(beatIDs) do
			ids[v] = cond
		end
	end
end

function switch.onCameraDraw(idx)
	if vertIdx[beatverts] > 1 then
	
		for i = vertIdx[beatverts], #beatverts do
			beatverts[i] = nil
		end
		
		vertIdx[beatverts] = 1
	
		-- Get alpha of beat block highlight based on timer and beep starting point. Final number controls brightness.
		local a = (1-(((lastTime-beepstartpoint)/(1-beepstartpoint))%(1/numbeeps))*numbeeps) * 0.9
		Graphics.glDraw{vertexCoords = beatverts, priority = -60, sceneCoords = true, color = 0xFFFFFF00 + (0x99*a)}
	end
		
	if vertIdx[fgverts] > 1 then
	
		for i = vertIdx[bgverts], #bgverts do
			bgverts[i] = nil
			bgtx[i] = nil
			fgverts[i] = nil
			fgtx[i] = nil
		end
		
		vertIdx[bgverts] = 1
		vertIdx[bgtx] = 1
		vertIdx[fgverts] = 1
		vertIdx[fgtx] = 1
		
		-- Draw spikes
		local img = Graphics.sprites.effect[switch.spikeeffectid].img
		Graphics.glDraw{vertexCoords = bgverts, textureCoords = bgtx, texture = img, priority = -80, sceneCoords = true}
		Graphics.glDraw{vertexCoords = fgverts, textureCoords = fgtx, texture = img, priority = -60, sceneCoords = true}
	end
end

return switch