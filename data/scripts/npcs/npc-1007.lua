local npc = {}

local id = NPC_ID

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

npcManager.setNpcSettings{
	id = id,
	
	width = 64,
	height = 64,
	gfxwidth = 64,
	gfxheight = 64,

	frames = 1,
	
	noblockcollision = true,
	nogravity = true,
	nohurt = true,
	noyoshi = true,
	nofireball = true,
	noiceball = true,
	nohammer = true,
	noshell = true,

	jumphurt = true,
	
	npcblocktop = true,
	playerblocktop = true,
	npcblock = true,
	playerblock = true,
	
	score = 0,
}

local effect = 147

npcManager.registerHarmTypes(id,
	{
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_TAIL,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_NPC]=effect,
		[HARM_TYPE_PROJECTILE_USED]=effect,
		[HARM_TYPE_TAIL]=effect,
		[HARM_TYPE_SWORD]=effect,
	}
);

local spawnedbygenerator = {
    [1] = true,
    [3] = true,
    [4] = true,
}

local function drawNPC(npcobject, args)
    args = args or {}
    if npcobject.__type ~= "NPC" then
        error("Must pass a NPC object to draw. Example: drawNPC(myNPC)")
    end
    local frame = args.frame or npcobject.animationFrame

    local afs = args.applyFrameStyle
    if afs == nil then afs = true end

    local cfg = NPC.config[npcobject.id]
    
    --gfxwidth/gfxheight can be unreliable
    local trueWidth = cfg.gfxwidth
    if trueWidth == 0 then trueWidth = npcobject.width end

    local trueHeight = cfg.gfxheight
    if trueHeight == 0 then trueHeight = npcobject.height end

    --drawing position isn't always exactly hitbox position
    local x = npcobject.x + 0.5 * npcobject.width - 0.5 * trueWidth + cfg.gfxoffsetx + (args.xOffset or 0)
    local y = npcobject.y + npcobject.height - trueHeight + cfg.gfxoffsety + (args.yOffset or 0)

    --cutting off our sprite might be nice for piranha plants and the likes
    local w = args.width or trueWidth
    local h = args.height or trueHeight

    local o = args.opacity or 1

    --the bane of the checklist's existence
    local p = args.priority or -45
    if cfg.foreground then
        p = -15
    end

    if spawnedbygenerator[npcobject:mem(0x138, FIELD_WORD)] then
        p = -75
    end

    local sourceX = args.sourceX or 0
    local sourceY = args.sourceY or 0

    --framestyle is a weird thing...

    local frames = args.frames or cfg.frames
    local f = frame or 0
    --but only if we actually pass a custom frame...
    if args.frame and afs and cfg.framestyle > 0 then
        if cfg.framestyle == 2 then
            if npcobject:mem(0x12C, FIELD_WORD) > 0 or npcobject:mem(0x132, FIELD_WORD) > 0 then
                f = f + 2 * frames
            end
        end
        if npcobject.direction == 1 then
            f = f + frames
        end
    end

	local texture = args.texture or Graphics.sprites.npc[npcobject.id].img
	
	if texture == nil then return end
	
	Graphics.drawBox{
		texture = texture,
		
		x = x,
		y = y,
		sourceX = sourceX,
		sourceY = sourceY + trueHeight * f,
		sourceWidth = w,
		sourceHeight = h,
		
		width = args.textureWidth,
		height = args.textureHeight,
		centred = args.centered,
		
		sceneCoords = true,
		
		color = Color.white .. o,
		priority = p,
	}
    -- Graphics.drawImageToSceneWP(args.texture or Graphics.sprites.npc[npcobject.id].img, x, y, sourceX, sourceY + trueHeight * f, w, h, o, p)
end

function npc.onDrawNPC(v)
	if v.ai1 <= 0 or v.despawnTimer <= 0 then return end
	
	local data = v.data._basegame
	data.origSize = data.origSize or vector(v.width, v.height)
	
	data.width = data.width or v.width
	data.height = data.height or v.height
	
	data.npc = data.npc or {}
	
	local npc = data.npc
	local id = v.ai1
	
	local cfg = NPC.config[id]
	
	npc.__type = "NPC"
	npc.id = id
	
	npc.width = cfg.width
	npc.height = cfg.height
	
	npc.x = (v.x + v.width * .5) - npc.width * .5
	npc.y = (v.y + v.height * .5) - npc.height * .5 
	
	npc.mem = npc.mem or function(self, ...)
		return v:mem(...)
	end
	
	npcutils.drawNPC(npc, {
		priority = -45.1,
	})
	
	local w, h = data.width, data.height
	
	local yOffset = (v.height - data.origSize[2]) * .5
	
	drawNPC(v, {
		xOffset = data.origSize[1] * .5,
		yOffset = (data.origSize[2]  * .5) - yOffset,
		
		textureWidth = w,
		textureHeight= h,
		
		centered = true,
		
		frame = 0,
	})
end

function npc.onTickEndNPC(v)
	if Defines.levelFreeze then return end

	local data = v.data._basegame
	
	if v.despawnTimer <= 0 then
		data.npc = nil
		data.width = nil
		data.height	= nil
		return
	end
	
	data.width = data.width or v.width
	data.height = data.height or v.height

	if v.ai3 > 0 then
		v:mem(0x156, FIELD_WORD, 2)
		
		local c = 1
		
		if (v.ai3 - 1) % 2 == 0 then
			c = -c
		end
		
		data.width = data.width + c
		data.height = data.height + c
		v.x = v.x - c * .5
		v.y = v.y - c * .5
		
		v.ai2 = (v.ai2 + math.abs(c))
        if v.ai2 == 12 then
            if v.ai4 == 1 then
                SFX.play(24)
                v.ai4 = 0
            end
        end
		if v.ai2 > 12 then
			v.ai2 = 0
			
			if v.ai3 == 5 then
				v.ai3 = 0
			else
				v.ai3 = (v.ai3 + 1)
			end
		end
	end
	
	v.width = data.width
	v.height = data.height
	
	v.animationFrame = -1
end

function npc.onNPCHarm(e, v, r)
	if v.id ~= id then return end
	
	v.speedX = 0
	v.speedY = 0
	
	if v:mem(0x156, FIELD_WORD) > 0 then
		e.cancelled = true
		return
	end
	
	v.ai3 = 1
    v.ai4 = 1

	if v.width <= 38 then
		local tagsInput = (v.data._settings.tagsInput or "")
		
		local str = [[
			return function(v, data, settings)
				]] .. tagsInput .. [[
			end
		]]
		
		local chunk, err = load(str)
		
		local n = NPC.spawn(v.ai1, v.x + v.width * .5, v.y + v.height * .5, v.section, false, true)
		n.direction = v.direction
		n.dontMove = v.dontMove
		n.friendly = v.friendly
        SFX.play(34)

		if chunk then
			local func = chunk()
			
			func(n, n.data, n.data._settings)
		end
		
		return
	end
	
	e.cancelled = true
end

function npc.onInitAPI()
	npcManager.registerEvent(id, npc, 'onDrawNPC')
	npcManager.registerEvent(id, npc, 'onTickEndNPC')
	registerEvent(npc, 'onNPCHarm')
end

return npc