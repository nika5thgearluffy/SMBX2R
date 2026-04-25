local npcManager = require("npcManager")

local flagpole = {}

local endstates = require("game/endstates")
local mega = require("npcs/ai/megashroom")
local timer = require("timer")
local utils = require("npcs/npcutils")

local npcID = NPC_ID

local settings = {
	id = npcID,
	width = 32,
	gfxwidth=32,
	height=32,
	gfxheight=32,
	frames=1,
	framestyle=0,
	framespeed = 8,
	playerblock=true,
	playerblocktop=true,
	npcblock=true,
	npcblocktop=true,
	nohurt=true,
	jumphurt = true,
	nofireball=true,
	noiceball=true,
	nogravity=true,
	noblockcollision=true,
	speed = 0,
	notcointransformable = true,
	isstationary = true,
	luahandlesspeed = true,
	nowaterphysics = true,
	nowalldeath=true,
	noyoshi=true,
	lineguided = true,
	linespeed = 3,
	lineactivebydefault = true,

	useforcedstate = true,
	polelength=9*32,
	poletopframes=1,
	polemidframes=1,
	flagframes = 4,
	flagoffsetx = 16,
	flagoffsety = 0, -- from the top
	flagendoffsetx = 16,
	flagendoffsety = -32, -- from the bottom
	flagsfx = "extended/flagpole",
	endsfx = "extended/smb1-course-clear",
}

npcManager.setNpcSettings(settings)

local endingLevel = false

-- Using a routine here to make sure this runs even if the flagpole dies to "no turn back"
local function megaEndRoutine(p)
	Routine.waitFrames(120)
	if p.isMega then
		mega.StopMega(p,true)
		Routine.waitFrames(120)
	end
	Level.endState(9)
	SFX.play(Misc.resolveSoundFile(NPC.config[npcID].endsfx))
	endstates.setPlayer(p)
end

local function initiateEndSequence(v, p, dir)
	v.data._basegame.grabbingPlayer = p
	p.direction = dir
	endingLevel = true
	timer.setActive(false)
	p:mem(0x50, FIELD_BOOL, false)
	for k,p2 in ipairs(Player.get()) do
		Audio.MusicChange(p2.section, 0)
	end
	Misc.npcToCoins()
	if p.isMega or p.mount == MOUNT_CLOWNCAR then
		if v.data._basegame.lineguide then
			v.data._basegame.lineguide.attachCooldown = 9999
			v.data._basegame.lineguide.state = 2
		end
		SFX.play(36)
		v.speedX = 4 * dir
		v.speedY = -2
		v.friendly = true
		v.data._basegame.state = 2
		Routine.run(megaEndRoutine, p)

		Misc.givePoints(9, vector(p.x + p.width, p.y))
	else
		p.speedX = 0
		p.speedY = 0
		v.data._basegame.state = 1
		p.y = math.max(p.y, v.y - NPC.config[v.id].polelength)
		local gradient = (p.y + p.height - (v.y - NPC.config[v.id].polelength)) / NPC.config[v.id].polelength
		local clampedGradient = math.ceil((1 - math.clamp(gradient, 0, 0.89)) * 10)
		Misc.givePoints(clampedGradient, vector(p.x + p.width, p.y), clampedGradient ~= 10)
	end
end

function flagpole.onInputUpdate()
	if Level.endState() == 0 and endingLevel then
		for k,p in ipairs(Player.get()) do
			for i, _ in pairs(p.keys) do
				p.keys[i] = false
			end
		end
	end
end

function flagpole.onTickEndNPC(v)
	local data = v.data._basegame
	
	v:mem(0x154, FIELD_BOOL, false) -- fix noturnback despawn yo

	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		if v:mem(0x124, FIELD_BOOL) then
			for k,c in ipairs(Camera.get()) do
				if v.y - NPC.config[v.id].polelength - NPC.config[v.id].gfxheight <= c.x + c.height then
					v.despawnTimer = 180
					break
				end
			end
		end
		if v.despawnTimer <= 0 then return end
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.grabbingPlayer = nil
		data.timer = 0
		local cfg = NPC.config[v.id]
		data.collider = data.collider or Colliders.Box(0,0,2,cfg.polelength + 2)
		data.animationTimer = data.animationTimer or 0
		data.state = 0
		data.flagPos = vector(cfg.flagoffsetx, cfg.flagoffsety)
	end

	--Depending on the NPC, these checks must be handled differently
	if v.heldIndex ~= 0 --Negative when held by NPCs, positive when held by players
	or v.forcedState > 0--Various forced states
	then
		return
	end

	data.animationTimer = data.animationTimer + 1

	if data.state ~= 2 then
		utils.applyLayerMovement(v)
	end
	
	-- Put main AI below here
	if Level.endState() == 0 then
		if data.state == 0 and not endingLevel then
			if not v.friendly then
				data.collider.x = v.x + 0.5 * v.width - 1
				data.collider.y = v.y - data.collider.height
				for k,p in ipairs(Player.getIntersecting(v.x - 64, v.y - 600, v.x + v.width + 64, v.y + v.height)) do
					if (p.isMega or p.mount == MOUNT_CLOWNCAR) and Colliders.speedCollide(p, v) then
						initiateEndSequence(v, p, p.direction)
						return
					end

					if Colliders.speedCollide(p, data.collider) then
						initiateEndSequence(v, p, p.direction)
					end
				end
			end
		elseif data.state == 1 and data.grabbingPlayer then
			local cfg = NPC.config[v.id]
			data.timer = data.timer + 1
			if cfg.useforcedstate then
				data.grabbingPlayer.forcedState = FORCEDSTATE_FLAGPOLE
			else
				data.grabbingPlayer.speedY = -Defines.player_grav
			end
			data.grabbingPlayer.x = v.x + 0.5 * v.width - ((data.grabbingPlayer.direction + 1) * 0.5) * (data.grabbingPlayer.width - 4)
			if data.grabbingPlayer.mount == 0 then
				data.grabbingPlayer.frame = 5
			end
			if data.timer == 20 then
				SFX.play(Misc.resolveSoundFile(NPC.config[v.id].flagsfx))
			elseif data.timer > 20 then
				if cfg.useforcedstate then
					if data.grabbingPlayer.y + data.grabbingPlayer.height < v.y then
						data.grabbingPlayer.y = data.grabbingPlayer.y + cfg.polelength / 90
						if data.grabbingPlayer.y + data.grabbingPlayer.height >= v.y then
							data.grabbingPlayer.y = v.y - data.grabbingPlayer.height
						end
					end
				elseif not data.grabbingPlayer:isOnGround() then
					data.grabbingPlayer.speedY = cfg.polelength / 90
				end

				local t = (data.timer - 20)/90
				data.flagPos = math.lerp(vector(cfg.flagoffsetx, cfg.flagoffsety), vector(cfg.flagendoffsetx, cfg.polelength + cfg.flagendoffsety), math.min(t, 1))
				if t >= 1.2 then
					Level.endState(9)
					SFX.play(Misc.resolveSoundFile(NPC.config[v.id].endsfx))
					endstates.setPlayer(data.grabbingPlayer)
					data.grabbingPlayer.forcedState = 0
				end
			end
		elseif data.state == 2 and data.grabbingPlayer then
			v.speedY = v.speedY + Defines.npc_grav
		end
	end
end

function flagpole.onDrawNPC(v)
	if v.despawnTimer <= 0 then return end
	
	local data = v.data._basegame

	if not data.initialized then return end

	local cfg = NPC.config[v.id]
	local t = math.floor(data.animationTimer/cfg.framespeed)
	local topFrame = t % cfg.poletopframes
	local midFrame = cfg.poletopframes + (t % cfg.polemidframes)
	local bottomFrame = cfg.poletopframes + cfg.polemidframes + (t % cfg.frames)
	local flagFrame = cfg.poletopframes + cfg.polemidframes + cfg.frames + (t % cfg.flagframes)

	local totalFrames = cfg.poletopframes + cfg.polemidframes + cfg.frames + cfg.flagframes
	if v.direction == 1 and cfg.framestyle >= 1 then
		topFrame = topFrame + totalFrames
		midFrame = midFrame + totalFrames
		bottomFrame = bottomFrame + totalFrames
		flagFrame = flagFrame + totalFrames
		totalFrames = totalFrames * 2
	end

	local p = -45
	if cfg.foreground then
		p = - 15
	end
	if v.forcedState > 0 then
		p = -75
	end

	local img = Graphics.sprites.npc[v.id].img
	local x = v.x + cfg.gfxoffsetx
	local y = v.y + cfg.gfxoffsety - cfg.polelength - NPC.config[v.id].gfxheight
	Graphics.drawImageToSceneWP(img, x, y, 0, cfg.gfxheight * topFrame, cfg.gfxwidth, cfg.gfxheight, p)
	y = y + cfg.gfxheight
	Graphics.drawImageToSceneWP(img, x + data.flagPos.x, y + data.flagPos.y, 0, cfg.gfxheight * flagFrame, cfg.gfxwidth, cfg.gfxheight, p)
	while (y < v.y) do
		Graphics.drawImageToSceneWP(img, x, y, 0, cfg.gfxheight * midFrame, cfg.gfxwidth, math.min(cfg.gfxheight, v.y - y), p)
		y = y + cfg.gfxheight
	end

	v.animationFrame = bottomFrame
	v.animationTimer = 999
end


registerEvent(flagpole, "onInputUpdate")
npcManager.registerEvent(npcID, flagpole, "onTickEndNPC")
npcManager.registerEvent(npcID, flagpole, "onDrawNPC")

return flagpole