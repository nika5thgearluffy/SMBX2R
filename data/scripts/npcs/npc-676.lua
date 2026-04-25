local light = {}

local npcManager = require("npcManager")
local utils = require("npcs/npcutils")

local npcID = NPC_ID

local lightConfig = npcManager.setNpcSettings {
	id = npcID,
	gfxheight = 0,
	gfxwidth = 0,
	width = 32,
	height = 32,
	frames = 1,
	framestyle = 0,
	ignorethrownnpcs = true,
	jumphurt = true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	nogravity = true,
	nohurt = true,
	noblockcollision = true,
	notcointransformable = true
}

npcManager.registerEvent(npcID, light, "onTickNPC")
registerEvent(light, "onNPCHarm")
registerEvent(light, "onNPCKill", "onNPCHarm")

--Light source

local function init(v)
	local data = v.data._basegame
	local s = v.data._settings or { color = Color.white, radius = 64, brightness = 1, sourceEnd = {x = 32, y = 0} }
	data.light = Darkness.light{x=0, y=0, radius = s.radius or 64, brightness = s.brightness, minradius = s.minradius, color = s.color, flicker = s.flicker, type = Darkness.lighttype.LINE, dir = vector(s.sourceEnd.x, s.sourceEnd.y)}
	data.light:attach(v, true)
	Darkness.addLight(data.light)
end

function light:onTickNPC()
	local data = self.data._basegame
	if data.light == nil then
		init(self)
	end
	
	local cx = self.x + self.width*0.5
	local cy = self.y + self.height*0.5
	local r = data.light.radius
	--[[
	local col = Color.red
	if self:mem(0x124,FIELD_BOOL) then
		col = Color.green
	end
	Graphics.drawLine{x1 = cx + r + data.light.width * 0.5, x2 = cx - r - data.light.width * 0.5, y1 = cy + r + data.light.height * 0.5, y2 = cy + r + data.light.height * 0.5, color=col, sceneCoords=true, priority = 0}
	Graphics.drawLine{x1 = cx + r + data.light.width * 0.5, x2 = cx - r - data.light.width * 0.5, y1 = cy - r - data.light.height * 0.5, y2 = cy - r - data.light.height * 0.5, color=col, sceneCoords=true, priority = 0}
	Graphics.drawLine{x1 = cx + r + data.light.width * 0.5, x2 = cx + r + data.light.width * 0.5, y1 = cy - r - data.light.height * 0.5, y2 = cy + r + data.light.height * 0.5, color=col, sceneCoords=true, priority = 0}
	Graphics.drawLine{x1 = cx - r - data.light.width * 0.5, x2 = cx - r - data.light.width * 0.5, y1 = cy - r - data.light.height * 0.5, y2 = cy + r + data.light.height * 0.5, color=col, sceneCoords=true, priority = 0}
	--]]
	for camIdx,c in ipairs(Camera.get()) do
		if math.max(cx, cx+data.light.dir.x) + r > c.x and math.min(cx, cx+data.light.dir.x) - r < c.x + c.width and 
		   math.max(cy, cy+data.light.dir.y) + r > c.y and math.min(cy, cy+data.light.dir.y) - r  < c.y + c.height then
				local resetOffset = (0x126 + (camIdx - 1)*2)

				if self:mem(resetOffset, FIELD_BOOL) or self:mem(0x124,FIELD_BOOL) then
					if not self:mem(0x124,FIELD_BOOL) then
						self:mem(0x14C,FIELD_WORD,camIdx)
					end

					self.despawnTimer = 180
					self:mem(0x124,FIELD_BOOL,true)
				end

				self:mem(0x126,FIELD_BOOL,false)
				self:mem(0x128,FIELD_BOOL,false)				
		end
	end
	
	data.light.enabled = not self.isHidden
	
	utils.applyLayerMovement(self)
end

function light.onNPCHarm(eventobj, npc)
	if npc.id == npcID then
		eventobj.cancelled = true
	end
end

return light
