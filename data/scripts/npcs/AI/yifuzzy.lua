local fuzzy = {}

local npcID = NPC_ID

local npcManager = require("npcManager")

local dizziness = lunatime.toTicks(15)
local dizzySfx = Misc.resolveSoundFile("fuzzy-dizzy")

local function compileShader(filename)
	filename = filename..".frag"
	local shader = Shader()
	shader:compileFromFile(nil, Misc.multiResolveFile(filename, "shaders/npc/"..filename))
	return shader
end

local dizzyShader, backgroundShader, pixelShader

local screenBuffer = Graphics.CaptureBuffer(800,600)

local dizzy = 0
local dizziness = 0
local strength = 1
local infinite = false
local transitionDuration = 0
fuzzy.idMap = {}

function fuzzy.getDizzy(config)
	dizzy = lunatime.toTicks(config.dizzytime or 15)
    transitionDuration = lunatime.toTicks(config.dizzytransitiontime or 7.5)
	infinite = dizzy < 0
    strength = config.dizzystrength or 1
	if dizzy < 0 then
		dizzy = lunatime.toTicks(15)
	end
	dizziness = dizzy
	SFX.play(dizzySfx)
end

function fuzzy.isDizzy()
	return dizzy > 0
end

function fuzzy.endDizzy(instant)
    dizziness = transitionDuration * 2
    dizzy = transitionDuration
    infinite = false

    if instant then
        dizzy = 0
    end
end

function fuzzy.registerFuzzy(id)
	npcManager.registerEvent(id, fuzzy, "onTickNPC")
    fuzzy.idMap[id] = true
end

function fuzzy.onInitAPI()
	registerEvent(fuzzy, "onTick")
	registerEvent(fuzzy, "onPostNPCHarm")
	registerEvent(fuzzy, "onPostNPCCollect")
	registerEvent(fuzzy, "onDraw")
end

function fuzzy.onTick()
	if fuzzy.isDizzy() then
		dizzy = dizzy - 1
	end
end

function fuzzy.onTickNPC(npc)
	if npc.isHidden or npc:mem(0x12A,FIELD_WORD) <= 0 or npc:mem(0x136, FIELD_BOOL) then
		return
	end
	
	npc.speedX = npc.direction --vanilla logic handles npc.txt speed multiplication
	npc.ai1 = npc.ai1 + 1
	npc.speedY = math.sin(lunatime.toSeconds(npc.ai1))*0.66666
end

function fuzzy.onPostNPCHarm(npc, reason, culprit)
	if fuzzy.idMap[npc.id] then
		if reason == 1 or reason == 7 or reason == 10 then
			if type(culprit) ~= "Player" or not (culprit.isMega or culprit.hasStarman) then
				fuzzy.getDizzy(NPC.config[npc.id])
			end
		end
	end
end

function fuzzy.onPostNPCCollect(npc, p)
	if fuzzy.idMap[npc.id] then
		if not (p.isMega or p.hasStarman) then
			fuzzy.getDizzy(NPC.config[npc.id])
		end
	end
end

function fuzzy.onDraw()
	if dizzy ~= 0 or infinite then
		dizzyShader      = dizzyShader      or compileShader("fuzzy")
		backgroundShader = backgroundShader or compileShader("fuzzy_bg")
		pixelShader      = pixelShader      or compileShader("fuzzy_pixel")
		local d = 0
		local halfMin = math.min(transitionDuration, dizziness / 2)
		if dizzy > dizziness - halfMin then
			d = math.lerp(0, 1, (dizzy - (dizziness - halfMin))/(halfMin))
		elseif not infinite and dizzy < halfMin then
			d = math.lerp(-1, 0, (dizzy /(halfMin)))
		end
		local intensity = (1 - d * d) * strength
		screenBuffer:captureAt(-95)
		Graphics.drawScreen{
			texture = screenBuffer,
			shader = backgroundShader,
			priority = -95,
			uniforms = {
				time = lunatime.time(),
				intensity = intensity
			}
		}
		screenBuffer:captureAt(0)
		Graphics.drawScreen{
			texture = screenBuffer,
			shader = dizzyShader,
			priority = 0,
			uniforms = {
				time = lunatime.time(),
				cameraX = (camera.x / camera.width) % 1,
				intensity = intensity
			}
		}
		local size = 50 * d*d - 25
		if d > 0 and size > 1 then
			local pxSize = {camera.width/size,camera.height/size}
			screenBuffer:captureAt(0)
			Graphics.drawScreen{
				texture = screenBuffer,
				shader = pixelShader,
				priority = 0,
				uniforms = {pxSize = pxSize}
			}
		end
	end
end

return fuzzy