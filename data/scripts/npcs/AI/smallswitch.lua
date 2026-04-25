local smallSwitch = {}

local npcManager = require("npcManager")
local switchcolors = require("switchcolors")
local npcutils = require("npcs/npcutils")
local synced = require("blocks/ai/synced")
local icicle = require("npcs/ai/icicle")
local thwomps = require("npcs/ai/thwomps")

smallSwitch.sharedSettings = {
	gfxwidth = 32,
	gfxheight = 32,
	gfxoffsetx = 0,
	gfxoffsety = 2,
	width = 32,
	height = 32,
	nogravity = false,
	frames = 1,
	framestyle = 0,
	framespeed = 8,
	noblockcollision = false,
	playerblock = true,
	playerblocktop = true,
	npcblock = true,
	npcblocktop = false,
	speed = 1,
	foreground = 0,
	jumphurt = true,
	nohurt = true,
	score = 0,
	noiceball = true,
	nowaterphysics = false,
	foreground = true,
	noyoshi = false,
	grabside = true,
	harmlessgrab = true,
	harmlessthrown = true,
	ignorethrownnpcs = true,
	nowalldeath = true,
	isstationary = true,
	--Custom settings
	switchon = true, --Whether the switch transforms "off" blocks into "on" blocks.
	switchoff = true, --Whether the switch transforms existing "on" blocks into off blocks.
	blockon = 1, --The ID of the switch's "on" blocks.
	blockoff = 2, --The ID of the switch's "off" blocks.
	effect = 81,
	iscustomswitch = true,
	permanent = false -- sticks around, remains pressed
}

local settings = {}
smallSwitch.settings = settings

local topCollisionBox = Colliders.Box(0,0,0,1)

local switchColorFunctions = {}

local function pressSwitchFromThwomp(v, thwomp, dir)
	if dir == thwomps.DIR.DOWN then
		smallSwitch.press(v)
	end
end

local function pressSwitchFromIcicle(v, icicle)
	smallSwitch.press(v)
end

function smallSwitch.registerSwitch(config)
	local customSettings = table.join(config, smallSwitch.sharedSettings)
	if settings[customSettings.id] ~= nil then
		error("This NPC is already registered as a switch. Use NPC.config to change the settings of registered switches.")
	end
	settings[customSettings.id] = npcManager.setNpcSettings(customSettings)
	npcManager.registerEvent(customSettings.id, smallSwitch, "onTickNPC")
	if customSettings.permanent then
		npcManager.registerEvent(customSettings.id,smallSwitch,"onDrawNPC")
	end
	local func, col = switchcolors.registerColor(customSettings.color)
	switchColorFunctions[col] = func

	-- Doing this is not necessary, because the weight interaction already covers it
	-- thwomps.registerNPCInteraction(customSettings.id, pressSwitchFromThwomp)
	icicle.registerNPCInteraction(customSettings.id, pressSwitchFromIcicle)
end

local function doSwitch(settings)
	if settings.color == "synced" then
		synced.tryToggle(settings.switchstate or 1)
		return
	end
	local blocks_a = Block.get(settings.blockoff)
	local blocks_b = Block.get(settings.blockon)
	if settings.switchon and settings.switchon ~= 0 then
		for _,v in ipairs(blocks_a) do
			v.id = settings.blockon
		end
	end
	if settings.switchoff and settings.switchoff ~= 0 then
		for _,v in ipairs(blocks_b) do
			v.id = settings.blockoff
		end
	end
	switchColorFunctions[switchcolors.colors[settings.color]]()
end

function smallSwitch:press()
	doSwitch(NPC.config[self.id])
	SFX.play(32)
	if not NPC.config[self.id].permanent then
		Animation.spawn(NPC.config[self.id].effect, self.x, self.y)
		self:kill()
	else
		self.data._basegame.pressed = true
	end
end

function smallSwitch:onTickNPC()
	if Defines.levelFreeze then
		return
	end

	if NPC.config[self.id].permanent then
		local data = self.data._basegame
		if data.friendly == nil then
			data.friendly = self.friendly
			data.pressed = self.friendly
		end

		if not data.pressed then
			self.friendly = data.friendly
		else
			self.friendly = true
		end
	end

	if self:mem(0x12A, FIELD_WORD) <= 0 or self:mem(0x138, FIELD_WORD) > 0 or self:mem(0x12C, FIELD_WORD) > 0 or self.friendly then
		return
	end

	for _,p in ipairs(Player.get()) do
		if p.standingNPC ~= nil and self == p.standingNPC then
			smallSwitch.press(self)
			break
		end
	end
	
	topCollisionBox.x = self.x
	topCollisionBox.y = self.y - 1
	topCollisionBox.width = self.width
	for k,v in ipairs(Colliders.getColliding{
		a = topCollisionBox,
		b = NPC.HITTABLE .. NPC.UNHITTABLE,
		btype = Colliders.NPC,
		collisionGroup = self.collisionGroup,
		filter = function(other)
			return NPC.config[other.id].isheavy
		end
	}) do
		if v:mem(0x12A, FIELD_WORD) > 0 and v:mem(0x138, FIELD_WORD) == 0 and v:mem(0x12C, FIELD_WORD) == 0 then
			smallSwitch.press(self)
			break
		end
	end

end

function smallSwitch.onDrawNPC(npc)
	if not npc.isHidden then
		local data = npc.data._basegame
		
		if data.pressed then
			npc.animationFrame = 1
		else
			npc.animationFrame = 0
		end
	end
end

return smallSwitch