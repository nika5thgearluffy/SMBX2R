-- Custom lakitu management
local lakituArray = {}		-- Table of spawned custom lakitus
local lakituGraphics = {
	[3] = pm.registerGraphic(CHARACTER_WARIO, "lakitu_fire.png"),
	[4] = pm.registerGraphic(CHARACTER_WARIO, "lakitu_leaf.png"),
	[6] = pm.registerGraphic(CHARACTER_WARIO, "lakitu_hammer.png"),
	[7] = pm.registerGraphic(CHARACTER_WARIO, "lakitu_ice.png")
}

-- Store items
local store = {}

-- Store config
local STOREUI_ROWS = 3		-- Number of rows of items displayed
local STOREUI_COLS = 3		-- Number of columns of items displayed
local STOREUI_OPENTIME = 6	-- How many frames does the shop UI take to open/close?

local STATE_ERROR = -1		-- Error message displayed
local STATE_NONE = 0		-- Store is closed
local STATE_OPENING = 1		-- Store is opening
local STATE_SELECTING = 2	-- Store is open and cursor is responding
local STATE_CLOSING = 3		-- Store is closing
local STATE_SELECTED = 4	-- You bought something! Good job!

local selectpos = 1			-- Current position of shop cursor
local startpos = 1			-- Index range of items to show on the store menu
local endpos = 1

local storeAnimTimer = 0	-- Timer for store UI animation
local storeAnimState = 0	-- Animation state for store UI
local shoplakitu = nil		-- Has a shop lakitu already spawned?
local shopErrorMsg = ""		-- Error message to show if insufficient funds or delivery is blocked
local msgBlinkTimer = 0		-- Blink timer for error message text

-- Input management during Misc.pause
local uptap, downtap, lefttap, righttap, jumptap, runtap = false
local upwaspressed, downwaspressed, leftwaspressed, rightwaspressed, jumpwaspressed, runwaspressed = false

local StoreUI = {
	card 	= pm.registerGraphic(CHARACTER_WARIO, "StoreUI\\StoreUI_card.png"),
	font 	= pm.registerGraphic(CHARACTER_WARIO, "StoreUI\\StoreUI_font.png"),
	frame 	= pm.registerGraphic(CHARACTER_WARIO, "StoreUI\\StoreUI_frame.png"),
	lakitu 	= pm.registerGraphic(CHARACTER_WARIO, "StoreUI\\StoreUI_lakitu.png"),
	frame2 	= pm.registerGraphic(CHARACTER_WARIO, "StoreUI\\StoreUI_nameframe.png"),
	hand 	= pm.registerGraphic(CHARACTER_WARIO, "StoreUI\\StoreUI_hand.png"),
	arrows	= pm.registerGraphic(CHARACTER_WARIO, "StoreUI\\StoreUI_arrows.png"),
	null	= pm.registerGraphic(CHARACTER_WARIO, "StoreUI\\StoreUI_null.png"),
	rednums	= pm.registerGraphic(CHARACTER_WARIO, "StoreUI\\StoreUI_rednums.png")
}

function wario.enableLakituHelper()
	wario.additem {id=284, 	price=100, 	name="Lakitu Helper",	container=CRATE_ID,	isLakituHelper=true,	iconpath="wario\\StoreUI\\StoreUI_lakituHelperIcon.png"}
end

function wario.disableLakituHelper()
	for i,item in ipairs(store) do
		if item[1] == 284 and item[6] then
			table.remove(store, i)
			
			-- Change store cursor
			local selectpos = 1
			local startpos = 1;		local endpos = #store;
			if #store > STOREUI_ROWS*STOREUI_COLS then endpos = startpos + STOREUI_ROWS*STOREUI_COLS - 1 end
			
			return true
		end
	end
end

-- Spawn a friendly Lakitu helper
local function spawnLakituHelper(x, y)
	if player.powerup > 2 and player.powerup ~= 5 then
		-- Spawn a friendly lakitu offscreen
		local lakitu = NPC.spawn(284, x, y, player.section, false, true)
		lakitu.friendly = true
		
		-- Change what it throws depending on powerup
		if player.powerup == 3 then
			lakitu.ai1 = 13			-- Fire: throws fireball
		elseif player.powerup == 4 then
			lakitu.ai1 = 171		-- Leaf: throws hammer
		elseif player.powerup == 6 then
			lakitu.ai1 = 291		-- Hammer: throws bomb
		elseif player.powerup == 7 then
			lakitu.ai1 = 265		-- Ice: throws iceball
		end
		
		-- Set lifetime and graphic
		lakitu.data.graphic = lakituGraphics[player.powerup]
		lakitu.data.timeLeft = 65*12
		lakituArray[#lakituArray + 1] = lakitu
	end
end

-- Initialize store
function wario.init()
	wario.enableLakituHelper()
end

-- Per-frame logic
function wario.onTick()
	-- If the player is Wario
	if player.character == CHARACTER_WARIO then
		for _, lakitu in pairs(lakituArray) do
			if lakitu.isValid then
				-- Age all player-spawned lakitus
				lakitu.data.timeLeft = lakitu.data.timeLeft - 1
				if lakitu.data.timeLeft <= 0 then
					Animation.spawn(63, lakitu.x + lakitu.width/2, lakitu.y + lakitu.height/2)
					lakitu:kill(9)
					lakitu = nil
					SFX.play(16)
				end
			else
				lakitu = nil
			end
		end
	end
end

-- Custom sprite and UI management
function wario.onDraw()
	-- If the player is Wario
	if player.character == CHARACTER_WARIO then
		-- Draw lakitu graphics
		for _, lakitu in pairs(lakituArray) do
			if lakitu.isValid then
				Graphics.draw {x = lakitu.x - 8, y = lakitu.y - 18, type = RTYPE_IMAGE, isSceneCoordinates = true, priority = -44,
							image = pm.getGraphic(CHARACTER_WARIO, lakitu.data.graphic), sourceY = lakitu.animationFrame*72, sourceHeight = 72}
			end
		end
	end
end