-- Keyboard modifiers + mouse-sent keys (Mac-only addition).
--
-- The Swiftpoint X1 can send keys such as Up/Down from mouse buttons. On
-- Windows, holding Alt on the keyboard while pressing such a button gives
-- Alt+Up. On macOS the X1's keys arrive with only the X1's own modifiers, so
-- the Option/Ctrl/Shift/Cmd you are holding on the keyboard is ignored.
--
-- This listens to modifier changes, remembers what is held, and adds those
-- modifiers to the keys in config.modifierMerge.keys when they arrive without
-- them. Keys typed on the keyboard already carry their modifiers, so they are
-- unaffected. Hammerspoon's own keystrokes (e.g. WippZoom's arrow presses
-- while you hold Ctrl+Option) are skipped.
--
-- The callback only reads and sets event flags: no window or app lookups, so
-- it can never stall input if another app hangs.
local config = require("config")

local M = {}

local T = hs.eventtap.event.types
local P = hs.eventtap.event.properties
local MODS = { "cmd", "alt", "shift", "ctrl" }

local held = {}          -- modifiers currently held, from flagsChanged events
local watched = {}       -- keycode -> true
local myPid = hs.processInfo.processID

local function syncHeld(flags)
    for _, m in ipairs(MODS) do held[m] = flags[m] and true or nil end
end

function M.start()
    local cfg = config.modifierMerge
    if not cfg or not cfg.enabled then return end
    for _, name in ipairs(cfg.keys) do
        local kc = hs.keycodes.map[name]
        if kc then watched[kc] = true end
    end

    M.tap = hs.eventtap.new({ T.flagsChanged, T.keyDown, T.keyUp }, function(e)
        local t = e:getType()
        if t == T.flagsChanged then
            syncHeld(e:getFlags())
            return false
        end

        if not watched[e:getKeyCode()] then return false end
        if e:getProperty(P.eventSourceUnixProcessID) == myPid then return false end

        local flags = e:getFlags()
        local changed = false
        for _, m in ipairs(MODS) do
            if held[m] and not flags[m] then
                flags[m] = true
                changed = true
            end
        end
        if changed then e:setFlags(flags) end
        return false
    end):start()

    -- macOS switches a tap off if it is ever too slow (e.g. during a system
    -- hiccup). Turn it back on, and forget modifiers whose release it missed.
    M.watchdog = hs.timer.doEvery(5, function()
        if not M.tap:isEnabled() then
            held = {}
            M.tap:start()
        end
    end)
end

return M
