-- Plugin mode system (Ctrl+Alt+Q) — port of plugins/Plugins.ahk.
--
-- WippZoom and GregTextPlus share hotkeys, so only one is active at a time.
-- To add a plugin: create plugins/<name>.lua exporting `bind(group)`, add the
-- name to config.pluginModes and register it in `setup`.
local config   = require("config")
local apps     = require("lib.apps")
local bindings = require("lib.bindings")
local holdmenu = require("lib.holdmenu")

local P = {}
P.mode = config.defaultPluginMode

function P.is(mode)
    return P.mode == mode
end

function P.set(name)
    P.mode = name
    bindings.refresh()
    hs.alert.closeAll()
    hs.alert.show("Plugin: " .. name, 0.8)
end

function P.setup()
    local global = bindings.group("Plugin menu", function() return true end)
    global:bind("^!q",
        function() holdmenu.open(config.pluginModes, "q", P.set, P.mode) end,
        holdmenu.release)

    local function resolveIn(mode)
        return function() return apps.resolveActive() and P.is(mode) end
    end

    require("plugins.gregtextplus").bind(bindings.group("GregTextPlus", resolveIn("GregTextPlus")))
    require("plugins.wippzoom").bind(bindings.group("WippZoom", resolveIn("WippZoom")))
end

return P
