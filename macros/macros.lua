-- Macro layout switcher (Ctrl+Shift+Q) — port of macros/Macros.ahk.
--
-- Each layout is a Resolve page. Only the active layout's hotkeys are live,
-- and only while Resolve is the frontmost app. Fusion hotkeys are also always
-- live in standalone Fusion Studio, regardless of layout.
--
-- To add a layout: create macros/<name>.lua exporting `bind(group)`, add the
-- name to config.macroModes (+ config.layouts), and register it in `setup`.
local config       = require("config")
local apps         = require("lib.apps")
local keys         = require("lib.keys")
local bindings     = require("lib.bindings")
local holdmenu     = require("lib.holdmenu")
local mouseProfile = require("utilities.mouse_profile")

local M = {}
M.mode = config.defaultMacroMode

function M.is(mode)
    return M.mode == mode
end

-- switchPage: also jump Resolve to the layout's page (menu selection only;
-- app activation just re-applies the mouse profile, as in the AHK version).
function M.refreshLayoutAndProfile(switchPage)
    local layout = config.layouts[M.mode]
    if not layout then return end
    -- Only type page shortcuts into Resolve, never into whatever else is in front.
    if switchPage and apps.resolveActive() then
        for _, spec in ipairs(layout.pageKeys or {}) do keys.send(spec) end
    end
    if layout.mouseProfile then mouseProfile.set(layout.mouseProfile) end
end

function M.set(name)
    M.mode = name
    bindings.refresh()
    M.refreshLayoutAndProfile(true)
    hs.alert.closeAll()
    hs.alert.show("Layout: " .. name, 0.8)
end

function M.setup()
    local global = bindings.group("Macro menu", function() return true end)
    global:bind("^+q",
        function() holdmenu.open(config.macroModes, "q", M.set, M.mode) end,
        holdmenu.release)

    local function resolveIn(mode)
        return function() return apps.resolveActive() and M.is(mode) end
    end

    require("macros.edit").bind(bindings.group("Edit", resolveIn("Edit")))
    require("macros.fusion").bind(bindings.group("Fusion", function()
        return (apps.resolveActive() and M.is("Fusion")) or apps.fusionStudioActive()
    end))
    require("macros.color").bind(bindings.group("Color", resolveIn("Color")))
    require("macros.fairlight").bind(bindings.group("Fairlight", resolveIn("Fairlight")))
    require("macros.delivery").bind(bindings.group("Delivery", resolveIn("Delivery")))
    require("macros.caption").bind(bindings.group("Caption", resolveIn("Caption")))

    -- Shell-hook equivalent: Resolve gained focus -> re-apply mouse profile.
    apps.onChange(function(app, activated)
        if activated and apps.isResolve(app) then M.refreshLayoutAndProfile(false) end
    end)
end

return M
