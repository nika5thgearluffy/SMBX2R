--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local sinewave = require("npcs/ai/sinewave")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	gfxwidth = 48, 
	gfxheight = 48, 
	width = 40, 
	height = 24, 
	frames = 2,
	framespeed = 8, 
	framestyle = 1,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1.2,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = true,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = true, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	
	score = 4,
	
	amplitude = 2,
    frequency  = 30,
    wavestart = -180,
    chase = false,
	health = 2
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=322,
		[HARM_TYPE_PROJECTILE_USED]=322,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=322,
		[HARM_TYPE_TAIL]=322,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below


--Register events
function sampleNPC.onInitAPI()
	sinewave.register(npcID)
	registerEvent(sampleNPC, "onNPCHarm")
end

function sampleNPC.onNPCHarm(eventObj,v,reason,culprit)
	local data = v.data
	if v.id ~= npcID then return end
	
	if not data.health then
		data.health = sampleNPCSettings.health
	end
	
	if reason == HARM_TYPE_NPC then
	
		if culprit then
			if culprit.__type == "NPC" and (culprit.id == 13 or culprit.id == 108 or culprit.id == 17 or NPC.config[culprit.id].SMLDamageSystem) then
				data.health = data.health - 1
				culprit:kill()
			else
				data.health = 0
			end
		else
			for _,n in ipairs(NPC.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
				if NPC.config[n.id].SMLDamageSystem then
					data.health = data.health - 1
					SFX.play(9)
					Animation.spawn(75, n.x, n.y)
					if data.health > 0 then
						eventObj.cancelled = true
					end
				end
			end
		end
		
		if culprit then
			if data.health > 0 then
				SFX.play(9)
				Animation.spawn(75, culprit.x, culprit.y)
				eventObj.cancelled = true
				return
			end
		end
	end
	
end

return sampleNPC