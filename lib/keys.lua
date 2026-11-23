-- AHK-style key specs -> Hammerspoon hotkeys and keystrokes.
--
--   "^+q"      Ctrl+Shift+Q            "{Enter}"   Return
--   "!+3"      Alt+Shift+3             "^{Space}"  Ctrl+Space
--   "+F3"      Shift+F3                "h"         plain h
--
-- The same spec maps to different physical modifiers depending on direction
-- (config.modifiers.trigger vs .send) — see config.lua.
local config = require("config")
local util   = require("lib.util")

local K = {}

local KEY_NAMES = {
    enter = "return", ["return"] = "return", tab = "tab", space = "space",
    esc = "escape", escape = "escape",
    up = "up", down = "down", left = "left", right = "right",
    home = "home", ["end"] = "end", pgup = "pageup", pgdn = "pagedown",
    -- Windows Backspace is the Mac "delete" key; Windows Delete is forward delete.
    bs = "delete", backspace = "delete", del = "forwarddelete", delete = "forwarddelete",
}

-- Returns mods (list of hs modifier names) and the hs key name.
function K.parse(spec, map)
    local mods, i = {}, 1
    while i < #spec do
        local mod = map[spec:sub(i, i)]
        if not mod then break end
        table.insert(mods, mod)
        i = i + 1
    end
    local key = spec:sub(i)
    local braced = key:match("^{(.+)}$")
    if braced then key = braced end
    local lower = key:lower()
    return mods, KEY_NAMES[lower] or lower
end

local function comboId(mods, key)
    local m = {}
    for _, v in ipairs(mods) do m[#m + 1] = v end
    table.sort(m)
    return table.concat(m, "+") .. ":" .. key
end

-- ---------------------------------------------------------------------------
-- Bindings: an hs.hotkey plus the "should it be on" state. `bindings.lua`
-- flips `setWanted` as the active app / layout changes (the #HotIf part).
-- ---------------------------------------------------------------------------
local registry = {}   -- comboId -> list of bindings

local Binding = {}
Binding.__index = Binding

function Binding:setWanted(wanted)
    self.wanted = wanted
    if wanted and not self.on then
        self.hotkey:enable()
        self.on = true
    elseif not wanted and self.on then
        self.hotkey:disable()
        self.on = false
    end
end

function K.bind(spec, pressed, released)
    local mods, key = K.parse(spec, config.modifiers.trigger)
    local ok, hk = pcall(hs.hotkey.new, mods, key, pressed, released)
    if not ok or not hk then
        util.log.e("could not create hotkey " .. spec .. ": " .. tostring(hk))
        return nil
    end
    local b = setmetatable({ spec = spec, mods = mods, key = key, hotkey = hk, on = false, wanted = false }, Binding)
    local id = comboId(mods, key)
    registry[id] = registry[id] or {}
    table.insert(registry[id], b)
    return b
end

-- ---------------------------------------------------------------------------
-- Sending
-- ---------------------------------------------------------------------------

-- A macro that re-sends its own hotkey (Alt+P, Alt+Shift+3) must not trigger
-- itself, so any live binding on the same physical combo is paused around the
-- send.
local function pauseSelf(mods, key)
    local list = registry[comboId(mods, key)]
    if not list then return end
    local paused = {}
    for _, b in ipairs(list) do
        if b.on then
            b.hotkey:disable()
            b.on = false
            paused[#paused + 1] = b
        end
    end
    if #paused == 0 then return end
    hs.timer.doAfter(0.15, function()
        for _, b in ipairs(paused) do
            if b.wanted and not b.on then
                b.hotkey:enable()
                b.on = true
            end
        end
    end)
end

-- Send one keystroke to the frontmost app. `spec` is either an AHK-style
-- string (modifiers translated through config.modifiers.send), or an exact
-- Mac combo that is sent untranslated: { {"ctrl"}, "space" }.
function K.resolveSend(spec)
    if type(spec) == "table" then return spec[1], spec[2] end
    return K.parse(spec, config.modifiers.send)
end

function K.send(spec)
    local mods, key = K.resolveSend(spec)
    pauseSelf(mods, key)   -- compares the physical combo being sent
    hs.eventtap.keyStroke(mods, key, math.floor(config.timing.keyStroke * 1000000))
end

-- Type literal text (SendInput "text").
function K.type(text)
    hs.eventtap.keyStrokes(text)
end

return K
