local ctrlNotification = {}
local textplus = require('textplus')

local textFmt = {xscale=1, yscale=1, priority = 5, font = textplus.loadFont("textplus/font/6.ini")}

local currentText = nil
local currentOpacity = 0.0
local currentPlayerNum = 1

local currentBatteryText = nil
local batteryTimer = 0.0
local batteryCooldown = 0.0

Graphics.sprites.Register("hardcoded", "hardcoded-54")

function ctrlNotification.onChangeController(name, playerNum)
	local selectedText = "Selected"
	if Player.count() > 1 then
		selectedText = "Player " .. tostring(playerNum)
	end
	currentText = textplus.layout(selectedText .. " Controller: " .. name, 780, textFmt)
	currentOpacity = 1.0
	currentPlayerNum = playerNum
end

function ctrlNotification.onCameraDraw(camIdx)
	local fbWidth,fbHeight = Graphics.getMainFramebufferSize()
	local cam = Camera(camIdx)

	if (currentOpacity > 0) and (currentText ~= nil) then
		local power = Misc.GetSelectedControllerPowerLevel(currentPlayerNum)
		local x = 10-cam.renderX
		local y = fbHeight-10-currentText.height-cam.renderY
		if power >= 0 and power < 4 then
			Graphics.drawImageWP(Graphics.sprites.hardcoded[54].img, 10-cam.renderX, fbHeight-10-32-cam.renderY, 0, 32*(3-power), 32, 32, currentOpacity, 10)
			x = 10+32+10-cam.renderX
			y = fbHeight-10-16-(currentText.height*0.5)-cam.renderY
		end
		textplus.render{layout=currentText, x=x, y=y, color={currentOpacity, currentOpacity, currentOpacity, currentOpacity}, priority = 10}
		
		currentOpacity = math.max(0, currentOpacity - 0.01)
		
		if currentOpacity == 0 then
			currentText = nil
		end
	elseif batteryCooldown <= 0 then
		-- TODO: Sensibly handle second player controller power checking?
		local power = Misc.GetSelectedControllerPowerLevel()
		if power == 1 or power == 0 then
			if batteryTimer <= 0 then
				batteryTimer = lunatime.toTicks(4)
				if power == 1 then
					currentBatteryText = textplus.layout("Low Controller Battery", 780, textFmt)
				elseif power == 0 then
					currentBatteryText = textplus.layout("Controller Battery Empty", 780, textFmt)
				end
			elseif (currentBatteryText ~= nil) then
				batteryTimer = batteryTimer - 1
				if batteryTimer <= 0 then
					batteryCooldown = lunatime.toTicks(60)
				else
					if power == 1 then
						Graphics.drawImageWP(Graphics.sprites.hardcoded[54].img, 10-cam.renderX, fbHeight-10-32-cam.renderY, 0, 64+32*math.floor((batteryTimer%32)/16), 32, 32, 0.75, 10)
					elseif power == 0 then
						Graphics.drawImageWP(Graphics.sprites.hardcoded[54].img, 10-cam.renderX, fbHeight-10-32-cam.renderY, 0, 96, 32, 32, 0.75*math.floor((batteryTimer%16)/8), 10)
					end
					
					textplus.render{layout=currentBatteryText, x=10+32+10-cam.renderX, y=fbHeight-10-16-(currentBatteryText.height*0.5)-cam.renderY, color={0.75,0.75,0.75,0.75}, priority = 10}
				end
			end
		else
			batteryTimer = 0
			batteryCooldown = lunatime.toTicks(60)
		end
	else
		batteryCooldown = batteryCooldown - 1
	end
end

function ctrlNotification.onInitAPI()
	registerEvent(ctrlNotification, "onChangeController")
	registerEvent(ctrlNotification, "onCameraDraw")
end

return ctrlNotification
