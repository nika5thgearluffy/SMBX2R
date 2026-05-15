local npcManager = require("npcmanager");
local npcutils = require("npcs/npcutils")
local sml = require("npcs/ai/SMLDeath")

--Thwomp-like code taken from 9thCore's Būichi NPC.
--String code taken from basegame spider NPCs.

--Create the library table
local spider = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local spiderSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 64,
	gfxwidth = 48,
	width = 48,
	height = 48,
	frames = 3,
	framestyle = 0,
	framespeed = 8, 
	speed = 1,
	
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=false,
	nogravity = true,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = false,

	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	
	score = 4,
	muted = false,
	stringpriority = -67, -- priority when the string is manually drawn
	stringretractspeed = 8, -- how fast an abandonned string retracts
	stringcolor = Color.white..0.9,
	health = 2
}

--Applies NPC settings
npcManager.setNpcSettings(spiderSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=328,
		[HARM_TYPE_FROMBELOW]=328,
		[HARM_TYPE_NPC]=328,
		[HARM_TYPE_PROJECTILE_USED]=328,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=328,
		[HARM_TYPE_TAIL]=10,
		[HARM_TYPE_SPINJUMP]=10,
		[HARM_TYPE_OFFSCREEN] = {id=328, speedY=-2.5},
		[HARM_TYPE_SWORD]=10,
	}
);

local STATE_INACTIVE = 0
local STATE_UP = 1
local STATE_DOWN = 2
local STATE_DED = 3

local abandonnedStrings = {};

-- helper function to draw spider strings
local function drawString(x, y1, y2, p, c)
	Graphics.drawLine{x1 = x, y1 = y1, x2 = x, y2 = y2, priority = p, color = c, sceneCoords = true};
end

-- creator function for a string object after a spider is killed
local function abandonnedString(npc, cfg)
	local data = npc.data._basegame;

	local str;
	
	if data ~= nil then
		str = {layer = data.layer, x = npc.x + npc.width/2, y2 = npc.y + npc.height/4};

		if data.usesSectionTop then
			str.y1 = Section(npc:mem(0x146, FIELD_WORD)).boundary.top;
		else
			str.y1 = data.topY;
		end
		str.speed = cfg.stringretractspeed
		str.priority = cfg.stringpriority
		str.color = cfg.stringcolor
	end
	
	table.insert(abandonnedStrings, str);
end
	
function spider.onInitAPI()
	npcManager.registerEvent(npcID, spider, "onTickEndNPC");
	npcManager.registerEvent(npcID, spider, "onDrawNPC");
	registerEvent(spider, "onTick");
	registerEvent(spider, "onDraw");
	registerEvent(spider, "onNPCHarm");
	registerEvent(spider, "onNPCKill");
end

-- hanging spider AI
function spider.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	local data = v.data._basegame
	local cfg = NPC.config[v.id]
	local plr = Player.getNearest(v.x + v.width / 2, v.y + v.height / 2)
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.deathTimer = 0
		data.waitTimer = 64
		return
	end

	--Initialize
	if not data.initialized then
		data.initialized = true
		data.deathTimer = data.deathTimer or 0
		data.waitTimer = data.waitTimer or 64
		data.origY = v.y
		data.state = STATE_INACTIVE
	end
	
	if v:mem(0x136, FIELD_BOOL) then --thrown
		data.origY = v.y
		v.speedX = 0
	end

	if data.state == STATE_INACTIVE then
		data.waitTimer = data.waitTimer + 1
		v.animationFrame = 0
		local plr = npcutils.getNearestPlayer(v) --get nearest player
		if plr.x + plr.width >= v.x - 64 and plr.x <= v.x + v.width + 64 then --check if player is in range
			if data.waitTimer >= 64 then
				data.state = STATE_DOWN
				data.waitTimer = 0
			end
		end
	end

	if v:mem(0x138, FIELD_WORD) > 0 then
		data.state = STATE_INACTIVE
		data.origY = v.y - 32
	end

	if data.state == STATE_DOWN then
		v.animationFrame = math.floor(lunatime.tick() / 6) % 2
		v.speedY = 4
	elseif data.state == STATE_UP then
		v.animationFrame = math.floor(lunatime.tick() / 10) % 2
		v.speedY = -2
	else
		v.speedY = 0
	end

	if v.collidesBlockBottom and data.state == STATE_DOWN then
		data.waitTimer = data.waitTimer + 1
		if data.waitTimer >= 16 then
			data.state = STATE_UP
		else
			v.animationFrame = 0
		end
	end

	if data.state == STATE_UP and v.y <= data.origY then
		data.state = STATE_INACTIVE
	end
	
	if data.state == STATE_DED then
		v.animationFrame = 2
		v.speedY = 3
		v.friendly = true
		if v.collidesBlockBottom then
			data.deathTimer = data.deathTimer + 1
			if data.deathTimer >= 96 then
				v:kill(HARM_TYPE_OFFSCREEN)
				if not NPC.config[v.id].muted then
					SFX.play("sound/extended/sml1-death.ogg")
				else
					SFX.play(4)
				end
			end
		end
	end

	if data.targetY == nil then
		local p = Player.getNearest(v.x, v.y)
		if v.section == p.section then
			-- initialization for hanging spiders in the player's section

			data.dropping = false; -- whether the NPC is dropping downwards
			
			-- determine whether its string attaches to a block or the section top
			local sec = Section(p.section)
			local rangeBlocks = Block.getIntersecting(v.x, sec.boundary.top, v.x + v.width, v.y); -- can only hook onto solid blocks or section top
			if #rangeBlocks > 0 then
				local blocks = {}

				for k,v in ipairs(rangeBlocks) do
					if not v.isHidden and v:mem(0x5A, FIELD_WORD) == 0 and (Block.SOLID_MAP[v.id] or Block.SEMISOLID_MAP[v.id]) then
						table.insert(blocks, v)
					end
				end
				if #blocks > 0 then
					local checkIntersecting = true;
					local top = sec.boundary.top;
					local centerX = v.x + v.width/2;
					
					while not data.topY do
						-- repeats this process until there are no more intersecting blocks as some may not be viable (hidden, etc.)
					
						local intersects, _, _, block = Colliders.linecast({centerX + 0.0000001, v.y}, {centerX, top}, blocks); -- linecast up to the top of the section
					
						if intersects then
							-- if a colliding semi-/solid block is found
							data.topY = block.y + block.height;
							data.usesSectionTop = false;
							data.layer = block.layerObj;
						else
							-- use the top of the section if no viable blocks are found
						
							data.topY = sec.boundary.top - v.height - 32;
							data.usesSectionTop = true;
							data.layer = v.layerObj
						end
					end
				else
					data.topY = sec.boundary.top - v.height - 32;
					data.usesSectionTop = true;
					data.layer = v.layerObj
				end
			else
				data.topY = sec.boundary.top - v.height - 32;
				data.usesSectionTop = true;
				data.layer = v.layerObj
			end
			-- move the NPC to the start position (original placed position is saved as target)
			data.targetY = v.y;
			v:mem(0x124, FIELD_BOOL,true)
		end
	end

	if data.targetY == nil then
		return
	end
	
	if v:mem(0x124, FIELD_BOOL) then
		local p = Player.getNearest(v.x, v.y)
		local cam = Camera(p.idx)
		if (not data.dropping) and (((v.x >= cam.x) and (v.x + v.width <= (cam.x + cam.width)))) then
			data.dropping = true;
		end
	else
		data.dropping = false;
	end

	if (v:mem(0x138, FIELD_WORD) == 5 and not data.lostString) or data.state == STATE_DED then
		abandonnedString(v, NPC.config[v.id])
		data.lostString = true
	end
end

-- draw logic for hanging spider strings
function spider.onDrawNPC(npc)
	local data = npc.data._basegame;
	
	if (not npc.isHidden) and (npc:mem(0x124, FIELD_BOOL)) and ((data.dropping)) and npc:mem(0x138, FIELD_WORD) < 5 then
		-- draw strings only for visible NPCs
	
		local x, y2 = npc.x + npc.width/2, npc.y + npc.height/4;
		local y1 = data.topY;
		
		drawString(x, y1, y2, NPC.config[npc.id].stringpriority, NPC.config[npc.id].stringcolor);
	end
end

-- misc logic
function spider.onTick()
	-- create abandonned strings from frozen spiders

	-- NEEDS ONNPCIDCHANGE STAT!
	for _, iceblock in ipairs(NPC.get(263, Section.getActiveIndices())) do
		if iceblock.ai1 == npcID then
			local data = iceblock.data._basegame;

			if (data ~= nil) and (not data.lostString) then
				abandonnedString(iceblock, NPC.config[iceblock.ai1]);
				
				data.lostString = true;
			end
		end
	end

	-- logic performed on abandonned strings

	for i=#abandonnedStrings, 1, -1 do
		local str = abandonnedStrings[i]
		-- sync with moving layers and shrink
	
		str.x = str.x + str.layer.speedX;
		str.y1 = str.y1 + str.layer.speedY;
		str.y2 = str.y2 - str.speed + str.layer.speedY;
		
		if str.y2 <= str.y1 then
			table.remove(abandonnedStrings, i); -- remove retracted strings
		end
	end
end

-- draw logic for abandonned strings (killed or frozen spiders)
function spider.onDraw()
	for _, str in ipairs(abandonnedStrings) do
		drawString(str.x, str.y1, str.y2, str.priority, str.color);
	end
end

--Handles damage
function spider.onNPCHarm(eventObj,v,reason,culprit)
	local data = v.data._basegame
	if v.id ~= npcID then return end
	
	if not data.health then
		data.health = spiderSettings.health
	end
	
	if reason == HARM_TYPE_JUMP then
		eventObj.cancelled = true
		Misc.givePoints(4, v, true)
		SFX.play(2)
		data.state = STATE_DED
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
		
		if data.health > 0 then
			SFX.play(9)
			if reason ~= HARM_TYPE_SWORD and culprit then
				Animation.spawn(75, culprit.x, culprit.y)
			end
			eventObj.cancelled = true
			return
		end
		
	end
end

-- create a string object for the spider's string so that it can be drawn retracting upon death
function spider.onNPCKill(_, killedNPC, killReason)
	if killedNPC.id == npcID and (killReason ~= HARM_TYPE_OFFSCREEN) then
		if not killedNPC.data._basegame.lostString then	
			abandonnedString(killedNPC, NPC.config[killedNPC.id]);
		end
	end
end

return spider