-- GregTextPlus plugin — port of plugins/GregTextPlus.ahk.
--
-- Hold the shortcut: the cursor jumps to that slider and the left button goes
-- down. Move the mouse left/right to drag the value. Release the key (or
-- Ctrl/Alt) to let go. Slider positions: config.gregTextPlus.
--
--   Ctrl+Alt+A  drag X     Ctrl+Alt+W  drag Y     Ctrl+Alt+S  drag Size
local config = require("config")
local mouse  = require("lib.mouse")

local G = {}
local types = hs.eventtap.event.types
local drag = nil   -- active drag state

local function finish()
    local d = drag
    if not d then return end
    drag = nil
    d.watch:stop()
    d.tap:stop()
    mouse.leftUp()
end

local function start(pt, mods)
    if drag then return end
    local p = mouse.resolve(pt)
    mouse.moveTo(p)
    hs.timer.usleep(15000)
    mouse.leftDown(p)

    -- A synthetic button-down doesn't make macOS report the physical mouse's
    -- movement as a drag, so turn mouse-moved events into left-drag events
    -- for as long as the key is held.
    local tap = hs.eventtap.new({ types.mouseMoved, types.leftMouseDragged }, function(e)
        if e:getType() == types.mouseMoved then e:setType(types.leftMouseDragged) end
        if config.gregTextPlus.stripModifiers then e:setFlags({}) end
        return false
    end)
    tap:start()

    -- Release if any of the hotkey's modifiers is let go (AHK checked Ctrl+Alt).
    local watch = hs.timer.doEvery(0.01, function()
        local held = hs.eventtap.checkKeyboardModifiers()
        for _, m in ipairs(mods) do
            if not held[m] then return finish() end
        end
    end)

    drag = { tap = tap, watch = watch }
end

function G.bind(g)
    local c = config.gregTextPlus
    local function dragKey(spec, pt)
        local b
        b = g:bind(spec, function() start(pt, b.mods) end, finish)
    end
    dragKey("^!a", c.x)
    dragKey("^!w", c.y)
    dragKey("^!s", c.size)
end

-- Safety: if Hammerspoon reloads mid-drag, never leave the button down.
function G.stop() finish() end

return G
