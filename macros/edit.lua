-- Edit layout — port of macros/Edit.ahk.
-- Live while Resolve is in front and the layout is "Edit" (the default).
local config = require("config")
local util   = require("lib.util")
local keys   = require("lib.keys")
local mouse  = require("lib.mouse")

local E = {}
local send, sleep = keys.send, util.sleep

-- Adding generators / effects / titles through Resolve's search.
-- Generators/titles: Tab, search, Enter, Tab.  Effects: click the clip under
-- the cursor first, then search, Enter.
function E.spawn(name, isEffect)
    if not isEffect then
        send("{Tab}")
    else
        mouse.click()
    end
    sleep(0.1)
    send(config.searchKey)
    sleep(config.timing.afterSearchOpen)
    keys.type(name)
    sleep(config.timing.beforeEnter)   -- Mac Resolve needs a moment to filter the results
    send("{Enter}")
    if isEffect then return end
    sleep(0.1)
    send("{Tab}")
end

function E.doEdit(shortcut)
    mouse.click()
    send("{Tab}")
    send(shortcut)
end

function E.deselectAll()
    send("^+d")
    sleep(0.1)
end

-- Run a macro body asynchronously so its sleeps don't freeze Hammerspoon.
local function macro(fn)
    return function() util.async(fn) end
end

local function spawn(name, isEffect)
    return macro(function() E.spawn(name, isEffect) end)
end

function E.bind(g)
    local s = config.spawn

    -- =======================================
    -- Cutting
    -- =======================================
    g:bind("F3", macro(function() E.doEdit("b") end))   -- Cut
    g:bind("F1", macro(function() E.doEdit("q") end))   -- Ripple Start
    g:bind("F2", macro(function() E.doEdit("w") end))   -- Ripple End

    -- Purge Fusion memory cache
    g:bind("!p", macro(function()
        send("h")
        sleep(1)
        send("!p")
        sleep(0.2)
        send("+4")
    end))

    -- =======================================
    -- Titles / Generators / Effects
    -- =======================================
    g:bind("F4", spawn(s.gregsText))                    -- Greg's Text+
    g:bind("F5", spawn(s.simpleFill, true))             -- John Simple Fill
    g:bind("F6", spawn(s.simpleShadow, true))           -- John Simple Shadow
    g:bind("F7", spawn(s.gradualAnimation))             -- Gradual Animation Layer

    g:bind("F8", macro(function()                       -- Basic Mask
        E.spawn(s.basicMask, true)
        send("^+!9")
    end))

    g:bind("+F1", spawn(s.fadeRight, true))             -- Fade Right Animation
    g:bind("+F2", spawn(s.fadeLeft, true))              -- Fade Left Animation
    -- Fade Down Animation. On release the AHK script also let go of the left
    -- button and sent "v" (the old `+F3 Up::` trim handler) — kept as-is.
    g:bind("+F3", spawn(s.fadeDown, true), function()
        mouse.leftUp()
        send("v")
    end)
    g:bind("+F4", spawn(s.fadeUp, true))                -- Fade Up Animation
    g:bind("+F5", spawn(s.pushUp, true))                -- Push Up Animation (Multi Transform)
    g:bind("+F6", spawn(s.wippMarkerClean, true))       -- WippMarker Clean
    g:bind("+F7", spawn(s.wippHighlightCenter, true))   -- WippHighlight Center
    g:bind("+F8", spawn(s.wippUnderlay))                -- WippUnderlay

    -- Render in place
    g:bind("!+3", function()
        send("^+!1")
        send("!+3")
    end)
end

return E
