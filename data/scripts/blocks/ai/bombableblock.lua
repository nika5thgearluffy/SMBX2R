local blockManager = require("blockManager")

local bombableBlock = {}


bombableBlock.idList = {}
bombableBlock.idMap = {}


function bombableBlock.register(blockID)
    blockManager.registerEvent(blockID, bombableBlock, "onPostExplosionBlock")

    table.insert(bombableBlock.idList,blockID)
    bombableBlock.idMap[blockID] = true
end

function bombableBlock.onInitAPI()
    registerEvent(bombableBlock, "onPostBlockPOWHit")
end


function bombableBlock.onPostExplosionBlock(v,explosion,playerObj)
    if explosion.collider:collide(v) then
        v:remove(true)
    end
end

function bombableBlock.onPostBlockPOWHit(v,powType)
    if bombableBlock.idMap[v.id] then
        v:remove(true)
    end
end


return bombableBlock