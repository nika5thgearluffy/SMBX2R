--[[
-- Author: Minus
-- Modifed for basegame by Saturnyoshi
--]]

local npcManager = require("npcManager")
local colliders = require("colliders")

local BOOM_SPEED = 4
local npcID = NPC_ID
local boomerang = {}

local boomerangSettings = {
	id = npcID,
	gfxheight = 32,
	gfxwidth = 32,
	height = 32,
	width = 32,
	frames = 4,
	framestyle = 0,
	ignorethrownnpcs = true,
	luahandlesspeed=true,
	jumphurt = 1,
	nogravity = 1,
	noblockcollision = 1,
	noyoshi = 1,
	noiceball = 1,
	speed = 1,
	spinjumpsafe = true,
	riseheight = 64,
	trajectorywidth = 7 * 32,
	fallheight = 32
}

local configFile = npcManager.setNpcSettings(boomerangSettings)

-----------------------------------------------------------
-------------------- HELPER FUNCTIONS: --------------------
-----------------------------------------------------------

-- Called when first spawned or respawned (i.e., ai1 is 0).  Initializes all of the boomerang's relevant parameters (no data is used here, due to the
-- small number of necessary parameters).
local function initialize(boom)
	local data = boom.data._basegame
	-- Set the flag that the boomerang has been initialized
	boom.ai1 = 1

	-- The current "state" of the boomerang's pseudo-elliptical path.
	-- 0: Not initialized.
	-- 1: Initial curve upward.
	-- 2: Horizontal movement away from the bro.
	-- 3: Curving back, first half.
	-- 4: Curving back, second half.
	-- 5: Horizontal movement back toward the bro.
	data.state = 1
	if boom.forcedState > 0 then
		data.state = 2
	end
	if boom:mem(0x130, FIELD_WORD) ~= 0 then
		boom:mem(0x12E, FIELD_WORD, 9999)
		boom:mem(0x136, FIELD_BOOL, true)
	end

	-- The timer for each phase of the boomerang path.  Once it reaches zero, the boomerang goes to the next state.
	local speedTotal = NPC.config[boom.id].speed * BOOM_SPEED
	data.timer = math.floor(math.pi * configFile.riseheight / (2 * speedTotal))

	-- Owner is assumed to be set to the NPC which spawned the boomerang
	-- to be able to detect whether the boomerang intersects with the original thrower while in state 5, and delete it if that's the case.
	-- data.ownerBro = nil
end

-----------------------------------------------------------
--------------------- API FUNCTIONS: ----------------------
-----------------------------------------------------------


function boomerang.onInitAPI()
	npcManager.registerEvent(npcID, boomerang, "onTickNPC")
end
local function heldFilterFunc(other)
	return other.despawnTimer >= 0 and (not other.isGenerator) and (not other.friendly) and other:mem(0x12C, FIELD_WORD) == 0 and other.forcedState == 0
end
function boomerang.onTickNPC(boom)
	if Defines.levelFreeze then return end

	if boom.despawnTimer <= 0 or boom:mem(0x12C, FIELD_WORD) ~= 0 then
		boom.ai1 = 0
		return
	end

	local speedTotal = NPC.config[boom.id].speed * BOOM_SPEED
	local data = boom.data._basegame
	if boom.ai1 == 0 then
		initialize(boom)
	elseif data.state == 1 then
		-- The boomerang is rising upward.  Adjust the speeds so that the boomerang follows a quarter circle path upward with speed
		-- BOOM_SPEED.

		boom.speedX = boom.direction * speedTotal * math.cos(speedTotal * data.timer / configFile.riseheight)
		boom.speedY = -speedTotal * math.sin(speedTotal * data.timer / configFile.riseheight)

		if data.timer > 0 then
			data.timer = data.timer - 1
		else
			data.state = 2
			data.timer = math.floor(configFile.trajectorywidth / speedTotal)
		end
	elseif data.state == 2 then
		-- The boomerang is moving away, following a horizontal path.

		boom.speedX = boom.direction * speedTotal
		boom.speedY = 0

		if data.timer > 0 then
			if boom.forcedState == 0 then
				data.timer = data.timer - 1
			end
		else
			data.state = 3
			data.timer = math.floor(math.pi * configFile.fallheight / (2 * speedTotal))
		end
	elseif data.state == 3 then
		-- The boomerang is following the top half of a half-circle path to turn back.

		boom.speedX = boom.direction * speedTotal * math.sin(speedTotal * data.timer / configFile.fallheight)
		boom.speedY = speedTotal * math.cos(speedTotal * data.timer / configFile.fallheight)

		if data.timer > 0 then
			data.timer = data.timer - 1
		else
			data.state = 4
			data.timer = math.floor(math.pi * configFile.fallheight / (2 * speedTotal))

			-- Turn the boomerang around.

			boom.direction = -boom.direction
		end
	elseif data.state == 4 then
		-- The boomerang is following the bottom half of a half-circle path to turn back.

		boom.speedX = boom.direction * speedTotal * math.cos(speedTotal * data.timer / configFile.fallheight)
		boom.speedY = speedTotal * math.sin(speedTotal * data.timer / configFile.fallheight)

		if data.timer > 0 then
			data.timer = data.timer - 1
		else
			data.state = 5
		end
	else
		-- The boomerang is following a horizontal path back in the direction it initially came.

		boom.speedX = boom.direction * speedTotal
		boom.speedY = 0

		if data.ownerBro ~= nil and data.ownerBro.isValid then
			-- If the boomerang intersects with the bro that originally threw it, destroy it.
			if colliders.collide(boom, data.ownerBro) then
				boom:kill()
			end
		end
	end

	if boom:mem(0x12E, FIELD_WORD) > 0 and not boom.friendly then
		for k,n in ipairs(Colliders.getColliding{
			a = boom,
			b = NPC.HITTABLE,
			btype = Colliders.NPC,
			collisionGroup = boom.collisionGroup,
			filter = heldFilterFunc
		}) do
			n:harm(3)
		end
	end
end
	
return boomerang