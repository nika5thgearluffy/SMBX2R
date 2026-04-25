-- Currency system that streamlines currency creation and tracking.
-- By Emral, October 2019

-- How it works:
-- When a registered NPC is collected, the respective currency counter goes up by the specified value.

local npcManager = require("npcManager")

local ac = {}
local currencies = {}

local currencyMap = {}

-- Money saves by default into a subtable in SaveData, so that it can be carried around between levels.
SaveData._currencies = SaveData._currencies or {}
local sd = SaveData._currencies
local atLeastOneHijack = false

-- Retrieve a currency by name
function ac.getCurrency(name)
    return currencyMap[name]
end

-- Registration instructions below the local functions.

local function registerCoinInternal(counter, id, value)
    counter._cointypes[id] = value
end

local function registerLimitInternal(counter, limit, func)
    if func ~= nil and type(func) ~= "function" then
        error("Second argument to registerLimit must be a function reference.")
    end
    if limit <= 0 then
        error("Limit must be greater than 0.")
    end
    counter._limit = {value = limit, func = func}
end

local function checkLimit(counter)
    if counter._limit == nil then return end
    if counter._value > counter._limit.value then
		local diff = (counter._value - counter._limit.value)
        counter._value = counter._value - diff 
        if counter._limit.func then
            counter._limit.func(diff)
        end
    end
end

local function addMoneyInternal(counter, value)
    counter._value = math.max(counter._value + value, 0)
    checkLimit(counter)
    sd[counter.name] = counter._value
end

local function setMoneyInternal(counter, value)
    counter._value = math.max(value, 0)
    checkLimit(counter)
    sd[counter.name] = counter._value
end

local function getMoneyInternal(counter)
    return counter._value
end

local function compareMoneyInternal(counter, value)
    return counter._value >= value, counter._value - value
end

local function drawInternal(counter, x, y, priority, textOffsetX)
    local x = x or 16
    local y = y or -4 + 20 * counter._id
    local value = counter:getMoney()
    local priority = priority or 5
    if counter.icon == nil then
        Text.printWP(counter.name .. ": " .. tostring(value), 4, x, y, priority)
    else
        local textOffsetX = textOffsetX or counter.icon.width + 2
        Graphics.drawImageWP(counter.icon, x, y, priority)
        Text.printWP(tostring(value), 1, x + textOffsetX, y, priority)
    end
end

local function makeCurrency(name, hijack, icon)
    local icon = icon

    if type(icon) == "string" then
        icon = Graphics.loadImageResolved(icon)
    end
    return {
        registerCoin = registerCoinInternal, -- Registers a new NPC as a "coin". myCurrency:registerCoin(id, value)
        registerLimit = registerLimitInternal, -- Registers the limit of the currency. By default, there is no limit. When a limit is reached, the coin counter is emptied and a function is executed. myCurrency:registerLimit(value, functionToExecute)
        addMoney = addMoneyInternal, -- Adds value to the coin counter manually. myCurrency:addMoney(value) (value can be negative to subtract)
        setMoney = setMoneyInternal, -- Sets the absolute value of the coin counter. myCurrency:setMoney(value)
        getMoney = getMoneyInternal, -- Gets the absolute value of the coin counter. Can be used for drawing, for example. myCurrency:getMoney()
        compareMoney = compareMoneyInternal, -- Compares coin counter value to some other value. Useful for shops. myCurrency:compareMoney(valueToCompareTo). Returns whether counter is greater or equal to comparison value, and the difference as 2nd arg.
        draw = drawInternal, -- Draws the coin counter. The function can be overridden and is not called internally. Default implementation is for debug purposes. myCurrency:draw()

        hijackDefaultCounter = hijack, -- If set to true, this counter will derive its value from the default coin counter and won't register the deaths of default coin types. If at least one currency is registered to hijack the default counter, the default counter is automatically re-routed into this counter and will be permanently empty.
        _cointypes = {},
        _limit = nil,
        _value = 0,
        icon = icon,
        name = name
    }
end

local function register(currency)
    if sd[currency.name] then
        currency._value = sd[currency.name]
    end
    currency._id = #currencies + 1
    atLeastOneHijack = atLeastOneHijack or currency.hijackDefaultCounter
    table.insert(currencies, currency)
    currencyMap[currency.name] = currency
    return currency
end

-- Registers a new currency and returns it. Save a reference of it to keep track of it. Name is for savedata.
function ac.registerCurrency(name, icon)
    if type(name) == "table" then
        name.icon = icon or name.icon
        return register(name)
    end
    -- In the currency table you get back, all the functions accessible for a currency are saved.
    local currency = makeCurrency(name)
    currency.icon = icon
    return register(currency)
end

-- Default currencies. Enable them by calling currencies.registerCurrency(currencies.CURRENCY_COINS)
ac.CURRENCY_COINS = makeCurrency("Coins", true)
ac.CURRENCY_COINS.icon = Graphics.loadImageResolved("hardcoded-33-2.png")
ac.CURRENCY_STARCOINS = makeCurrency("Star Coins")
ac.CURRENCY_STARCOINS.setMoney = function(c, value)
    SaveData._basegame.starcoinCounter = value
end
ac.CURRENCY_STARCOINS.getMoney = function(c)
    c._value = SaveData._basegame.starcoinCounter
    return SaveData._basegame.starcoinCounter
end
ac.CURRENCY_STARCOINS.addMoney = function(c, value)
    SaveData._basegame.starcoinCounter = SaveData._basegame.starcoinCounter + value
end
ac.CURRENCY_STARCOINS.compareMoney = function(c)
    return SaveData._basegame.starcoinCounter >= value, SaveData._basegame.starcoinCounter - value
end
ac.CURRENCY_STARCOINS.icon = Graphics.loadImageResolved("hardcoded-51-1.png")
ac.CURRENCY_DRAGONCOINS = makeCurrency("Dragon Coins")
ac.CURRENCY_DRAGONCOINS:registerCoin(274, 1)
ac.CURRENCY_DRAGONCOINS.icon = Graphics.loadImageResolved("hardcoded-58-1.png")

-- Below is just code.

function ac.onInitAPI()
    registerEvent(ac, "onTickEnd")
    registerEvent(ac, "onPostNPCCollect")
end

local starcoinIDMap = {
    [310] = true
}

local defaultCoinIDMap = {
    [10] = true,
    [33] = true,
    [88] = true,
    [102] = true,
    [138] = true,
    [152] = true,
    [251] = true,
    [252] = true,
    [253] = true,
    [258] = true,
    [274] = true,
    [411] = true,
}

function ac.onTickEnd()
    if atLeastOneHijack then
        local hijackedValue = mem(0x00B2C5A8, FIELD_WORD)
        if hijackedValue > 0 then
            mem(0x00B2C5A8, FIELD_WORD, 0)
            for k,v in ipairs(currencies) do
                if v.hijackDefaultCounter then
                    v:addMoney(hijackedValue)
                end
            end
        end
    end
end

function ac.onPostNPCCollect(v, p)
    for k,c in ipairs(currencies) do
        if c._cointypes[v.id] then
            if not (c.hijackDefaultCounter and defaultCoinIDMap[v.id]) then
                c:addMoney(c._cointypes[v.id])
            end
        end
    end
end

return ac