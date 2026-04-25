local npc = {}
local id = NPC_ID

local npcutils = require("npcs/npcutils")
local beetle = require("npcs/ai/busterbeetle")
local nm = require('npcManager')

local defaultId = 609

local settings = {
	id = id,
	
	frames = 1,
	framestyle=0,
	
	jumphurt = false,
	nohurt = true,
	
	npcblock = true,
	npcblocktop = false,
	playerblock = true,
	playerblocktop = true,
	nogravity = true,
	
	grabside = false,
	grabtop = true,
	
	noiceball = true,
	noyoshi= false,
	nofireball = true,

	noblockcollision = true,
	harmlessgrab=true,

	spriteLeftWidth = 14,
	spriteRightWidth = 14,
	containedHeight = 38,
	containedYOffset = -10,
	containedLeftCutoff = 2,
	containedRightCutoff = 2
}
	
nm.setNpcSettings(settings)
beetle.registerNoTransformID(id)

function npc.onDrawNPC(v)
	if v.despawnTimer <= 0 then return end
	v.animationFrame = -1

	if v.ai1 <= 0 then
		v.ai1 = defaultId
	end
	

	if v.ai1 > 0 then
		local cfg = NPC.config[v.ai1]
		local cfgv = NPC.config[v.id]
		local settings = v.data._settings
	
		if v.width ~= cfg.width then
			local w = math.max(cfg.width, 32)
			v.x = v.x + 0.5 * v.width - 0.5 * w
			-- v.y = v.y + v.height - cfg.height
	
			v.width = w
			-- v.height = cfg.height
		end

		local p = -45.01
		if cfg.foreground then
			p = -15.1
		end

		local gfxw, gfxh = cfg.gfxwidth, cfg.gfxheight

		if gfxw == 0 then
			gfxw = cfg.width
		end

		if gfxh == 0 then
			gfxh = cfg.height
		end

		local gfxh2 = cfgv.gfxheight
		if gfxh2 == 0 then
			gfxh2 = v.height
		end

		local gfxw2 = v.width

		if settings.invisible then
			Graphics.drawImageToSceneWP(Graphics.sprites.npc[v.ai1].img,
				v.x + 0.5 * v.width - 0.5 * gfxw,
				v.y + 0.5 * v.height - 0.5 * gfxh + cfg.gfxoffsety, 0, 0, gfxw, gfxh, p)
		else

			local frame = math.floor(lunatime.drawtick() / cfgv.framespeed) % cfgv.frames

			if v.direction == 1 and cfgv.framestyle > 0 then
				frame = frame + cfgv.frames
			end

			Graphics.drawImageToSceneWP(Graphics.sprites.npc[v.ai1].img,
				v.x + 0.5 * v.width - 0.5 * gfxw + cfgv.containedLeftCutoff,
				v.y + cfgv.containedYOffset, cfgv.containedLeftCutoff, 0, gfxw - (cfgv.containedLeftCutoff + cfgv.containedRightCutoff), math.min(gfxh, cfgv.containedHeight), p)
	
			local img = Graphics.sprites.npc[v.id].img

			Graphics.drawImageToSceneWP(img,
				v.x + cfgv.gfxoffsetx,
				v.y + cfgv.gfxoffsety, 0, frame * gfxh2, cfgv.spriteLeftWidth, gfxh2, p + 0.01)

			Graphics.drawImageToSceneWP(img,
				v.x + cfgv.gfxoffsetx + v.width - cfgv.spriteRightWidth,
				v.y + cfgv.gfxoffsety, img.width - cfgv.spriteRightWidth, frame * gfxh2, cfgv.spriteRightWidth, gfxh2, p + 0.01)
	
			Graphics.drawBox{
				texture = img,
				x = v.x + cfgv.gfxoffsetx + cfgv.spriteLeftWidth,
				y = v.y + cfgv.gfxoffsety,
				height = gfxh2,
				width = v.width - (cfgv.spriteLeftWidth + cfgv.spriteRightWidth),
				sourceX = cfgv.spriteLeftWidth,
				sourceWidth = img.width - (cfgv.spriteLeftWidth + cfgv.spriteRightWidth),
				sourceY = frame * gfxh2,
				sourceHeight = gfxh2,
				priority = p + 0.01,
				sceneCoords = true
			}

		end
	end
end

function npc.onTickEndNPC(v)
	if v.despawnTimer <= 0 then return end
	if v.ai1 <= 0 then
		v.ai1 = defaultId
	end

	local contained = v:mem(0x138, FIELD_WORD)
	if contained > 0 and contained ~= 5 then return end

	local data = v.data._basegame

	if data.x == nil then
		data.x = v.spawnX
		data.y = v.spawnY
		v.x = v.spawnX
		v.y = v.spawnY
	end

	if v:mem(0x12C, FIELD_WORD) == 0 and contained ~= 5 then
		data.x = v.x
		data.y = v.y
	end

	if v:mem(0x12C, FIELD_WORD) ~= 0 or contained == 5 then
		local n = NPC.spawn(v.id, data.x, data.y, v.section, v.spawnId > 0)
		n.layerName = v.layerName
		v.dontMove = false
		v.layerName = "Spawned NPCs"
		n.ai1 = v.ai1
		n.spawnId = v.spawnId
		n.spawnX = data.x
		n.spawnY = data.y
		n.spawnAi1 = n.ai1
		n.width = v.width
		n.data._settings = v.data._settings
		-- n.height = v.height
		local cfg = NPC.config[n.ai1]
	
		if n.width ~= cfg.width then
			local w = math.max(cfg.width, 32)
			n.x = n.x + 0.5 * n.width - 0.5 * w
			-- n.y = n.y + n.height - cfg.height
	
			n.width = w
			-- n.height = cfg.height
		end

		local data = v.data._basegame
		
		-- reset some collision related fields before transformation,
		-- otherwise, under certain conditions (if the vase is placed overlapping a block)
		-- then the thrown item will be thrown backwards
		v:mem(0x50, FIELD_FLOAT, 0)
		v:mem(0x152, FIELD_BOOL, 0)
		v:mem(0x120, FIELD_BOOL, 0)
		-- transform the vase into the new held item
		v:transform(v.ai1)
		v.data._basegame = data
		v.spawnId = 0

		npc.onDrawNPC(n) -- this doesn't happen?
		return
	end

	npcutils.applyLayerMovement(v)
end

function npc.onInitAPI()
	nm.registerEvent(NPC_ID, npc, 'onDrawNPC')
	nm.registerEvent(NPC_ID, npc, 'onTickEndNPC')
end

return npc