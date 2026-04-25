local WorldMap = {}

registerEvent(WorldMap,"_onDrawOverworld")

-- Settings for the world map
WorldMap.settings = {}

-- Should we show the level title on the Hud?
WorldMap.settings.showTitle = true

-- Should the player be drawn onto the map?
WorldMap.settings.drawPlayer = true

function WorldMap._onDrawOverworld()
    -- Loop through all the levels and correctly place the level names and filenames where they go
    for i = 1,Level.count() do
        if not world.playerIsCurrentWalking and (world.playerX == Level.get().x and world.playerY == Level.get().y) then
            -- Level title
            if WorldMap.settings.showTitle then
                world:mem(0x3C, FIELD_STRING, Level.get().title)
            end
        end
    end

    -- Now draw the player
    --[[local WPHeight = 32
    if world. == 3 then
        WPHeight = 44
    elseif world. == 4 then
        WPHeight = 40
    else
        WPHeight = 32
    end]]
end

return WorldMap