--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local lakitushop = require("lakitushop")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 160,
	gfxwidth = 64,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 48,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 2,
	framestyle = 0,
	framespeed = 24, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = true,
	noblockcollision = true,
	ignorethrownnpcs = true,
	nofireball = false,
	noiceball = false,
	noyoshi= true,
	nowaterphysics = false,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = true, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,

	--Identity-related flags. Apply various vanilla AI based on the flag:
	--iswalker = false,
	--isbot = false,
	--isvegetable = false,
	--isshoe = false,
	--isyoshi = false,
	--isinteractable = false,
	--iscoin = false,
	--isvine = false,
	--iscollectablegoal = false,
	--isflying = false,
	--iswaternpc = false,
	--isshell = false,

	--Emits light if the Darkness feature is active:
	lightradius = 100,
	lightbrightness = 1,
	--lightoffsetx = 0,
	lightoffsety = -104,
	lightcolor = Color(1, 0.7, 0.7),

	--Define custom properties below
    lakituid = 712
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)


--Custom local definitions below


--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	--registerEvent(sampleNPC, "onNPCKill")
end

function sampleNPC.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data._basegame
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
        if data.lakitu and data.lakitu.isValid then
            data.lakitu.post = nil
        end
        data.lakitu = nil
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
	end

    if not v.friendly then
        v.msg = " "
    else
        return
    end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) ~= 0   --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		return
	end

    for _, p in ipairs(Player.get()) do
        local distVec = vector(p.x + 0.5 * p.width - v.x - 0.5 * v.width, p.y + 0.5 * p.height - v.y - 0.5 * v.height)
        if distVec.length < v.width then
            if data.lakitu == nil or not data.lakitu.isValid then
                data.lakitu = NPC.spawn(NPC.config[v.id].lakituid, v.x + RNG.irandomEntry{-250, 250}, camera.y)
                data.lakitu.y = data.lakitu.y - data.lakitu.height + 2
                data.lakitu.data._basegame.post = v
                data.lakitu.despawnTimer = 180
                data.lakitu.data._basegame.state = 1

                SFX.play(Misc.resolveSoundFile("extended/lakitushop-ready"))
            end

            if data.lakitu.data._basegame.state > 2 or data.lakitu.data._basegame.state < 1 then
                data.lakitu.data._basegame.state = 1

                SFX.play(Misc.resolveSoundFile("extended/lakitushop-ready"))
            end

            if p.keys.up == KEYS_PRESSED then
                lakitushop.open(p, data.lakitu, v.data._settings.preset)
            end
        else
            v.animationFrame = 0
            v.animationTimer = 1
            if data.lakitu and data.lakitu.isValid then
                data.lakitu.data._basegame.state = 3
            else
                data.lakitu = nil
            end
        end
    end
end

--Gotta return the library table!
return sampleNPC