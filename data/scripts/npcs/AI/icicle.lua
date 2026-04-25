--------------------------------------------------------------------
--          Icicle from Super Mario Maker 2 by Nintendo           --
--                    Recreated by IAmPlayer                      --
--------------------------------------------------------------------

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local blockutils = require("blocks/blockutils")
local lakitu = require("npcs/ai/lakitu")

local icicle = {}

local sharedSettings = {
	gfxheight = 64,
	gfxwidth = 32,
	width = 24,
	height = 56,
	gfxoffsetx = 0,
	gfxoffsety = 8,
	frames = 1,
	framestyle = 0,
	framespeed = 8,
	speed = 1,
	
	npcblocktop = true,
	playerblocktop = true,

	nohurt=true,
	nogravity = true,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = false,
	
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = true,
	harmlessthrown = true,
	ignorethrownnpcs = true,
	notcointransformable = true,
    nowalldeath = true,
	isstationary = true,
	
	respawntimer = 120,
	waittime = 32,
	respawnduration = 24,
	shakedistance = 96,
	shakespeed = 0.4,
	shakestrength = 3,
	falldistance = 64,
	effectID = 296,
	dripeffectID = 297,
	maxspeed = 6,
    fallsound = "extended/icicle_fall",
    breaksound = "extended/icicle_break",
	
	iscold = true,
	durability = -1,
}

local function init(v)
	local data = v.data._basegame
	if data.initialized then return end
	data.initialized = true
	data.scale = 1
	data.timer = 0
	data.dripTimer = RNG.random(0, 180)
	data.rotation = 0
	data.state = 0
	data.scale = 1
	data.isRespawnable = v.data._settings.respawnable --Defaults to true
	
	if data.isRespawnable == nil then
		data.isRespawnable = true
	end

	data.trueFriendly = v.friendly
	
	data.origin = vector(v.x, v.y)

	local config = NPC.config[v.id]

	if data.fallsound == nil then
		data.fallsound = config.fallsound
		if type(data.fallsound) == "string" then
			data.fallsound = Misc.resolveSoundFile(data.fallsound)
		end
	end
	if data.breaksound == nil then
		data.breaksound = config.breaksound
		if type(data.breaksound) == "string" then
			data.breaksound = Misc.resolveSoundFile(data.breaksound)
		end
	end
	
	data.sprite = Sprite{
		image = Graphics.sprites.npc[v.id].img,
		x = v.x + v.width * 0.5 + config.gfxoffsetx, --needs to be kept updated
		y = v.y - (data.scale * 2 + 4) + config.gfxoffsety, --needs to be kept updated
		width = config.gfxwidth * data.scale, --needs to be kept updated
		height = config.gfxheight * data.scale, --needs to be kept updated
		frames = config.frames,
		align = Sprite.align.TOP
	}
end

local icicleMap = {}

local function icicleLakituCallback(icicle, l)
	init(icicle)

	local data = icicle.data._basegame
	data.isRespawnable = false
	data.state = 1
	data.ignore = l

	icicle.speedY = 0
end

function icicle.register(id, settings, type)
	npcManager.registerEvent(id, icicle, "onTickEndNPC")
	npcManager.registerEvent(id, icicle, "onDrawNPC")

    npcManager.registerDefines(id, {NPC.UNHITTABLE})
    npcManager.setNpcSettings(table.join(settings, sharedSettings))
    icicleMap[id] = type or 1

	lakitu.registerOnPostSpawnCallback(id, icicleLakituCallback)
end

local function defaultInteraction(other, icicle)
	other:harm(3)
end

local function breakEffect(v)
    local data = v.data._basegame
	if data.state ~= 3 then
		Effect.spawn(NPC.config[v.id].effectID, v.x, v.y)
	end

    SFX.play(data.breaksound)

	data.scale = 0
	data.state = 3
	data.rotation = 0
	data.timer = 0
end

local function pressSwitchInteraction(v, icicle)
	if v:mem(0x12C, FIELD_WORD) == 0 then
		v:harm(HARM_TYPE_JUMP)
		if icicle.data._basegame.isRespawnable then
			breakEffect(icicle)
		else
			icicle:kill()
			Effect.spawn(NPC.config[icicle.id].effectID, icicle.x, icicle.y)
			SFX.play(icicle.data._basegame.breaksound)
		end
	end
end

local npcInteractions = {}

-- Registers a function to run whenever an icicle hits a specific NPC ID.
function icicle.registerNPCInteraction(npcID,func)

	if (func == nil) then
		func = defaultInteraction
	end
	npcInteractions[npcID] = func
end

icicle.registerNPCInteraction(32,pressSwitchInteraction)
icicle.registerNPCInteraction(238,pressSwitchInteraction)
icicle.registerNPCInteraction(239,pressSwitchInteraction)

local pSwitches = {32}

function icicle.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if v:mem(0x12C, FIELD_WORD) ~= 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		return
	end

    local config = NPC.config[v.id]

	if not data.initialized then
		init(v)
	end
	
	if data.state == 0 and icicleMap[v.id] ~= 2 then -- idle
		local p = Player.getNearest(v.x + 0.5 * v.width, v.y)
		local dist = math.abs((p.x + 0.5 * p.width) - (v.x + 0.5 * v.width))
		if ((dist <= config.falldistance and p.y >= v.y) or p.standingNPC == v) then
			data.state = 1
			data.timer = 0
		elseif (dist <= config.shakedistance and p.y >= v.y) then
			data.rotation = math.sin(data.timer * config.shakespeed) * config.shakestrength
			data.timer = data.timer + 1
		else
			data.timer = 0
			data.rotation = data.rotation * 0.8
		end
		
		if icicleMap[v.id] == 1 and data.state == 4 then
			v.despawnTimer = 180
		end

		if config.dripeffectID > 0 then
			data.dripTimer = data.dripTimer + RNG.random(0.2, 1)
			if data.dripTimer > 180 then
				data.dripTimer = 0
				local e = Effect.spawn(config.dripeffectID, v.x + 0.5 * v.width, v.y + v.height)
			end
		end
	elseif data.state == 1 then -- locked into falling
		if data.timer > config.waittime - 16 then
			data.rotation = data.rotation * 0.8
			if data.timer >= config.waittime then
				data.state = 2
				data.rotation = 0
				v.speedY = 0
				v.speedX = 0
				data.timer = 0
				SFX.play(data.fallsound)
			end
		else
			data.rotation = math.sin(data.timer * config.shakespeed) * config.shakestrength
		end
		data.timer = data.timer + 1
	elseif data.state == 4 then -- immobile, fallen
		v.despawnTimer = 180
		v.speedY = math.min(v.speedY + Defines.npc_grav, config.maxspeed)
	elseif data.state == 2 then -- fallingh
		if not v.collidesBlockBottom then
			v.speedY = v.speedY + 0.08
			for _, n in NPC.iterateIntersecting(v.x, v.y + v.height, v.x + v.width, v.y + v.height + v.speedY) do
				if n.despawnTimer > 0 and not n.friendly and not (data.ignore == n) then
					if npcInteractions[n.id] then
						npcInteractions[n.id](n, v)
					elseif NPC.HITTABLE_MAP[n.id] then
						n:harm(3)
						if icicleMap[v.id] == 1 then
							if data.isRespawnable then
								breakEffect(v)
							else
								v:kill()
								Effect.spawn(config.effectID, v.x, v.y)
								SFX.play(data.breaksound)
							end
						end
						break
					end
				end
			end
		else
			for _, b in Block.iterateIntersecting(v.x, v.y + v.height, v.x + v.width, v.y + v.height + 2) do
				if blockutils.hiddenFilter(b) then
					if Block.MEGA_SMASH_MAP[b.id] and b.contentID == 0 then
						b:remove(true)
					else
						b:hit(true)
					end
				end
			end

			if icicleMap[v.id] == 1 then
				data.state = 4
			else
				if data.isRespawnable then
					breakEffect(v)
				else
					v:kill()
					Effect.spawn(config.effectID, v.x, v.y)
					SFX.play(data.breaksound)
				end
			end
		end

		if v.speedY >= config.maxspeed then
			v.speedY = config.maxspeed
		end
	elseif data.state == 3 then -- respawning
		data.timer = data.timer + 1
		v.x = data.origin.x
		v.y = -50000000
		v.friendly = true
		if data.timer >= config.respawntimer then
			v.y = data.origin.y
			data.scale = math.min(1, data.scale + 1/(config.respawnduration))
		end

		if data.scale == 1 then
			data.state = 0
			data.timer = 0
			v.friendly = data.trueFriendly
		end
	end
	
	if not v.friendly then
		for k,p in ipairs(Player.get()) do
			if p.deathTimer == 0 and Colliders.collide(p, v) then
				if not (p:mem(0x3C, FIELD_BOOL) or p.isMega or p.hasStarman) then
					p:harm()
				end

				if data.isRespawnable then
					breakEffect(v)
				else
					v:kill()
					Effect.spawn(config.effectID, v.x, v.y)
					SFX.play(data.breaksound)
				end
				break
			end
		end
	end
	
	v.noblockcollision = data.state < 2
	local x, y = npcutils.getLayerSpeed(v)
	data.origin.x = data.origin.x + x
	data.origin.y = data.origin.y + y
	--moving icicles
    if data.state < 2 then
	    v.speedX,v.speedY = x, y
    end

	data.sprite.x = v.x + v.width * 0.5 + config.gfxoffsetx
	data.sprite.width = config.gfxwidth
	data.sprite.height = config.gfxheight
	data.sprite.y = v.y + v.height - data.sprite.height + config.gfxoffsety
	data.sprite.scale = vector(data.scale, data.scale)
end

function icicle.onDrawNPC(v)
	if v.despawnTimer <= 0 then return end

	if v:mem(0x12C, FIELD_WORD) ~= 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		return
	end
	
	local data = v.data._basegame
	
	if not Misc.isPaused() then
		if not Defines.levelFreeze then
			if data.sprite ~= nil then
				data.sprite.rotation = data.rotation
			end
		end
	end
	
	local p = -45
    if NPC.config[v.id].foreground then
        p = -15
    end
	
	if data.sprite ~= nil then
		data.sprite:draw{
			priority = p,
			sceneCoords = true,
			frame = v.animationFrame,
		}
	end
	
	npcutils.hideNPC(v)
end

--Gotta return the library table!
return icicle