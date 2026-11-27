-- ===========================================================================
-- Resolve Hammerspoon — DaVinci Resolve macros for macOS.
-- Port of the Resolve AutoHotkey project (ResolveMacros.ahk).
--
-- Load it from ~/.hammerspoon/init.lua with:
--     dofile(os.getenv("HOME") .. "/Projects_Git/resolve-hammerspoon/init.lua")
-- ===========================================================================

local root = debug.getinfo(1, "S").source:sub(2):match("^(.*/)") or (hs.configdir .. "/")
RESOLVE_HS_ROOT = root
package.path = root .. "?.lua;" .. root .. "?/init.lua;" .. package.path

hs.hotkey.setLogLevel("warning")   -- enabling/disabling per app is chatty otherwise

local config   = require("config")
local util     = require("lib.util")
local apps     = require("lib.apps")
local bindings = require("lib.bindings")
local macros   = require("macros.macros")
local plugins  = require("plugins.plugins")

-- General utilities — active in every app, like the un-#HotIf'd AHK hotkeys.
local everywhere = bindings.group("Utilities", function() return true end)
require("utilities.general").bind(everywhere)
require("utilities.clipboard").bind(everywhere)
require("utilities.open_project_folder").bind(everywhere)
-- Keyboard modifiers held while the mouse sends arrow keys (Option+mouse-Up).
require("utilities.modifier_merge").start()
-- (Explorer Focus / Win+Ctrl+Alt+Space intentionally not ported.)

-- Macro layout switcher (Ctrl+Shift+Q) and plugin mode system (Ctrl+Alt+Q).
macros.setup()
plugins.setup()

apps.watcher:start()
bindings.refresh()

if config.autoReload then
    RESOLVE_HS_RELOADER = hs.pathwatcher.new(root, function(files)
        for _, f in ipairs(files) do
            if f:match("%.lua$") and not f:find("/slots/", 1, true) then
                hs.reload()
                return
            end
        end
    end):start()
end

-- Global handle: keeps everything alive and is handy from the console / `hs`.
RESOLVE_HS = {
    config   = config,
    macros   = macros,
    plugins  = plugins,
    bindings = bindings,
    status   = function()
        return string.format("layout=%s plugin=%s front=%s active=[%s]",
            macros.mode, plugins.mode,
            tostring(hs.application.frontmostApplication():name()),
            table.concat(bindings.activeGroups(), ", "))
    end,
}

util.log.i("loaded from " .. root)
hs.alert.show("Resolve macros loaded", 1)
