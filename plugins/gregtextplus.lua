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
    d.tap:stop()
    mouse.leftUp()
end

local myPid = hs.processInfo.processID
local srcPid = hs.eventtap.event.properties.eventSourceUnixProcessID

local function start(pt, mods)
    if drag then return end
    local p = mouse.resolve(pt)
    mouse.moveTo(p)
    hs.timer.usleep(15000)
    mouse.leftDown(p)

    local tap = hs.eventtap.new({ types.mouseMoved, types.leftMouseDragged, types.flagsChanged }, function(e)
        local t = e:getType()

        -- Release when one of the hotkey's modifiers (Ctrl/Option) is let go,
        -- like the AHK loop. Only real keyboard events count: macOS's overall
        -- modifier state can't be used, because posting our modifier-free
        -- click makes it report Ctrl/Option as released while you still hold
        -- them, which used to end the drag instantly.
        if t == types.flagsChanged then
            if e:getProperty(srcPid) ~= myPid then
                local flags = e:getFlags()
                for _, m in ipairs(mods) do
                    if not flags[m] then
                        hs.timer.doAfter(0, finish)
                        break
                    end
                end
            end
            return false
        end

        -- A synthetic button-down doesn't make macOS report the physical
        -- mouse's movement as a drag, so turn mouse-moved events into
        -- left-drag events for as long as the key is held.
        if t == types.mouseMoved then e:setType(types.leftMouseDragged) end
        if config.gregTextPlus.stripModifiers then e:setFlags({}) end
        return false
    end)
    tap:start()

    drag = { tap = tap }
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

-- Start/stop a drag by hand (debugging from the console or `hs`).
G.start = start
function G.stop() finish() end

return G
