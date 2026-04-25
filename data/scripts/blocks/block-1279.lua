local blockmanager = require("blockmanager")
local blockutils = require("blocks/blockutils")
local switch = require("blocks/ai/crashswitch")

local blockID = BLOCK_ID

local block = {}

local settings = blockmanager.setBlockSettings({
	id = blockID,
	smashable = 2,
	bumpable = true
})

local sound = Misc.resolveSoundFile("nitro")

local function trigger(v)
	SFX.play(sound)
	Defines.earthquake = math.max(Defines.earthquake, 32)
	
	local delayed = { {}, {}, {}, {} }
	for _,v in Block.iterateByFilterMap{[683]=true} do
		if blockutils.hiddenFilter(v) then
			if RNG.random() < 0.5 then
				table.insert(delayed[RNG.randomInt(1,4)], v)
			else
				blockutils.detonate(v, 5)
			end
		end
	end
	
	Routine.run(function()
		for _,d in ipairs(delayed) do
			Routine.waitFrames(2)
			
			for _,v in ipairs(d) do
				if v.isValid then
					blockutils.detonate(v, 5)
				end
			end
		end
	end)
end

switch.registerSwitch(blockID, trigger, 1280)

return block