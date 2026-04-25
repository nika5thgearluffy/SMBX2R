local monty = {}

local montymoles = {}

local dirtTable = {}

-- Mole hole Destructibles
monty.extraNPCExceptions = table.map{
	400, 430, 582, 583, 584, 585, 594, 595, 596, 597, 598, 599 
}
monty.extraBGOExceptions = table.map{
	201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218
}

function monty.spawnDirt(v)
	local entry = {}
	entry.x = v.x
	entry.y = v.y
	entry.id = v.uid
	table.insert(dirtTable[v.id], entry)
	v.data._basegame.hasDirt = true
end

function monty.removeObjects(v)
	if v.data._settings.holeRemovesBlock then
		for k,b in Block.iterateIntersecting(v.x + 1, v.y + 1, v.x + v.width - 2, v.y + v.height - 2) do
			if b.width <= v.width + 0.04 and b.height <= v.height then
				b.isHidden = true
			end
		end
		for k,b in NPC.iterateIntersecting(v.x + 1, v.y + 1, v.x + v.width - 2, v.y + v.height - 2) do
			if b.width <= v.width and b.height <= v.height then
				local cfg = NPC.config[b.id]
				if monty.extraNPCExceptions[b.id] or cfg.isvine or cfg.iscoin then
					b.isHidden = true
				end
			end
		end
		for k,b in BGO.iterateIntersecting(v.x + 1, v.y + 1, v.x + v.width - 2, v.y + v.height - 2) do
			if monty.extraBGOExceptions[b.id] then
				b.isHidden = true
			end
		end
	end
end

function monty.removeDirt(v)
	for k,w in ipairs(dirtTable[v.id]) do
		if w.id == v.uid then
			table.remove(dirtTable[v.id], k)
			v.data._basegame.hasDirt = false
			break
		end
	end
end

function monty.register(id)
    table.insert(montymoles, id)
	dirtTable[id] = {}
end

function monty.onInitAPI()
	registerEvent(monty, "onDraw")
end

function monty.onDraw()
    for k,m in ipairs(montymoles) do
        local dirtID = NPC.config[m].holeID or 223
        for k,v in ipairs(dirtTable[m]) do
            Graphics.drawImageToSceneWP(Graphics.sprites.background[dirtID].img, v.x, v.y, -85) -- TODO: BGO.spawn!
        end
    end
end

return monty