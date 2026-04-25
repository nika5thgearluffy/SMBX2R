----- common type handling functions for config files
local configTypes = {}

local lunajson = require("ext/lunajson")

local customParsers = {}
-- set up a new parser function for an arbitrary type name
function configTypes.registerPropParser(type, parse)
    customParsers[type] = parse
end

-- Encoder for casting to boolean
local function encodeBoolean(value)
	return (value ~= false) and (value ~= 0) and (value ~= nil)
end
configTypes.encodeBoolean = encodeBoolean

-- Encoder for casting to number
local function encodeNumber(value)
	if value == true then
		return 1
	elseif tonumber(value) then
		return tonumber(value)
	elseif not value then
		return 0
	else
		error("Cannot convert `" .. value .. "` (type: " .. type(value) .. ") to number")
	end
end
configTypes.encodeNumber = encodeNumber

-- Converts the property to the specified type, if possible
local function convertPropType(value, toType)
	if type(value) ~= toType then
		if toType == "boolean" then
			value = encodeBoolean(value)
		elseif toType == "number" then
			value = encodeNumber(value)
		elseif toType == "string" then
			value = tostring(value)
		elseif type(toType) == "function" then
			value = toType(value)
		elseif toType == "Color" then
			value = Color.parse(value)
        elseif customParsers[toType] then
            value = customParsers[toType](value)
        else
			error("Cannot convert `" .. value .. "` (type: " .. type(value) .. ") to " .. toType)
		end
	end
	return value
end
configTypes.convertPropType = convertPropType

-- converts a raw lua array to config array value
local configArrayMT = {} -- typename -> mt
local asArray
asArray = function(array, ofType)
    if ofType == nil and type(array) == "table" then
        ofType = type(array[1])
    end
    local tname = "ConfigArray<" .. ofType .. ">"
    if customParsers[ofType] == nil then
        -- set up parser
        local mt = { __type = tname }
        configTypes.registerPropParser(tname, function(input)
            local output = nil
            if type(input) == "table" then
                output = input
            elseif type(input) == "string" then
                pcall(function () output = lunajson.decode(input) end)
                if type(output) ~= "table" then
                    -- result must decode as table
                    output = nil
                end
            end
            if output == nil then
                error("Cannot convert `" .. input .. "` to config array of " .. ofType)
            end

            -- clone and verify the parsed input
            local cloned = {}
            for k, v in ipairs(output) do
                cloned[k] = convertPropType(v, ofType)
            end

            return setmetatable(cloned, mt)
        end)
    end
    return convertPropType(array, tname)
end
configTypes.asArray = asArray

return configTypes