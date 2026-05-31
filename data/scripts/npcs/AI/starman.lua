local npcManager = require("npcManager")
local particles = require("particles")
local colliders = require("colliders")
local darkness = require("darkness")

local starman = {}

starman.ids = {};
starman.duration = {};
starman.ignore = {};
starman.ignore[108] = true;

local idMap = {}

starman.sfxFile = Misc.resolveSoundFile("starman")
local starPreviousSFXFile = starman.sfxFile

local starSoundObject;
local starTimers = {};
local starActivePlayers = {};
local starSparkleObjects = {};
local starOpacity = {}
local starScoreboard = {}

local starlights = {};
local sparklesize = {};

local activeStarIDs = {}

local starmanMusicChunk = nil
local musicvolcache;

local timeFPS = Misc.GetEngineTPS()

function starman.register(id, ignoreOnNPCKill)
	table.insert(starman.ids, id)
	if not ignoreOnNPCKill then
		idMap[id] = true
	end
end

function starman.animationCheck(p)
	return p.forcedState ~= 5 and p.forcedState ~= 8 and p.forcedState ~= 11 and p.forcedState ~= 12
end

function starman.active(idx)
	if(type(idx) == "Player") then idx = idx.idx end;
	if(idx) then return starActivePlayers[idx] == true end;
	for k,_ in pairs(starActivePlayers) do
		return true;
	end
	return false;
end

Player._hasStarman = starman.active;

local function startMusic()
	if(starman.active() and starSoundObject ~= nil) then
		return;
	else
		starSoundObject = Audio.SfxPlayObj(starmanMusicChunk, -1)
		if(musicvolcache == nil) then
			musicvolcache = Audio.MusicVolume();
			Audio.MusicVolume(0);
		end
	end
end

local function stopMusic(idx)
	local onlyPlayer = true;
	for k,_ in pairs(starActivePlayers) do
		if(k ~= idx) then
			onlyPlayer = false;
			break;
		end
	end
	if(onlyPlayer and starSoundObject ~= nil) then
		starSoundObject:Stop()
		starSoundObject = nil;
	end
end

local function resetMusic()
    Audio.MusicVolume(musicvolcache);
    Audio.MusicRewind()
    musicvolcache = nil;
end

function starman.stop(p)
	p = p or player;
	local idx = p.idx;
	activeStarIDs[idx]  =nil
	starActivePlayers[idx] = nil;
	if(starlights[idx] ~= nil) then
		starlights[idx]:destroy();
	end
	starlights[idx] = nil;
	p:mem(0x140, FIELD_WORD, 0);
end

starman.stopTheStar = starman.stop;

local function getDuration(id)
	local t = starman.duration[id];		
	if t == nil then
		if NPC.config[id].duration ~= nil and NPC.config[id].duration then
			t = lunatime.toTicks(NPC.config[id].duration)
		else --No duration set for this npc id
			t = 1
		end
	end
	return t
end

function starman.start(p, id)
	id = id or starman.ids[1]
	p = p or player;
	if(p.isMega) then
		return;
	end
	startMusic();
	local idx = p.idx;
	activeStarIDs[idx] = id
	starTimers[idx] = getDuration(id)
    starOpacity[idx] = 1
    starScoreboard[idx] = 1;
	
	if(starlights[idx] == nil) then
		starlights[idx] = darkness.addLight(darkness.light(0,0,300,2,Color.white));
	else
		starlights[idx].enabled = true;
	end
	if(starSparkleObjects[idx] == nil) then
		starSparkleObjects[idx] = particles.Emitter(0,0,Misc.multiResolveFile("p_starman_sparkle.ini", "particles\\p_starman_sparkle.ini"));
	else
		starSparkleObjects[idx].enabled = true;
	end
	starActivePlayers[idx] = true;
	starSparkleObjects[idx]:Attach(p);
	starlights[idx]:attach(p, true);
end

starman.startTheStar = starman.start;

local function starmanFilter(v)
	return colliders.FILTER_COL_NPC_DEF(v) and not starman.ignore[v.id];
end

local function checkCollisionNoEntity(x1, y1, width1, height1, x2, y2, width2, height2) --Checks a collision between two things
    return (y1 + height1 >= y2) and
           (y1 <= y2 + height2) and
           (x1 <= x2 + width2) and
           (x1 + width1 >= x2)
end

local function restoreOldScoreRoutine(npcID, oldScore)
    Routine.waitFrames(5, true)
    NPC.config[npcID].score = oldScore
end

local function checkStarStatus(p)
	local idx = p.idx;
	if(starActivePlayers[idx]) then
		p:mem(0x140, FIELD_WORD, -2);
		p:mem(0x142, FIELD_WORD, 0);
		
		for k,v in ipairs(NPC.get(NPC.HITTABLE)) do
            -- TODO: Doesn't work well with piranha plants underneath pipes, giving a ton of score. Will either need a check for piranhas underneath pipes, or they'll need to be underneath 1 or 2 pixels deeper
            if(v and v.isValid and starActivePlayers[p.idx] and checkCollisionNoEntity(p.x - 2, p.y + 2, p.width + 2, p.height + 2, v.x, v.y, v.width, v.height)) then
                local oldScore = NPC.config[v.id].score
                if starScoreboard[p.idx] < 10 then
                    starScoreboard[p.idx] = starScoreboard[p.idx] + 1
                end
                NPC.config[v.id].score = 0
                Misc.givePoints(starScoreboard[p.idx],{x = v.x+v.width*0.5,y = v.y+v.height*0.5},true)
                if starScoreboard[p.idx] >= 10 then
                    SFX.play(15)
                end
                Routine.run(restoreOldScoreRoutine, v.id, oldScore)
                v:harm(HARM_TYPE_NPC)
            end
        end
		
		starTimers[idx] = starTimers[idx] - 1;
		if(starTimers[idx] == math.min(getDuration(activeStarIDs[idx])-1, math.floor(lunatime.toTicks(1)))) then
			stopMusic(idx);
            resetMusic();
			if(starSparkleObjects[idx] ~= nil) then
				starSparkleObjects[idx].enabled = false;
			end
		elseif(starTimers[idx] <= 0) then
			starTimers[idx] = nil;
			starman.stop(p);
		end
        
        if (starTimers[idx] ~= nil and activeStarIDs[idx] ~= nil and (starTimers[idx] <= math.min(getDuration(activeStarIDs[idx])-1, math.floor(lunatime.toTicks(1))))) then
            starOpacity[idx] = starOpacity[idx] - (1 / timeFPS)
        end
	end
end

local currentFrames = {};
local shader = Misc.multiResolveFile("starman.frag", "shaders\\npc\\starman.frag")

function starman.onInitAPI()
	registerEvent(starman, "onTick")
	registerEvent(starman, "onDraw", "onDraw", false)
	registerEvent(starman, "onExitLevel")
    registerEvent(starman, "onPostNPCCollect")
    
    for k,v in ipairs(starman.ids) do
        idMap[v] = true
    end
	
	starman.reloadMusic();
end

function starman.reloadMusic()
	starmanMusicChunk = Audio.SfxOpen(starman.sfxFile)
    starPreviousSFXFile = starman.sfxFile
end

local function drawStar(p)
	if(type(shader) == "string") then
		local s = Shader();
		s:compileFromFile(nil, shader);
		shader = s;
	end
	
	local idx = p.idx;

	if(starSoundObject ~= nil) then
		if(Misc.isPaused() or p.deathTimer > 0) then
			starSoundObject:Pause();
		else
			starSoundObject:Resume();
		end
	end
	
	if(starSparkleObjects[idx] ~= nil and p:mem(0x13E, FIELD_WORD) == 0) then
		if(sparklesize[idx] == nil or p.width ~= sparklesize[idx].w or p.height ~= sparklesize[idx].h) then
			sparklesize[idx] = {w=p.width,h=p.height};
			local wid = "-"..(sparklesize[idx].w*0.5)..":"..(sparklesize[idx].w*0.5);
			local hei = "-"..(sparklesize[idx].h*0.5)..":"..(sparklesize[idx].h*0.5)
			starSparkleObjects[idx]:setParam("xOffset",wid);
			starSparkleObjects[idx]:setParam("yOffset",hei);
		end
        
        local priority = -25;
        if(p.forcedState == 3) then
            priority = -70;
        end

		if(starActivePlayers[idx] and starman.animationCheck(p)) then
			p:render{
						shader = shader, 
						uniforms =
								{
									time = lunatime.tick()*2;
								},
						drawmounts = (p:mem(0x108, FIELD_WORD) ~= 3),
                        priority = priority,
                        color = Color(1, 1, 1) .. starOpacity[idx]
					};
					
			
			starSparkleObjects[idx]:Draw(priority);
		
		end
	end
end

function starman.onDraw()
    if starman.sfxFile ~= starPreviousSFXFile then
        starman.reloadMusic()
    end
	for _,v in ipairs(Player.get()) do
		local idx = v.idx;
		if(starActivePlayers[idx]) then
			drawStar(v);
		elseif(starSparkleObjects[idx] and not starSparkleObjects[idx].enabled and starSparkleObjects[idx]:Count() == 0) then
			starSparkleObjects[idx] = nil;
			sparklesize[idx] = nil;
		end
	end
end

function starman.onPostNPCCollect(npc,p)
	local id = npc.id;
	if(idMap[npc.id]) then
        SFX.play(6)
		starman.start(p, npc.id)
	end
end

function starman.onTick()
	if(not isOverworld) then
		for _,v in ipairs(Player.get()) do
			checkStarStatus(v)
		end
	end
end

function starman.onExitLevel()
	for _,v in ipairs(Player.get()) do
        starman.stop(v);
	end
end

return starman;