-- pauseMenu13.lua (v3.0.0, SMBX2R Edition)
-- By "The Sun God: Nika"
-- A more-accurate-to SMBX-1.3 pause menu, with capabilities such as returning to the map/hub, customization, and more!

local pauseMenu13 = {}

local textplus = require("textplus")

pauseMenu13.enabled = true -- If the pause menu needs to be disabled, set this to false.
pauseMenu13.enableCheatedAndNotSaveMenuChanges = true -- If false, the options won't change when the player has cheated/not cheated

if GameData.__basegame_notCheated == nil then
    GameData.__basegame_notCheated = true
end

local isPauseMenuOpen = false -- This is true when the menu is open.
local isPauseMenuQuittingGame = false -- True when the pause menu is saving and quitting the game. If this is set to true, a black screen will be drawn throughout the screen.
local isPauseMenuExitingLevel = false -- Same as above, except it's true when exiting a level.
local showBlackScreen = false -- Shows a black screen.
local menuPosition = 1 -- Position the menu is on. The default is 1
local maxMenuItems = 0 -- Max items from the pause menu.
local cheatedTimer = 0 -- Goes up when cheated

pauseMenu13.pauseFont = textplus.loadFont("pauseMenu13/font.ini") --The font used for the pause menu.
pauseMenu13.pauseCursor = Graphics.loadImage(getSMBXPath().."/scripts/pauseMenu13/pauseMenu13-arrow.png") --The arrow image used for the pause menu.

pauseMenu13.saveAndQuitSFX = 14 -- The sound that plays when saving and quitting the game.
pauseMenu13.saveSFX = 58 -- The sound that plays when saving and continuing the game.
pauseMenu13.menuNavigationUpSFX = 26 -- The sound that plays when moving up on an option.
pauseMenu13.menuNavigationDownSFX = 26 -- The sound that plays when moving down on an option.
pauseMenu13.menuNavigationToQuitOptionSFX = 26 -- The sound that plays when moving to the bottom option when pressing run.
pauseMenu13.pauseMenuOpenSFX = 30 -- The sound that plays when opening the pause menu.
pauseMenu13.pauseMenuCloseSFX = 30 -- The sound that plays when closing the pause menu.
pauseMenu13.exitLevelSFX = 14 -- The sound that plays when exiting the level.

pauseMenu13.secondsUntilGameQuits = 0.5 -- Seconds it takes until the game entirely quits when saving and quitting.
pauseMenu13.secondsUntilLevelExit = 0.5 -- Seconds it takes until the game leaves the level when selecting "Exit to Map/Hub".

pauseMenu13.screenW = 800 -- The width of the screen. Change this if the screen is bigger/smaller than the SMBX2 resolution.
pauseMenu13.screenH = 600 -- The height of the screen. Change this if the screen is bigger/smaller than the SMBX2 resolution.

pauseMenu13.menuItems = {}

-- Below is the menu height, x/y positions of the menu, and box height for the box drawing.
pauseMenu13.total_menu_height = 0
pauseMenu13.menu_left_X = pauseMenu13.screenW / 2 - 183 + 62 -- pauseMenu13.screenW / 2 - 190 + 62
pauseMenu13.menu_top_Y = 0
pauseMenu13.menu_box_height = 200

function pauseMenu13.onInitAPI()
    registerEvent(pauseMenu13,"onInputUpdate")
    registerEvent(pauseMenu13,"onDraw")
    registerEvent(pauseMenu13,"onPause")
    registerEvent(pauseMenu13,"onFramebufferResize")
    registerEvent(pauseMenu13,"onCheatActivate")
end

function pauseMenu13.onFramebufferResize(width, height)
    -- Recalculate width/height
    pauseMenu13.screenW = width
    pauseMenu13.screenH = height
    pauseMenu13.menu_left_X = pauseMenu13.screenW / 2 - 183 + 62 --pauseMenu13.screenW / 2 - 190 + 62
end

-- Adds a menu item to the pause menu.
function pauseMenu13.addMenuOption(menuText, functionToDo)
    maxMenuItems = maxMenuItems + 1
    pauseMenu13.total_menu_height = (maxMenuItems) * 36 - 18;
    pauseMenu13.menu_top_Y = pauseMenu13.screenH / 2 - pauseMenu13.total_menu_height / 2;
    table.insert(pauseMenu13.menuItems, {menuText, functionToDo, maxMenuItems})
end

-- Finds an option and returns a number where the menu item should be.
function pauseMenu13.findMenuOption(menuText)
    local valueFound = 0
    for i = 1,maxMenuItems do
        if menuText == pauseMenu13.menuItems[i][1] then
            valueFound = i
            break
        end
    end
    return valueFound
end

-- Removes a menu option. Everything else to the right of the removed option will be shifted over to the left.
function pauseMenu13.removeMenuOption(menuText)
    local menuIdx = pauseMenu13.findMenuOption(menuText)
    for i = menuIdx, maxMenuItems do
        if i ~= maxMenuItems then
            pauseMenu13.menuItems[i] = pauseMenu13.menuItems[i + 1]
        end
        if i == maxMenuItems then
            pauseMenu13.menuItems[maxMenuItems] = nil
            maxMenuItems = maxMenuItems - 1
        end
    end
    pauseMenu13.total_menu_height = (maxMenuItems) * 36 - 18;
    pauseMenu13.menu_top_Y = pauseMenu13.screenH / 2 - pauseMenu13.total_menu_height / 2;
end

-- ONLY call this if you're readding menu options for your episode.
function pauseMenu13.resetMenuOptions()
    maxMenuItems = 0
    pauseMenu13.total_menu_height = (maxMenuItems) * 36 - 18;
    pauseMenu13.menu_top_Y = pauseMenu13.screenH / 2 - pauseMenu13.total_menu_height / 2;
    pauseMenu13.menuItems = {}
end

if (isOverworld) then
    pauseMenu13.addMenuOption("CONTINUE", (function() pauseMenu13.continueGame(false) end))
    pauseMenu13.addMenuOption("SAVE & CONTINUE", (function() pauseMenu13.continueGame(true) end))
    pauseMenu13.addMenuOption("SAVE & QUIT", (function() Routine.run(pauseMenu13.saveAndQuitGame) end))
else
    pauseMenu13.addMenuOption("CONTINUE", (function() pauseMenu13.continueGame(false) end))
    if FileFormats.openWorldHeader(Episode.filename()).isHubStyleWorld and Level.filename() ~= mem(0x00B25724, FIELD_STRING) then
        pauseMenu13.addMenuOption("RETURN TO HUB", (function() Routine.run(pauseMenu13.exitLevel) end))
    else
        pauseMenu13.addMenuOption("RETURN TO MAP", (function() Routine.run(pauseMenu13.exitLevel) end))
    end
    pauseMenu13.addMenuOption("SAVE & CONTINUE", (function() pauseMenu13.continueGame(true) end))
    pauseMenu13.addMenuOption("SAVE & QUIT", (function() Routine.run(pauseMenu13.saveAndQuitGame) end))
end

function pauseMenu13.unpauseJumpFailsafe()
    for _,p in ipairs(Player.get()) do
        if isOverworld then
            p:mem(0x17A, FIELD_BOOL, false)
        else
            p:mem(0x11E, FIELD_BOOL, false)
        end
    end
end

function pauseMenu13.saveAndQuitGame()
    SFX.play(pauseMenu13.saveAndQuitSFX)
    isPauseMenuQuittingGame = true
    showBlackScreen = true
    Audio.SeizeStream(-1)
    Audio.MusicStop()
    Routine.wait(pauseMenu13.secondsUntilGameQuits, true)
    Misc.saveGame()
    Misc.exitEngine()
end

function pauseMenu13.continueGame(canSave)
    if canSave == nil then
        canSave = false
    end
    if canSave then
        Misc.saveGame()
        SFX.play(pauseMenu13.saveSFX)
    else
        SFX.play(pauseMenu13.pauseMenuCloseSFX)
    end
    isPauseMenuOpen = false
    menuPosition = 1
    Misc.unpause()
    pauseMenu13.unpauseJumpFailsafe()
end

function pauseMenu13.exitLevel()
    SFX.play(pauseMenu13.saveAndQuitSFX)
    isPauseMenuExitingLevel = true
    showBlackScreen = true
    Audio.SeizeStream(-1)
    Audio.MusicStop()
    Routine.wait(pauseMenu13.secondsUntilLevelExit, true)
    Misc.unpause()
    if not isOverworld then
        if not FileFormats.openWorldHeader(Episode.filename()).isHubStyleWorld then
            Level.exit()
        else
            Level.load(mem(0x00B25724, FIELD_STRING))
        end
    else
        isPauseMenuOpen = false
        menuPosition = 1
        Misc.unpause()
        pauseMenu13.unpauseJumpFailsafe()
    end
end

function pauseMenu13.pauseUnpauseGame()
    if pauseMenu13.enabled then
        isPauseMenuOpen = not isPauseMenuOpen
        if isPauseMenuOpen then
            SFX.play(pauseMenu13.pauseMenuOpenSFX)
            Misc.pause()
        elseif not isPauseMenuOpen then
            SFX.play(pauseMenu13.pauseMenuCloseSFX)
            Misc.unpause()
            menuPosition = 1
        end
    end
end

function pauseMenu13.onCheatActivate(cheat)
    if pauseMenu13.enableCheatedAndNotSaveMenuChanges then
        if not (cheat.id == "redigitiscool" or cheat.id == "gdiredigit") and Defines.player_hasCheated then
            if pauseMenu13.findMenuOption("SAVE & CONTINUE") ~= 0 then
                pauseMenu13.removeMenuOption("SAVE & CONTINUE")
            end
            if pauseMenu13.findMenuOption("SAVE & QUIT") ~= 0 then
                pauseMenu13.menuItems[pauseMenu13.findMenuOption("SAVE & QUIT")][1] = "QUIT"
            end
        elseif (cheat.id == "redigitiscool" or cheat.id == "gdiredigit") then
            if pauseMenu13.findMenuOption("QUIT") ~= 0 then
                pauseMenu13.removeMenuOption("QUIT")
            end
            pauseMenu13.addMenuOption("SAVE & CONTINUE", (function() pauseMenu13.continueGame(true) end))
            pauseMenu13.addMenuOption("SAVE & QUIT", (function() Routine.run(pauseMenu13.saveAndQuitGame) end))
            GameData.__basegame_notCheated = true
        end
    end
end

function pauseMenu13.onInputUpdate()
    for _,p in ipairs(Player.get()) do
        if isPauseMenuOpen then
            if p.keys.run == KEYS_PRESSED then
                if menuPosition ~= maxMenuItems then
                    SFX.play(pauseMenu13.menuNavigationToQuitOptionSFX)
                end
                menuPosition = maxMenuItems
            end
            if p.keys.up == KEYS_PRESSED then
                menuPosition = menuPosition - 1
                if menuPosition < 1 then
                    menuPosition = maxMenuItems
                end
                SFX.play(pauseMenu13.menuNavigationUpSFX)
            end
            if p.keys.down == KEYS_PRESSED then
                menuPosition = menuPosition + 1
                if menuPosition > maxMenuItems then
                    menuPosition = 1
                end
                SFX.play(pauseMenu13.menuNavigationDownSFX)
            end
            if p.keys.jump == KEYS_PRESSED then
                for i = 1,maxMenuItems do
                    if menuPosition == pauseMenu13.menuItems[i][3] then
                        pauseMenu13.menuItems[i][2]()
                    end
                end
            end
        end
    end
end

function pauseMenu13.onDraw()
    if isPauseMenuOpen then
        Graphics.drawBox{x = pauseMenu13.screenW / 2 - 190, y = pauseMenu13.screenH / 2 - pauseMenu13.menu_box_height / 2, width = 380, height = pauseMenu13.menu_box_height, color = Color.black, priority = 6}
        for i = 1,maxMenuItems do
            textplus.print{text = pauseMenu13.menuItems[i][1], x = pauseMenu13.menu_left_X, y = pauseMenu13.menu_top_Y + (i - 1) * 36, priority = 6.1, xscale = 2, yscale = 2, font = pauseMenu13.pauseFont}
        end
        Graphics.drawImageWP(pauseMenu13.pauseCursor, pauseMenu13.menu_left_X - 20, pauseMenu13.menu_top_Y + ((menuPosition - 1) * 36), 6.1)
    end
    if showBlackScreen then
        Graphics.drawScreen{priority = 10, color = Color.black}
    end
    cheatedTimer = cheatedTimer + 1
end

function pauseMenu13.onPause(eventObj)
    if not eventObj.cancelled then
        if not Misc.inEditor() then
            if maxMenuItems >= 1 then
                eventObj.cancelled = true
                pauseMenu13.pauseUnpauseGame()
            end
        end
    end
end

return pauseMenu13