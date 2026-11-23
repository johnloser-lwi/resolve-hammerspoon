-- AHK ToolTip equivalent: a small label next to the cursor that fades out.
local T = {}
local current, hideTimer

local STYLE = { font = ".AppleSystemUIFont", size = 12 }

function T.show(msg, seconds)
    if hideTimer then hideTimer:stop() end
    if current then current:delete() end

    local size = hs.drawing.getTextDrawingSize(msg, STYLE)
    local w, h = math.ceil(size.w) + 14, math.ceil(size.h) + 8
    local m = hs.mouse.absolutePosition()
    local c = hs.canvas.new({ x = m.x + 16, y = m.y + 16, w = w, h = h })
    c:level(hs.canvas.windowLevels.popUpMenu)
    c:behavior({ "canJoinAllSpaces", "transient" })
    c[1] = { type = "rectangle", action = "fill", fillColor = { hex = "#2B2B2B", alpha = 0.95 },
             strokeColor = { hex = "#555555" }, roundedRectRadii = { xRadius = 3, yRadius = 3 } }
    c[2] = { type = "text", text = msg, textColor = { white = 1 }, textFont = STYLE.font,
             textSize = STYLE.size, frame = { x = 7, y = 4, w = w - 14, h = h - 8 } }
    c:show()
    current = c
    hideTimer = hs.timer.doAfter(seconds or 1.2, function()
        if current == c then
            c:delete()
            current = nil
        end
    end)
end

return T
