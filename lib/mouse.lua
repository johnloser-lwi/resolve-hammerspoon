-- Synthetic mouse: moves, clicks, button down/up, and coordinate resolution.
--
-- All clicks are posted with no modifier flags, so a held Ctrl/Alt from the
-- triggering hotkey never turns a click into Ctrl+click (= right-click on Mac).
local config = require("config")
local util   = require("lib.util")
local apps   = require("lib.apps")

local M = {}
local types = hs.eventtap.event.types
local props = hs.eventtap.event.properties

function M.pos()
    return hs.mouse.absolutePosition()
end

-- Config point -> absolute point, honoring config.coordMode.
function M.resolve(pt)
    if config.coordMode == "window" then
        local win = apps.focusedWindow()
        if win then
            local f = win:frame()
            return { x = f.x + pt.x, y = f.y + pt.y }
        end
        util.log.w("coordMode=window but no focused window; using screen coordinates")
    end
    return { x = pt.x, y = pt.y }
end

function M.post(eventType, p, clickState)
    local e = hs.eventtap.event.newMouseEvent(eventType, p, {})
    e:setFlags({})
    if clickState then e:setProperty(props.mouseEventClickState, clickState) end
    e:post()
end

-- MouseMove: a real mouse-moved event so the app sees hover, not just a warp.
function M.moveTo(p)
    M.post(types.mouseMoved, p)
end

-- Put the cursor back without generating events (end of a macro).
function M.warp(p)
    hs.mouse.absolutePosition(p)
end

-- Click x, y (absolute). Defaults to the current cursor position (MouseClick).
function M.click(p)
    p = p or M.pos()
    M.moveTo(p)
    M.post(types.leftMouseDown, p, 1)
    hs.timer.usleep(math.floor(config.timing.click * 1000000))
    M.post(types.leftMouseUp, p, 1)
end

-- Click a config point (resolved through coordMode).
function M.clickAt(pt)
    M.click(M.resolve(pt))
end

function M.leftDown(p) M.post(types.leftMouseDown, p or M.pos(), 1) end
function M.leftUp(p)   M.post(types.leftMouseUp,   p or M.pos(), 1) end

return M
