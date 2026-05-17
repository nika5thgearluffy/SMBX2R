local messageBox13 = {}

local textplus = require("textplus")
local tplusUtils = require("textplus/tplusutils")

-- Is the system disabled, or not?
messageBox13.enabled = true

-- The drawing priority for the message box.
messageBox13.priority = 5

-- The box image for the message box.
messageBox13.boxImage = Graphics.sprites.hardcoded[46].img
-- The font used for the message box.
messageBox13.font = textplus.loadFont("messageBox13/font.ini")

-- The sound to play when a message box pops up.
messageBox13.openSFX = 47
-- The sound to play when flipping pages.
messageBox13.pageSFX = 26
-- The sound to play when closing a message box.
messageBox13.closeSFX = 0

--Whether a message box is on or not.
local messageBoxOn = false
--The message shown on the screen
local message = ""
--The page marker, used with the <page> tag
local currentPageMarker = 1
--Calculated when showing a message
local maxBoxHeight = 0

function messageBox13.onInitAPI()
    registerEvent(messageBox13,"onMessageBox")
    registerEvent(messageBox13,"onDraw")
    registerEvent(messageBox13,"onInputUpdate")
end

local customTags = {}
function customTags.page(fmt, out, args)
    out[#out+1] = {page=true} -- Add page tag to stream
    return fmt
end

function messageBox13.parseTextForDialogMessage(text, args)
	local formattedText = textplus.parse(text, {font = messageBox13.font, xscale=1, yscale=1, color=Color.white}, customTags, {"page"})

	local pages = {}
	local page = {}
	for _,seg in ipairs(formattedText) do
		if seg.page then
			pages[#pages+1] = page
			page = {}
		else
			page[#page+1] = seg
		end
	end
	pages[#pages+1] = page
	
	return pages
end

function messageBox13.getDialogMessage(text)
    text = text or ""
    if maxWidth == nil then
        maxWidth = 27 * 17
    end
    
    --Create page list
    local pages = messageBox13.parseTextForDialogMessage(text)

    --Layout the pages
    for i=1,#pages do
        pages[i] = textplus.layout(pages[i], maxWidth)
    end
    
    return pages
end

function messageBox13.onDraw()
    if messageBoxOn then
        messageBox13.drawMessageBox()
    end
end

function messageBox13.onInputUpdate()
    local currentDialog = messageBox13.getDialogMessage(message)
    for _,p in ipairs(Player.get()) do
        if messageBoxOn then
            if p.keys.jump == KEYS_PRESSED and currentPageMarker < #currentDialog then
                currentPageMarker = currentPageMarker + 1
                SFX.play(messageBox13.pageSFX)
            elseif p.keys.jump == KEYS_PRESSED and currentPageMarker >= #currentDialog then
                if messageBox13.closeSFX ~= 0 then
                    SFX.play(messageBox13.closeSFX)
                end
                messageBox13.closeMessageBox()
            end
        end
    end
end

function messageBox13.activateMessageBox(content)
    message = content
    currentPageMarker = 1
    SFX.play(messageBox13.openSFX)
    Misc.pause()
    messageBoxOn = true
end

function messageBox13.closeMessageBox()
    messageBoxOn = false
    currentPageMarker = 1
    message = ""
    Misc.unpause()
    for _,p in ipairs(Player.get()) do
        p:mem(0x11E, FIELD_BOOL, false)
    end
end

function messageBox13.drawMessageBox()
    local currentDialog = messageBox13.getDialogMessage(message)
    
    local TextBoxW = messageBox13.boxImage.width
    local UseGFX = true
    local ScreenW = camera.width
    local ScreenH = camera.height
    
    if (ScreenW < messageBox13.boxImage.width) then
        TextBoxW = ScreenW - 50
        UseGFX = false
    end
    
    local charWidth = 18;
    local lineHeight = 17;

    local BoxY = 0;
    local BoxY_Start = ScreenH / 2 - 150;

    if(BoxY_Start < 60) then
        BoxY_Start = 60
    end

    --Draw background all at once:
    --how many lines are there?
    local lineStart = 0; -- start of current line
    local lastWord = 0; -- planned start of next line
    local numLines = 0; -- n lines
    local maxChars = ((TextBoxW - 24) / charWidth) + 1; -- 27 by default
    -- Text size without a NULL terminator
    
    local textSize = (#message - 1)

    --PASS ONE: determine the number of lines
    --Wohlstand's updated algorithm, no substrings, reasonably fast
    
    for i = lineStart + 1, #message, maxChars do
        numLines = numLines + 1
    end

    --Draw the background now we know how many lines there are.
    local totalHeight = numLines * lineHeight + 20

    --carefully render the background image...
    Graphics.drawBox{
        x = ScreenW / 2 - TextBoxW / 2,
        y = BoxY_Start,
        width = TextBoxW,
        height = 20,
        sourceWidth = TextBoxW,
        sourceHeight = 20,
        texture = messageBox13.boxImage,
        sourceX = 0,
        sourceY = 0,
        priority = messageBox13.priority,
    }
    local rndMidH = (currentDialog[currentPageMarker].height - 20)
    local gfxMidH = (messageBox13.boxImage.height - 40)
    local vertReps = (rndMidH / gfxMidH + 1)
    
    for i = 0, vertReps do
        Graphics.drawBox{
            x = ScreenW / 2 - TextBoxW / 2,
            y = BoxY_Start + 20 + rndMidH,
            sourceWidth = TextBoxW,
            sourceHeight = 20,
            texture = messageBox13.boxImage,
            sourceX = 0,
            sourceY = messageBox13.boxImage.height - 20,
            priority = messageBox13.priority,
        }
    end
    
    for i = 0, math.floor(vertReps) - 1 do
        Graphics.drawBox{
            x = ScreenW / 2 - TextBoxW / 2,
            y = BoxY_Start + 20 + i * gfxMidH,
            width = TextBoxW,
            sourceHeight = rndMidH - i * gfxMidH,
            texture = messageBox13.boxImage,
            sourceX = 0,
            sourceY = 20,
            priority = messageBox13.priority,
        }
    end
    
    --PASS TWO: draw the lines
    --Wohlstand's updated algorithm
    --modified to not allocate/copy a bunch of strings
    
    local firstLine = true
    BoxY = BoxY_Start + 10 + lineHeight
    
    textplus.render{x = ScreenW/2 - TextBoxW / 2 + 12, y = 160, layout = currentDialog[currentPageMarker], priority = messageBox13.priority + 0.001}
end

function messageBox13.onMessageBox(eventObj, content, player, npcTalkedTo)
    if messageBox13.enabled then
        eventObj.cancelled = true
        messageBox13.activateMessageBox(content)
    end
end

return messageBox13