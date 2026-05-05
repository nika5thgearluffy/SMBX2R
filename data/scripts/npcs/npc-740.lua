--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local SML_Squid = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local SML_SquidSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 64,
	gfxwidth = 56,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 44,
	height = 62,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 2,
	framestyle = 0,
	framespeed = 10, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 0,
	score = 5,
	--Collision-related

	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = false,
	noiceball = false,
	noyoshi= true,
	nowaterphysics = true,
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = true,
	health = 3
}

--Applies NPC settings
npcManager.setNpcSettings(SML_SquidSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=10,
		[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below


--Register events
function SML_Squid.onInitAPI()
	npcManager.registerEvent(npcID, SML_Squid, "onTickNPC")
	registerEvent(SML_Squid, "onNPCHarm")
	registerEvent(SML_Squid, "onNPCKill")
end

function SML_Squid.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	v.dontMove = true
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
	end

	if not data.move then
		data.move = 0
	end

	data.move = data.move + 1
	v.speedY = (-math.cos(data.move/32)*0.45)
	
	if v.ai2 > 0 then
		v.ai2 = v.ai2 - 1
		v.invincibleToSword = true
	else
		v.invincibleToSword = false
	end	
	
end


function SML_Squid.onNPCHarm(event,v,Harms,culprit)
	local data = v.data
	if v.id ~= npcID then return end
	
	if not data.health then
		data.health = SML_SquidSettings.health
	end
	
	if Harms == HARM_TYPE_NPC then
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
						event.cancelled = true
					end
				end
			end
		end
		if culprit then
			if data.health > 0 then
				SFX.play(9)
				Animation.spawn(75, culprit.x, culprit.y)
				event.cancelled = true
				return
			end
		end
	elseif Harms == HARM_TYPE_SWORD and culprit then
		data.health = data.health - 1
		v.ai2 = 16
		if Colliders.downSlash(player,v) then
			player.speedY = -6
		end
		if data.health > 0 then
			SFX.play(89)
			event.cancelled = true
			return
		end
	end
end

function SML_Squid.onNPCKill(event,v,Harms,culprit)
	if v.id ~= npcID then return end
	for i=0, 1 do
		local g = i * 48
        if type(culprit) == "Player" then
            local n = NPC.spawn(726,v.x,v.y + g - 8,culprit.section, false, true --[[centered hitbox around x/y]])
            n.speedX = 2 * v.direction
        end
	end
end

--Gotta return the library table!
return SML_Squid