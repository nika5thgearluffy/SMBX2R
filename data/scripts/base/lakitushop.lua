-- Custom lakitu management
local lakituArray = {}		-- Table of spawned custom lakitus

local lakitushop = {}

local textplus = require("textplus")
local currencies = require("currencies")
local tableinsert = table.insert

SaveData._lakitushop = SaveData._lakitushop or {}
local sd = SaveData._lakitushop
sd.stock = sd.stock or {}

local presets = {}

lakitushop.defaultConfig = {
	columns = 3,
	rows = 3,
	confirmPurchase = false,
	defaultConfirmationOption = 0, -- -1 is cancel, 1 is buy, 0 requires you to make an input
	framesToOpen = 6,
	confirmationInputIsVertical = false, -- override the draw function if you want to use this
	confirmationFrameSequence = {1,2,3,3,2,1,4,5,5,4},
	confirmationArrowFrames = 4,
	confirmationButtonFrames = 6,
	priceFont = textplus.loadFont("textplus/font/3.ini"),
	speechFont = textplus.loadFont("textplus/font/4.ini"),
	useCurrencies = false,
	offsets = {
		lakitu = vector(-80, -58),
		itemIcon = vector(68, 36),
		cursor = vector(- 24, 37),
		speechmargin = vector(4, 4),
		speechsize = vector(0, 40),
		speechrect = vector(14,14,14,14),
		framerect = vector(22,22,22,22),
		confirmshadowrect = vector(12,12,12,12),
		card = vector(100, 90),
		cardTop = 52,
		margin = vector(30, 30),
	},
	graphics = {
		card = Graphics.sprites.hardcoded["58-4"].img,
		arrows = Graphics.sprites.hardcoded["58-2"].img,
		speech = Graphics.sprites.hardcoded["58-9"].img,
		hand = Graphics.sprites.hardcoded["58-3"].img,
		frame 	= Graphics.sprites.hardcoded["58-7"].img,
		lakitu 	= Graphics.sprites.hardcoded["58-5"].img,
		confirm = Graphics.sprites.hardcoded["58-10"].img,
		choose  = Graphics.sprites.hardcoded["58-11"].img,
		null	= Graphics.sprites.hardcoded["58-6"].img,
		coin = Graphics.sprites.hardcoded["33-2"].img
	}
}

local configMT = {
	__index = function(t, x)
		return lakitushop.defaultConfig[x]
	end
}

local configOffsetsMT = {
	__index = function(t, x)
		return lakitushop.defaultConfig.offsets[x]
	end
}

local configGraphicsMT = {
	__index = function(t, x)
		return lakitushop.defaultConfig.graphics[x]
	end
}

lakitushop.items = {}

function lakitushop.addPreset(name, args)
	if name == nil then
		error("Preset must be given a unique name!")
		return
	end
	-- args is as follows:
	-- args.items = list of items that are available
	-- args.config = config override
	if args.config == nil then
		args.config = {}
	end
	if args.config.offsets == nil then
		args.config.offsets = {}
	end
	if args.config.graphics == nil then
		args.config.graphics = {}
	end

	args.name = name

	setmetatable(args.config, configMT)
	setmetatable(args.config.offsets, configOffsetsMT)
	setmetatable(args.config.graphics, configGraphicsMT)

	presets[name] = args

	return args
end

local currentConfig = lakitushop.defaultConfig

-- Store items
local store = {}

lakitushop.STATE_ERROR = -1		-- Error message displayed
lakitushop.STATE_NONE = 0		-- Store is closed
lakitushop.STATE_OPENING = 1		-- Store is opening
lakitushop.STATE_SELECTING = 2	-- Store is open and cursor is responding
lakitushop.STATE_CLOSING = 3		-- Store is closing
lakitushop.STATE_SELECTED = 4	-- You bought something! Good job!
lakitushop.STATE_CONFIRM = 5     -- Are you sure you want to make this purchase?

local selectpos = 1			-- Current position of shop cursor
local startpos = 1			-- Index range of items to show on the store menu
local endpos = 1

local storeAnimTimer = 0	-- Timer for store UI animation
local storeAnimState = 0	-- Animation state for store UI
local msgBlinkTimer = 0		-- Blink timer for error message text
local errorBecauseNoStock = false

local confirmationOption = 0
local confirmationTimer = 0

function lakitushop.getState(preset)
	if preset == nil then
		preset = currentConfig
	elseif type(preset) == "string" then
		preset = presets[preset]
	end

	if preset == currentConfig then
		return storeAnimState
	else
		return lakitushop.STATE_NONE
	end
end

local textCaptureBuffer = Graphics.CaptureBuffer(800, 600)
lakitushop.textLayouts = {
	nocoins = nil,
	nostock = nil,
	confirm = nil,
	thanks = nil,
}

local itemLayouts = {}

local function refreshItemLayouts(item)
	local args = {
		color = Color.black, xscale = 2, yscale = 2,
		font = currentConfig.speechFont
	}
	if item.description ~= "" then
		itemLayouts[item.name] = textplus.layout(textplus.parse(item.name .. ": " .. item.description, args))
	else
		itemLayouts[item.name] = textplus.layout(textplus.parse(item.name, args))
	end
end

function lakitushop.refreshTextLayouts()
	local args = {
		color = Color.black, xscale = 2, yscale = 2
	}
	lakitushop.textLayouts.nocoins = textplus.layout(textplus.parse("No freebies!", args))
	lakitushop.textLayouts.nostock = textplus.layout(textplus.parse("Out of stock!", args))
	lakitushop.textLayouts.confirm = textplus.layout(textplus.parse("Are you sure?", args))
	lakitushop.textLayouts.thanks = textplus.layout(textplus.parse("Thanks!", args))
end

local buzzer = Misc.resolveSoundFile("extended/lakitushop-buzzer.ogg")

lakitushop.CONTAINER_NONE = nil
lakitushop.CONTAINER_RESERVE = -1
lakitushop.CONTAINER_BUBBLE = 283
lakitushop.CONTAINER_EGG = 96
lakitushop.CONTAINER_CRATE = 433
lakitushop.CONTAINER_EXPLOSIVECRATE = 434

local actingPlayer
local actingLakitu

local function getPrice(item)
	if item.priceFunction then
		return item:priceFunction()
	else
		if item.currencyPrice and item.currency and currentConfig.useCurrencies then
			return item.currencyPrice
		end
		return item.price
	end
end

local function getEffect(item)
	if item.effectFunction then
		return item:effectFunction()
	else
		return item.id
	end
end

local function getVisible(item)
	if item.visibleFunction then
		return item:visibleFunction()
	else
		return item.visible
	end
end

local function getStock(item)
	if item.saveStockToSaveData then
		return sd.stock[item.name]
	else
		return item.stock
	end
end

local function setStock(item, stock)
	if item.saveStockToSaveData then
		sd.stock[item.name] = stock
	else
		item.stock = stock
	end
end

local function canBuyItem(item)
	if item:getStock() == 0 then return false end
	local coins = 0
	if currentConfig.useCurrencies and item.currency ~= nil then
		if type(item.currency) == "string" then
			coins = currencies.getCurrency(item.currency):getMoney()
		else
			coins = item.currency:getMoney()
		end
	else
		coins = mem(0x00B2C5A8, FIELD_WORD)
	end
	return coins >= item:getPrice()
end

local function spawnNPCFromLakitu(id, containerid)
	if actingLakitu == nil or containerid == lakitushop.CONTAINER_RESERVE then
		actingPlayer.reservePowerup = id
		SFX.play(12)
	else
		local lakituType = type(actingLakitu)

		local mainID = id
		local ai1ID = nil
		if containerid then
			ai1ID = id
			mainID = containerid
		end
	
		if lakituType == "NPC" then
			actingLakitu.data._basegame.npcToSpawn = mainID
			actingLakitu.data._basegame.ai1 = ai1ID
			SFX.play(12)
		elseif lakituType == "Vector4" then
			lakitushop.spawnNPC(mainID, ai1ID, actingLakitu.x, actingLakitu.y, actingPlayer.section, actingLakitu.z, actingLakitu.w)
			SFX.play(9)
		elseif lakituType == "Vector2" then
			lakitushop.spawnNPC(mainID, ai1ID, actingLakitu.x, actingLakitu.y, actingPlayer.section, 0, 0)
			SFX.play(9)
		elseif lakituType == "Warp" then
			local x,y = actingLakitu.x + 0.5 * actingLakitu.width, actingLakitu.y + 0.5 * actingLakitu.height
			if actingLakitu.exitDirection == 1 then
				y = y + 0.5 * actingLakitu.height - 0.5 * NPC.config[mainID].height
			elseif actingLakitu.exitDirection == 2 then
				x = x + 0.5 * actingLakitu.width - 0.5 * NPC.config[mainID].width
			elseif actingLakitu.exitDirection == 3 then
				y = y - 0.5 * actingLakitu.height + 0.5 * NPC.config[mainID].height
			else
				x = x - 0.5 * actingLakitu.width + 0.5 * NPC.config[mainID].width
			end
			lakitushop.spawnNPC(mainID, ai1ID, x, y, actingLakitu.exitSection, 0, 0, actingLakitu.exitDirection)
			SFX.play(9)
		else
			Misc.warn("Unsupported Lakitu entity of type " .. lakituType .. ". Must be NPC, Vector4, Vector2, Warp, or nil.")
		end
	end
end

local function buyItem(item)
	if canBuyItem(item) then

		if item:getStock() > 0 then
			item:setStock(item:getStock() - 1)
		end

		if currentConfig.useCurrencies and item.currency ~= nil then
			local c
			if type(item.currency) == "string" then
				c = currencies.getCurrency(item.currency)
			else
				c = item.currency
			end
			c:addMoney(-item:getPrice())
		else
			mem(0x00B2C5A8, FIELD_WORD, mem(0x00B2C5A8, FIELD_WORD) - item:getPrice())
		end

		local id
		if item.effectFunction then
			id = item.effectFunction()
		else
			id = item.id
		end

		if id then
			spawnNPCFromLakitu(id, item.container)
			if closeShopOnBuy ~= false then
				lakitushop.close(true)
			end
		else
			if closeShopOnBuy == true then
				lakitushop.close(true)
			end
		end
	end
end

local function drawItem(item, x, y, width, height, selected)
	local coins = 0
	if currentConfig.useCurrencies and item.currency ~= nil then
		if type(item.currency) == "string" then
			coins = currencies.getCurrency(item.currency):getMoney()
		else
			coins = item.currency:getMoney()
		end
	else
		coins = mem(0x00B2C5A8, FIELD_WORD)
	end

	local x = x + 0.5 * width - 0.5 * currentConfig.graphics.card.width
	local y = y + 0.5 * height - 0.5 * (currentConfig.graphics.card.height - currentConfig.offsets.cardTop)

	-- Checkered background
	Graphics.draw {
		x = x, y = y,
		type = RTYPE_IMAGE,
		priority = 5,
		image = currentConfig.graphics.card,
		sourceX = 0, sourceY = 0,
		sourceWidth = currentConfig.graphics.card.width, sourceHeight = currentConfig.offsets.cardTop
	}

	-- Card frame (top fringe)
	if selected then
	end
	
	if item.icon ~= nil then
		local ICONWIDTH, ICONHEIGHT = currentConfig.offsets.itemIcon.x, currentConfig.offsets.itemIcon.y
		local itemWidth = math.min(ICONWIDTH, item.icon.width)
		local itemHeight = math.min(ICONHEIGHT, item.icon.height)

		local h = item.icon.height
		if item.defaultIcon then
			local cfg = NPC.config[item.id]
			h = cfg.gfxheight
			if h == 0 then
				h = cfg.height
			end

			itemHeight = math.min(itemHeight, h)
		end

		local sourceX = 0.5 * item.icon.width - 0.5 * itemWidth
		local sourceY = 0.5 * h - 0.5 * itemHeight

		Graphics.drawImageWP(
			item.icon,
			x + 8 + 0.5 * ICONWIDTH - 0.5 * itemWidth,
			y + 8 + 0.5 * ICONHEIGHT - 0.5 * itemHeight,
			sourceX,
			sourceY,
			itemWidth,
			itemHeight,
			5
		)
	end

	local canBuy = canBuyItem(item)
	if not canBuy then
		Graphics.draw {
			x = x,
			y = y,
			type = RTYPE_IMAGE,
			priority = 5,
			image = currentConfig.graphics.null,
			opacity = 0.7
		}
	end

	Graphics.draw {
		x = x, y = y,
		type = RTYPE_IMAGE,
		priority = 5,
		image = currentConfig.graphics.card,
		sourceX = 0, sourceY = currentConfig.offsets.cardTop,
		sourceWidth = currentConfig.graphics.card.width,
		sourceHeight = currentConfig.offsets.cardTop
	}

	-- Card frame (bottom)
	Graphics.draw {
		x = x, y = y + currentConfig.offsets.cardTop,
		type = RTYPE_IMAGE,
		priority = 5,
		image = currentConfig.graphics.card,
		sourceX = 0, sourceY = currentConfig.offsets.cardTop * 2,
		sourceWidth = currentConfig.graphics.card.width, sourceHeight = currentConfig.graphics.card.height - 2 * currentConfig.offsets.cardTop
	}
					
	-- Price
	local color = Color(0.7, 0, 0.2)
	if canBuy then
		color = Color.black
	end

	if currentConfig.useCurrencies and item.currency then
		local c = item.currency
		if type(c) == "string" then
			c = currencies.getCurrency(item.currency)
		end

		if c.icon then
		Graphics.drawImageWP(c.icon, x + 6, y + 64 - 0.5 * c.icon.height, 5)
		end
	else
		Graphics.drawImageWP(currentConfig.graphics.coin, x + 6, y + 64 - 0.5 * currentConfig.graphics.coin.height, 5)
	end

	textplus.print{
		font = currentConfig.priceFont,
		text = tostring(item:getPrice()),
		pivot = vector(1, 0.5),
		xscale = 2,
		yscale = 2,
		color = color,
		x = x + 78,
		y = y + 72,
		priority = 5
	}
end

-- currency - string/currency - The currencies.lua currency used. If the config to use currencies is set to false, only regular coins will be used either way.
-- price - number - The cost of the item. Defaults to 10
-- priceFunction - function - The cost of the item, expressed as a function that returns a number. Can be used to handle discounts. Replaces "price"
-- id - number - The ID of NPC to spawn
-- effectFunction - function - The function to execute when the item is purchased, if it should not be a NPC. Replaces id. If the function returns a number, it is treated as an NPC spawn.
-- stock - number - The amount available for purchase. Defaults to -1 (infinite)
-- saveStockToSaveData - bool - If true, stock is remembered across playthroughs. Defaults to true.
-- container - CONTAINER - The container the item should be delivered in. Defaults to lakitushop.CONTAINER_NONE
-- name - string - The name the item should show in the shop. Name is used to index stock in savedata, so it should be unique.
-- description - string - The item's description text. Appended to the name in the speech dialog.
-- visible - bool - Whether the item is visible in the shop
-- visibleFunction - function - Whether the item is visible in the shop, expressed as a function that returns a bool
-- Icon - Image/string - The icon to display next to the name, or its file path. If the id is set and the icon is nil, it defaults to show the center of the first frame of the NPC
-- currencyPrice - number - If set, the price is instead treated as a fallback. This argument is used for the default items, but is not very useful in user code.
-- closeShopOnBuy - bool - Sets whether an item should close the shop when bought. By default it is true for items using id, and false for items using effectFunction.
function lakitushop.addItem(args)
	if args.name == nil then
		error("Must provide a unique name for the item.")
		return
	end
	local item = {
		currency = args.currency or "Coins",
		id = args.id or 9,
		container = args.container,
		stock = args.stock or -1,
		saveStockToSaveData = args.saveStockToSaveData,
		effectFunction = args.effectFunction,
		price = args.price or 10,
		priceFunction = args.priceFunction,
		visible = args.visible,
		visibleFunction = args.visibleFunction,
		name = args.name,
		description = args.description or "",
		icon = args.icon,
		currencyPrice = args.currencyPrice,
		closeShopOnBuy = args.closeShopOnBuy
	}

	if type(item.icon) == "string" then
		item.icon = Graphics.loadImageResolved(item.icon)
	end

	if item.icon == nil and args.id ~= nil then
		item.icon = Graphics.sprites.npc[item.id].img
		item.defaultIcon = true
	end

	if item.visible == nil and item.visibleFunction == nil then
		item.visible = true
	end

	if item.saveStockToSaveData == nil then
		item.saveStockToSaveData = true
	end

	if item.saveStockToSaveData then
		if sd.stock[item.name] == nil then
			sd.stock[item.name] = item.stock
		end
	end

	item.refreshLayouts = refreshItemLayouts
	item.getStock = getStock
	item.setStock = setStock
	item.getPrice = getPrice
	item.getEffect = getEffect
	item.getVisible = getVisible
	item.draw = drawItem
	item.buy = buyItem

	refreshItemLayouts(item)

	table.insert(lakitushop.items, item)

	return item
end

function lakitushop.refreshItems(config)
	store = {}
	if config == nil or config.items == nil or #config.items == 0 then
		for k,v in ipairs(lakitushop.items) do
			if v:getVisible() then
				v:refreshLayouts()
				table.insert(store, v)
			end
		end
	else
		store = config.items
		for k,v in ipairs(config.items) do
			if v:getVisible() then
				v:refreshLayouts()
			end
		end
	end
end

function lakitushop.spawnNPC(id, ai1, x, y, section, speedX, speedY, warpDirection)
	local n = NPC.spawn(id, x, y, section, false, true)
	n.direction = math.sign(speedX)
	n.speedX = speedX
	n.speedY = speedY
	if warpDirection then
		n:mem(0x138, FIELD_WORD, 4)
		n:mem(0x13C, FIELD_WORD, warpDirection)
	end
	if ai1 then
		n.ai1 = ai1
	end

	return n
end

function lakitushop.dropItem(v, condition)
	local data = v.data._basegame
	-- The NPC will only be spawned if the user-defined condition is true.
	if data.npcToSpawn and (condition == nil or condition) then
		lakitushop.spawnNPC(
			data.npcToSpawn,
			data.ai1,
			v.x + 0.5 * v.width, v.y + 0.5 * v.height, v.section,
			2 * v.direction, -2
		)
		data.npcToSpawn = nil
		data.ai1 = nil
		return true
	end
end

-- The first argument is the player that can move the cursor in the lakitu shop menu
-- Regarding the second argument to this function:
-- If called with an NPC, it assumes it to be a shop lakitu and as part of its logic call lakitushop.dropItem to handle item dropping conditions.
-- If called with a Vector4, it takes the xy as the coordinate to spawn the NPC at (center), and takes the zw as the speed to apply to the NPC
-- Using a Vector2 is like using a Vector4, but with the zw as 0,0.
-- If called with a warp, the NPC will be ejected from the warp's exit (Warp generator-style). For projectile-style generation, use Vector4.
-- If called with nothing, any NPC items are spawned in (or dropped from) the acting player's reserve item box
function lakitushop.open(pl, lakitu, preset)
	if storeAnimState ~= lakitushop.STATE_NONE then return end
	currentConfig = lakitushop.defaultConfig

	if type(preset) == "string" then
		preset = presets[preset]
		if preset ~= nil then
			currentConfig = preset.config
		end
	elseif type(preset) == "table" then
		currentConfig = preset.config
	end
	lakitushop.refreshItems(preset)
	actingPlayer = pl
	actingLakitu = lakitu

	startpos = 1
	selectpos = 1
	endpos = #store

	storeAnimTimer = 0
	storeAnimState = lakitushop.STATE_OPENING
	if not Misc.isPausedByLua() then Misc.pause() end
	SFX.play(30)
end

function lakitushop.moveSelection(difference)
	local oldPos = selectpos
	selectpos = selectpos + difference
	SFX.play(26)
	-- Prevent selectpos from exiting bounds
	if selectpos < 1 then
		if oldPos == 1 then
			selectpos = #store
		else
			selectpos = 1
		end
	elseif selectpos > #store then 
		if oldPos == #store then
			selectpos = 1
		else
			selectpos = #store
		end
	end
end

function lakitushop.close(boughtSomething)
	if boughtSomething then
		-- Exit store
		storeAnimTimer = 40
		storeAnimState = lakitushop.STATE_SELECTED
		-- Cancel jump
		actingPlayer:mem(0x11e, FIELD_WORD, 1)
	end
	storeAnimTimer = currentConfig.framesToOpen
	storeAnimState = lakitushop.STATE_CLOSING
	if Misc.isPausedByLua() then Misc.unpause() end
	SFX.play(30)
end


-- Input management for store UI and dashing
function lakitushop.onInputUpdate()
	if storeAnimState == lakitushop.STATE_NONE then return end
	
	if storeAnimState == lakitushop.STATE_SELECTING then

		-- Move selection in the store
		if actingPlayer.keys.left == KEYS_PRESSED then 
			lakitushop.moveSelection(-1)
		elseif actingPlayer.keys.right == KEYS_PRESSED then
			lakitushop.moveSelection(1)
		end

		if actingPlayer.keys.up == KEYS_PRESSED then
			lakitushop.moveSelection(-currentConfig.columns)
		elseif actingPlayer.keys.down == KEYS_PRESSED then
			lakitushop.moveSelection(currentConfig.columns)
		end

		-- Exit the store when you hit the run button
		if actingPlayer.keys.run == KEYS_PRESSED then
			lakitushop.close()
		end

		if actingPlayer.keys.jump == KEYS_PRESSED then
			if canBuyItem(store[selectpos]) then
				if currentConfig.confirmPurchase then
					storeAnimState = lakitushop.STATE_CONFIRM
					confirmationOption = currentConfig.defaultConfirmationOption
					SFX.play(47)
				else
					store[selectpos]:buy()
				end
			else
				storeAnimState = lakitushop.STATE_ERROR
				errorBecauseNoStock = store[selectpos]:getStock() == 0
			end
		end

		if storeAnimState == lakitushop.STATE_ERROR then
			SFX.play(buzzer)
			msgBlinkTimer = 0
		end
	elseif storeAnimState == lakitushop.STATE_CONFIRM then
		local left = actingPlayer.keys.left
		local right = actingPlayer.keys.right
		if confirmationInputIsVertical then
			left = actingPlayer.keys.up
			right = actingPlayer.keys.down
		end
		if left == KEYS_PRESSED then
			confirmationOption = -1
			SFX.play(26)
			confirmationTimer = 0
		end
		if right == KEYS_PRESSED then
			confirmationOption = 1
			SFX.play(26)
			confirmationTimer = 0
		end

		if actingPlayer.keys.run == KEYS_PRESSED then
			storeAnimState = lakitushop.STATE_SELECTING
			SFX.play(76)
		end

		if actingPlayer.keys.jump == KEYS_PRESSED then
			if confirmationOption == -1 then
				storeAnimState = lakitushop.STATE_SELECTING
				SFX.play(76)
			elseif confirmationOption == 1 then
				storeAnimState = lakitushop.STATE_SELECTING
				store[selectpos]:buy()
			else
				SFX.play(buzzer)
			end
		end
		confirmationTimer = confirmationTimer + 1
	end
end

function lakitushop.draw9Slice(
	texture, xpos, ypos, BOXWIDTH, BOXHEIGHT,
	left, top, right, bottom)
	local width = texture.width
	local height = texture.height
	local x1 = {0, left/width, (width - right)/width}
	local x2 = {left/width, (width - right)/width, 1}
	local y1 = {0, top/height, (height - bottom)/height}
	local y2 = {top/height, (height - bottom)/height, 1}
	local w = {left, BOXWIDTH - left - right, right}
	local h = {top, BOXHEIGHT - top - bottom, bottom}
	local xv = {0, left, BOXWIDTH - right}
	local yv = {0, top, BOXHEIGHT - right}
	
	local vt = {}
	local tx = {}

	for x = 1, 3 do
		for y=1, 3 do
			tableinsert(vt, xpos + xv[x])
			tableinsert(vt, ypos + yv[y])

			tableinsert(tx, x1[x])
			tableinsert(tx, y1[y])

			for i=1, 2 do
				tableinsert(vt, xpos + xv[x] + w[x])
				tableinsert(vt, ypos + yv[y])
				tableinsert(tx, x2[x])
				tableinsert(tx, y1[y])

				tableinsert(vt, xpos + xv[x])
				tableinsert(vt, ypos + yv[y] + h[y])
				tableinsert(tx, x1[x])
				tableinsert(tx, y2[y])
			end

			tableinsert(vt, xpos + xv[x] + w[x])
			tableinsert(vt, ypos + yv[y] + h[y])
			tableinsert(tx, x2[x])
			tableinsert(tx, y2[y])
		end
	end

	Graphics.glDraw{
		vertexCoords = vt,
		textureCoords = tx,
		priority = 5,
		texture = texture,
		primitive = Graphics.GL_TRIANGLES
	}
end

-- Rendering frame of shop UI
function lakitushop.renderShopFrame(xpos, ypos, BOXWIDTH, BOXHEIGHT)
	local offsets = currentConfig.offsets
	lakitushop.draw9Slice(currentConfig.graphics.frame, xpos, ypos, BOXWIDTH, BOXHEIGHT,
	offsets.framerect.x, offsets.framerect.y, offsets.framerect.z, offsets.framerect.w)
end

local lastLayout = nil
local textOverflowTimer = 0

function lakitushop.drawConfirmationOverlay(x, y, boxwidth, boxheight, selection, timer)
	local centerX = x + 0.5 * boxwidth
	local centerY = y + 0.5 * boxheight

	local rect = currentConfig.offsets.confirmshadowrect

	Graphics.drawBox{
		x = x + rect.x,
		y = y + rect.y,
		width = boxwidth - rect.x - rect.z,
		height = boxheight - rect.y - rect.w,
		priority = 5,
		color = Color.black .. 0.5
	}

	local leftFrame = 0
	local midFrame = -1
	local rightFrame = 0

	local sequence = currentConfig.confirmationFrameSequence
	if selection == -1 then
		leftFrame = sequence[1+ (math.floor(timer/8)%#sequence)]
	elseif selection == 0 then
		midFrame = math.floor(timer/8)%currentConfig.confirmationArrowFrames
	else
		rightFrame = sequence[1+ (math.floor(timer/8)%#sequence)]
	end

	local width = currentConfig.graphics.confirm.width/currentConfig.confirmationButtonFrames
	local height = currentConfig.graphics.confirm.height/currentConfig.confirmationArrowFrames
	local menuWidth = 0.5 * currentConfig.graphics.choose.width + 20 + width

	Graphics.drawImageWP(currentConfig.graphics.confirm, centerX - menuWidth, centerY - 0.25 * currentConfig.graphics.confirm.height, width * leftFrame, currentConfig.graphics.confirm.height * 0.5, width, currentConfig.graphics.confirm.height * 0.5, 5)
	Graphics.drawImageWP(currentConfig.graphics.confirm, centerX + menuWidth - width, centerY - 0.25 * currentConfig.graphics.confirm.height, width * rightFrame, 0, width, currentConfig.graphics.confirm.height * 0.5, 5)
	Graphics.drawImageWP(currentConfig.graphics.choose, centerX - currentConfig.graphics.choose.width * 0.5, centerY - height/2, 0, height * midFrame, currentConfig.graphics.choose.width, height, 5)
end

function lakitushop.drawSpeechBubbleText(x, y, boxwidth, boxheight)
	local xv = x + 12
	local yv = y - 22
	local textAreaWidth = boxwidth + currentConfig.offsets.lakitu.x - 2 * currentConfig.offsets.speechmargin.x - currentConfig.offsets.speechrect.x - currentConfig.offsets.speechrect.z
	local currentLayout = itemLayouts[store[selectpos].name]
	-- Show name of item
	if storeAnimState == lakitushop.STATE_ERROR then
		if msgBlinkTimer < 9*6 then
			if msgBlinkTimer%(2*6) < 6 or msgBlinkTimer > 4*6 then
				if errorBecauseNoStock then
					currentLayout = lakitushop.textLayouts.nostock
				else
					currentLayout = lakitushop.textLayouts.nocoins
				end
			else
				currentLayout = nil
			end
			msgBlinkTimer = msgBlinkTimer + 1
		else
			msgBlinkTimer = 0
			if errorBecauseNoStock then
				currentLayout = lakitushop.textLayouts.nostock
			else
				currentLayout = lakitushop.textLayouts.nocoins
			end
			storeAnimState = lakitushop.STATE_SELECTING
		end
	elseif storeAnimState == lakitushop.STATE_SELECTED then
		currentLayout = lakitushop.textLayouts.thanks
	elseif storeAnimState == lakitushop.STATE_CONFIRM then
		currentLayout = lakitushop.textLayouts.confirm
	end

	if currentLayout then
		if lastLayout ~= currentLayout then
			textCaptureBuffer:clear(-100)
			textplus.render{
				x = 0,
				y = 0,
				layout = currentLayout,
				target = textCaptureBuffer,
				priority = 5
			}

			textOverflowTimer = 0
		end

		local w = math.max(0, currentLayout.width - textAreaWidth)

		if w > 0 then
			textOverflowTimer = (textOverflowTimer + 1) % currentLayout.width
		end

		Graphics.drawBox{
			x = xv,
			y = yv - 0.5 * currentLayout.height,
			priority = 5,
			texture = textCaptureBuffer,
			width = textAreaWidth,
			height = currentLayout.height,
			sourceX = math.clamp(textOverflowTimer - 40, 0, w),
			sourceY = 0,
			sourceWidth = textAreaWidth,
			sourceHeight = currentLayout.height
		}
	end

	lastLayout = currentLayout
end

function lakitushop.drawThumbsUp(x, y)
	-- Thumbs up! You did it!
	Graphics.draw {
		x = x, y = y,
		type = RTYPE_IMAGE,
		priority = 5,
		image = currentConfig.graphics.hand
	}
end

function lakitushop.drawLakitu(x, y, width, height)
	-- Render lakitu mascot
	Graphics.draw {
		x = x + width + currentConfig.offsets.lakitu.x, y = y + currentConfig.offsets.lakitu.y,
		type = RTYPE_IMAGE,
		priority = 5,
		image = currentConfig.graphics.lakitu
	}
end

function lakitushop.drawSpeechBubble(x, y, width, height)
	local offsets = currentConfig.offsets
	lakitushop.draw9Slice(currentConfig.graphics.speech,
		x + offsets.speechmargin.x, y - offsets.speechmargin.y - offsets.speechsize.y,
		width - offsets.speechmargin.x * 2 + offsets.lakitu.x, offsets.speechsize.y,
		offsets.speechrect.x, offsets.speechrect.y, offsets.speechrect.z, offsets.speechrect.w)
end

function lakitushop.drawScrollArrows(x, y, width, height, shouldRenderTop, shouldRenderBottom)
	-- Render scroll arrows
	local tick = math.floor(lunatime.drawtime()*2)%2
	if shouldRenderTop then
		Graphics.draw {
			x = x + width/2 - 9, y = y + 13 + 2*tick,
			type = RTYPE_IMAGE,
			priority = 5,
			image = currentConfig.graphics.arrows,
			sourceX = 0, sourceY = 0,
			sourceWidth = 18, sourceHeight = 14
		}
	end
	if shouldRenderBottom then
		Graphics.draw {
			x = x + width/2 - 9, y = y + height - 27 - 2*tick,
			type = RTYPE_IMAGE,
			priority = 5,
			image = currentConfig.graphics.arrows,
			sourceX = 0, sourceY = 14,
			sourceWidth = 18, sourceHeight = 14
		}
	end
end

function lakitushop.drawCursor(x, y)
	Graphics.draw {
		x = x - 4*math.floor(lunatime.drawtime()*2)%2, y = y,
		type = RTYPE_IMAGE,
		priority = 5,
		image = currentConfig.graphics.hand,
		sourceX = 0, sourceY = 0,
		sourceWidth = 32, sourceHeight = 32
	}
end

-- Custom sprite and UI management
function lakitushop.onDraw()
		
	if storeAnimState ~= lakitushop.STATE_NONE then
		-- Dimensions of shop menu
		local width = currentConfig.offsets.card.x*currentConfig.columns + currentConfig.offsets.margin.x * 2
		local height = currentConfig.offsets.card.y*currentConfig.rows + currentConfig.offsets.margin.y * 2
		-- Position of shop menu
		local rows = currentConfig.rows
		local x = (camera.width - width)/2
		local y = (camera.height - height)/2 - 16
		-- Rows and columns (x2, for rendering frame sections)
		
		-- Render menu according to current visual state
		if storeAnimState == lakitushop.STATE_OPENING or storeAnimState == lakitushop.STATE_CLOSING then
			
			local xmid = x + 0.5 * width
			local ymid = y + 0.5 * height
			local t = storeAnimTimer/currentConfig.framesToOpen

			-- Render shop frame
			lakitushop.renderShopFrame(
				xmid - 0.5 * width * t,
				ymid - 0.5 * width * t,
				width * t, height * t)
		else
			-- If there are too many items to fit all at once
			if #store > rows*currentConfig.columns then
				endpos = startpos + rows*currentConfig.columns - 1
				while selectpos > endpos do
					startpos = startpos + currentConfig.columns
					endpos = startpos + rows*currentConfig.columns - 1
				end
				while selectpos < startpos do
					startpos = startpos - currentConfig.columns
					endpos = startpos + rows*currentConfig.columns - 1
				end
			end
			if startpos < 1 then startpos = 1 end
			if endpos > #store then endpos = #store end
			-- Position to render selected card
			local selectedCardx = 0;
			local selectedCardy = 0;
			-- Render unselected cards
			for i = startpos, endpos do
				-- Calculate card positions
				local cardx = x + currentConfig.offsets.margin.x + ((i-1)%currentConfig.columns)*currentConfig.offsets.card.x
				local cardy = y + currentConfig.offsets.margin.y + math.floor((i - startpos)/currentConfig.columns)*currentConfig.offsets.card.y
				
				if i ~= selectpos then
					-- Render card
					store[i]:draw(cardx, cardy, currentConfig.offsets.card.x, currentConfig.offsets.card.y, false)
				else
					-- Save it for later
					selectedCardx = cardx
					selectedCardy = cardy
				end
			end
			
			-- Render shop frame
			lakitushop.renderShopFrame(x, y, width, height)
			
			-- Render selected card and picker glove
			store[selectpos]:draw(selectedCardx, selectedCardy, currentConfig.offsets.card.x, currentConfig.offsets.card.y, true)
			if storeAnimState == lakitushop.STATE_SELECTED then
				lakitushop.drawThumbsUp(selectedCardx + currentConfig.offsets.cursor.x, selectedCardy + currentConfig.offsets.cursor.y)
				storeAnimTimer = storeAnimTimer - 1
				if storeAnimTimer <= 0 then
					storeAnimTimer = currentConfig.framesToOpen
					storeAnimState = lakitushop.STATE_CLOSING
					if Misc.isPausedByLua() then Misc.unpause() end
					SFX.play(30)
				end
			else
				lakitushop.drawCursor(selectedCardx + currentConfig.offsets.cursor.x, selectedCardy + currentConfig.offsets.cursor.y)
			end

			lakitushop.drawSpeechBubble(x, y, width, height)
			lakitushop.drawLakitu(x, y, width, height)
			lakitushop.drawScrollArrows(x, y, width, height, math.ceil(startpos/currentConfig.columns) > 1, math.ceil(endpos/currentConfig.columns) < math.ceil(#store/currentConfig.columns))
			
			lakitushop.drawSpeechBubbleText(x, y, width, height)

			if storeAnimState == lakitushop.STATE_CONFIRM then
				lakitushop.drawConfirmationOverlay(x, y, width, height, confirmationOption, confirmationTimer)
			end
		end
		
		-- Increment/decrement timer
		if storeAnimState == lakitushop.STATE_OPENING then
			storeAnimTimer = storeAnimTimer + 1
			if storeAnimTimer >= currentConfig.framesToOpen then
				storeAnimTimer = currentConfig.framesToOpen
				storeAnimState = lakitushop.STATE_SELECTING
			end
		elseif storeAnimState == lakitushop.STATE_CLOSING then
			storeAnimTimer = storeAnimTimer - 1
			if storeAnimTimer <= 0 then
				storeAnimTimer = 0
				storeAnimState = lakitushop.STATE_NONE
			end
		end
	end
end


-- Default item definitions. Can be quickly accessed with, for instance, lakitushop.ITEM_MUSHROOM.visible = false and lakitushop.ITEM_FIREFLOWER.currencyPrice = 85
lakitushop.ITEM_MUSHROOM = lakitushop.addItem {
	visible = true,
	id=9,
	price=10, currencyPrice = 15,
	name="Super Mushroom"
}
lakitushop.ITEM_FIREFLOWER = lakitushop.addItem {
	visible = true,
	id=14,
	price=25, currencyPrice = 30,
	name="Fire Flower"
}
lakitushop.ITEM_ICEFLOWER = lakitushop.addItem {
	visible = true,
	id=264,
	price=25, currencyPrice = 30,
	name="Ice Flower"
}
lakitushop.MUSHROOM = lakitushop.ITEM_MUSHROOM
lakitushop.FIREFLOWER = lakitushop.ITEM_FIREFLOWER
lakitushop.ICEFLOWER = lakitushop.ITEM_ICEFLOWER
lakitushop.SUPER_LEAF = lakitushop.addItem {
	visible = true,
	id=34,
	price=25, currencyPrice = 30,
	name="Super Leaf"
}
lakitushop.TANOOKI_SUIT = lakitushop.addItem {
	visible = true,
	id=169,
	price=75, currencyPrice = 100,
	name="Tanooki Suit"
}
lakitushop.HAMMER_SUIT = lakitushop.addItem {
	visible = true,
	id=170,
	price=75, currencyPrice = 100,
	name="Hammer Suit"
}
lakitushop.ITEM_STARMAN = lakitushop.addItem {
	visible = true,
	id=293,
	price=80, currencyPrice = 150,
	name="Starman"
}
lakitushop.STARMAN = lakitushop.ITEM_STARMAN
lakitushop.ITEM_1UP = lakitushop.addItem {
	visible = false,
	id=90,
	price=100, currencyPrice = 100,
	name="1-UP Mushroom"
}
lakitushop.ONEUP = lakitushop.ITEM_1UP
lakitushop.KURIBO_SHOE = lakitushop.addItem {
	visible = true,
	id=35,
	price=75, currencyPrice = 100,
	name="Kuribo Shoe"
}
lakitushop.PODOBOO_SHOE = lakitushop.addItem {
	visible = false,
	id=191,
	price=80, currencyPrice = 125,
	name="Podoboo Shoe"
}
lakitushop.LAKITU_SHOE = lakitushop.addItem {
	visible = false,
	id=193,
	price=85, currencyPrice = 175,
	name="Lakitu Shoe"
}
lakitushop.YOSHI_GREEN = lakitushop.addItem {
	visible = true,
	id=95, container = lakitushop.CONTAINER_EGG,
	price=75, currencyPrice = 125,
	name="Green Yoshi"
}
lakitushop.YOSHI_RED = lakitushop.addItem {
	visible = false,
	id=100, container = lakitushop.CONTAINER_EGG,
	price=80, currencyPrice = 150,
	name="Red Yoshi"
}
lakitushop.YOSHI_BLUE = lakitushop.addItem {
	visible = false,
	id=98, container = lakitushop.CONTAINER_EGG,
	price=80, currencyPrice = 150,
	name="Blue Yoshi"
}
lakitushop.YOSHI_YELLOW = lakitushop.addItem {
	visible = false,
	id=99, container = lakitushop.CONTAINER_EGG,
	price=80, currencyPrice = 150,
	name="Yellow Yoshi"
}
lakitushop.YOSHI_PINK = lakitushop.addItem {
	visible = false,
	id=150, container = lakitushop.CONTAINER_EGG,
	price=80, currencyPrice = 150,
	name="Pink Yoshi"
}
lakitushop.YOSHI_PURPLE = lakitushop.addItem {
	visible = false,
	id=149, container = lakitushop.CONTAINER_EGG,
	price=80, currencyPrice = 150,
	name="Purple Yoshi"
}
lakitushop.YOSHI_CYAN = lakitushop.addItem {
	visible = false,
	id=228, container = lakitushop.CONTAINER_EGG,
	price=80, currencyPrice = 150,
	name="Cyan Yoshi"
}
lakitushop.YOSHI_BLACK = lakitushop.addItem {
	visible = false,
	id=148, container = lakitushop.CONTAINER_EGG,
	price=85, currencyPrice = 175,
	name="Cyan Yoshi"
}

function lakitushop.onStart()
	lakitushop.refreshTextLayouts()
end

registerEvent(lakitushop, "onStart")
registerEvent(lakitushop, "onInputUpdate")
registerEvent(lakitushop, "onDraw")

return lakitushop