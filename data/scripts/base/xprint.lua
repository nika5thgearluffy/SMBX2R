local xprint = {}
local textplus = require("textplus")

xprint.backgroundColor = Color.black .. 0.3
xprint.formattingArgs = {plaintext = true}

local tableinsert = table.insert

--[[
QUICK & DIRTY DEBUG PRINTING LIB
To save yourself a dozen Text.print calls
                                            
v0.0.1                                    
                                            
ADDED:    2022-09-02                  
UPDATED:  2022-09-02

(someone please de-rixify this library!!)
--]]



--[[ xprint.printPairs args:

        values
            key/value pair table
            the properties to monitor

        position
            vector2 (optional, default (0,0) )
            the position to draw the debug monitor at

        x
            number
            the x position to draw the debug monitor at

        y
            number
            the y position to draw the debug monitor at

        keyWidth
            number (optional, default 180)
            the width of the key column

        valueWidth
            number (optional, default 20)
            the width of the value column

        priority
            number (optional, default 0)
            the priority to draw the debug monitor at
--]]

local monitoredMap = {}
local monitoredObjects = {}

local autoUnmonitorList = {}
local monitoredObjectNames = {}

function xprint.monitor(object, keys, title)
    monitoredObjectNames[object] = title or monitoredObjectNames[object]
    if monitoredMap[object] then
        monitoredMap[object] = table.append(monitoredMap[object], keys)
    else
        monitoredMap[object] = keys
        tableinsert(monitoredObjects, object)
    end
end

function xprint.stopMonitoring(object)
    if monitoredMap[object] then
        monitoredObjectNames[object] = nil
        monitoredMap[object] = nil
        for k,v in ipairs(monitoredObjects) do
            if v == object then
                table.remove(monitoredObjects, k)
            end
        end
    end
end

function xprint.print(object, keys, title)
    monitoredObjectNames[object] = title or monitoredObjectNames[object]
    xprint.monitor(object, keys)
    tableinsert(autoUnmonitorList, object)
end

Misc.monitor = xprint.monitor
Misc.stopMonitoring = xprint.stopMonitoring

local blackRects = {}

local function addNewRect(left, top, right)
    tableinsert(blackRects, left)
    tableinsert(blackRects, top)
    for i=1, 2 do
        tableinsert(blackRects, right)
        tableinsert(blackRects, top)
        tableinsert(blackRects, left)
        tableinsert(blackRects, 0)
    end
    tableinsert(blackRects, right)
    tableinsert(blackRects, 0)
end

local function resizeRect(bottom)
    local idx = #blackRects - 6

    if idx > 0 then
        blackRects[idx] = bottom
        blackRects[idx + 4] = bottom
        blackRects[idx + 6] = bottom
    end
end

function xprint.onDraw()
    local yOffset = 0
    local padX = 2
    local padY = 2
    local gapX = 6
    local gapY = 6
    local lineHeightMargin = 2

    local maxWidth = 160

    local lastColumnWidth = 0
    local needsNewLayout = true

    local layouts = {}
    blackRects = {}

    for k,v in ipairs(monitoredObjects) do
        local objKeys = monitoredMap[v]

        local column = #layouts

        local startX = column - 1
        if yOffset == 0 and column > 0 then
            startX = column + 1
        end

        addNewRect(math.max(startX, 0) * (maxWidth + gapX), yOffset, math.max(startX, 0) * (maxWidth + gapX) + maxWidth + 6)

        if monitoredObjectNames[v] then
            local title = textplus.layout(textplus.parse("<color yellow>" .. monitoredObjectNames[v] .. "</color>"), maxWidth - 10)

            local h = 0
            for l,line in ipairs(title) do
                line.startX = 10
                if l == #title then
                    line.descent = line.descent + 2 * lineHeightMargin
                end
                h = h + line.ascent + line.descent
            end

            if needsNewLayout then
                table.insert(layouts, title)
                needsNewLayout = false
            else
                for _,v in ipairs(title) do
                    tableinsert(layouts[#layouts], v)
                end
            end
            yOffset = yOffset + h
        end

        for idx, value in ipairs(objKeys) do
            local label = textplus.layout(textplus.parse(value, xprint.formattingArgs), maxWidth)
            local value = textplus.layout(textplus.parse(tostring(v[value], xprint.formattingArgs)), maxWidth - label.width - 6)

            for _,line in ipairs(label) do
                line.ascent = 9
                line.descent = -9
            end

            local h = 0
            for l,line in ipairs(value) do
                line.startX = maxWidth - line.width
                if l == #value then
                    line.descent = line.descent + lineHeightMargin

                    if idx == #objKeys then
                        line.descent = line.descent + 2 * padY + gapY
                    end
                end

                h = h + line.ascent + line.descent
            end

            yOffset = yOffset + h
            if idx == #objKeys then
                resizeRect(yOffset - padY - gapY)
            end

            if needsNewLayout then
                tableinsert(layouts, label)
                for _,v in ipairs(value) do
                    tableinsert(layouts[#layouts], v)
                end
                needsNewLayout = false
            else
                for _,v in ipairs(label) do
                    tableinsert(layouts[#layouts], v)
                end
                for _,v in ipairs(value) do
                    tableinsert(layouts[#layouts], v)
                end
            end

            if yOffset >= 590 then
                yOffset = 0
                needsNewLayout = true
                resizeRect(600)

                if idx ~= #objKeys then
                    startX = startX + 1
                    addNewRect(math.max(startX, 0) * (maxWidth + gapX), yOffset, math.max(startX, 0) * (maxWidth + gapX) + maxWidth + 6)
                end
            end
        end

        if yOffset >= 590 then
            yOffset = 0
            needsNewLayout = true
            resizeRect(600)
        end
    end

    resizeRect(yOffset)


    if #blackRects > 0 then
        Graphics.glDraw{
            primitive = Graphics.GL_TRIANGLES,
            priority = 10,
            vertexCoords = blackRects,
            color = xprint.backgroundColor,
        }
    end

    for k,v in ipairs(layouts) do
        textplus.render{
            x = (k-1) * (maxWidth + gapX + 2 * padX) + padX,
            y = padY,
            color = Color.white,
            priority = 10,
            layout = v
        }
    end

    -- local position = vector.zero2
    -- local position = args.position  or  vector.zero2
    -- local priority = args.priority  or  0
    -- local keyWidth = args.keyWidth  or  180
    -- local valueWidth = args.valueWidth  or  20 

    -- local i = 0
    -- for  k,v in pairs (args.values)  do

    --     local x = (args.x  or  position.x)
    --     local y = (args.y  or  position.y) + 12*i
    --     textplus.print{
    --         x = x,
    --         y = y,
    --         color = Color.white,
    --         text = tostring(k),
    --         priority = priority+0.001
    --     }
    --     i = i+1
    --     textplus.print{
    --         x = x + keyWidth,
    --         y = y,
    --         color = Color.white,
    --         text = tostring(v),
    --         pivot = vector(1,0),
    --         priority = priority+0.001
    --     }
    -- end

    for k,v in ipairs(autoUnmonitorList) do
        xprint.stopMonitoring(v)
    end

    autoUnmonitorList = {}
end

if Misc.inEditor() then
    registerEvent(xprint, "onDraw")
end    



return xprint