local blockmanager = require("blockmanager")

local table_insert = table.insert
local table_remove = table.remove

local onef0 = {}

-- set this outside of functions to restore old behaviour
onef0.undoLedgeFix = false

local speedYChangeList = {}
local collidesThisFrame = {}
local speedYChangeMap = {}

function onef0.onInitAPI()
    registerEvent(onef0, "onTickEnd", "onTickEnd", true)
end

function onef0.register(id)
    blockmanager.registerEvent(id, onef0, "onIntersectBlock")
end

local customTicks = {}
local customReleases = {}

function onef0.registerGlide(id, func)
	customTicks[id] = func
end

function onef0.registerRelease(id, func)
	customReleases[id] = func
end

local collider = Colliders.Box(0, 0, 0, 1)

function onef0.onTickEnd()
	for i=#speedYChangeList, 1, -1 do
		local v = speedYChangeList[i]
		if v and v.isValid and (not v.collidesBlockBottom) and v:mem(0x12C, FIELD_WORD) == 0 and v.data._basegame.gliding then
			if v.id == v.data._basegame.gliding.id then
				if v.speedX ~= 0 and (math.sign(v.speedX) ~= v.direction) then
					v.direction = math.sign(v.speedX)
				end
				local speed = math.abs(v.data._basegame.gliding.speedX)
				local oldSpeed = math.abs(v.speedX)
				if oldSpeed > speed then
					v.speedX = oldSpeed * v.direction
				else
					v.speedX = speed * v.direction
				end
			end
			if v.speedY >= v.data._basegame.gliding.lastSpeedY then

				v.data._basegame.gliding.speedY = math.min(12, v.data._basegame.gliding.speedY + (v.speedY - v.data._basegame.gliding.lastSpeedY))
			
				if not collidesThisFrame[v] then
					v.speedY = v.data._basegame.gliding.speedY
					if customReleases[v.id] then
						customReleases[v.id](v)
					end
					speedYChangeMap[v] = nil
					table_remove(speedYChangeList, i)
				end
			else
				if customReleases[v.id] then
					customReleases[v.id](v)
				end
				speedYChangeMap[v] = nil
				table_remove(speedYChangeList, i)
			end
		end
	end

	collidesThisFrame = {}
end

function onef0.onIntersectBlock(v, o)
	if o.__type ~= "NPC" then return end
	if NPC.config[o.id].nogliding
		or o:mem(0x138, FIELD_WORD) ~= 0
		or o.y + o.height > v.y + 8
		-- or o.collidesBlockBottom
		--or o.speedY <= 0
			then return end
	
	local data = v.data._basegame

	collider.x = v.x
	collider.width = v.width
	collider.y = v.y - 1

	if Colliders.collide(collider, o) then
		collidesThisFrame[o] = true
		o.data._basegame = o.data._basegame or {}
		o.data._basegame.gliding = o.data._basegame.gliding or {}
		o.data._basegame.gliding.speedX = o.speedX
		o.data._basegame.gliding.speedY = o.speedY
		o.data._basegame.gliding.id = o.id
		o.y = (v.y-o.height)
		if onef0.undoLedgeFix then
			o.speedY = math.min(o.speedY, -Defines.npc_grav)
		else
			o.speedY = math.min(o.speedY, 0)
			if o.speedY == 0 and customTicks[o.id] then
				customTicks[o.id](o)
			end
			if o.attachedLayerObj then
				o.attachedLayerObj.speedY = o.speedY
			end
		end
		o.data._basegame.gliding.lastSpeedY = o.speedY
		if o.data._basegame.lineguide and o.data._basegame.lineguide.attachedNPCs then
			for k,n in ipairs(o.data._basegame.lineguide.attachedNPCs) do
				n.speedY = 0
			end
		end
		if not speedYChangeMap[o] then
			speedYChangeMap[o] = true
			table_insert(speedYChangeList, o)
		end
	end
end

return onef0