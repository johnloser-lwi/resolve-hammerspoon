-- Which app is in front, and notifications when that changes.
local config = require("config")
local util   = require("lib.util")

local A = {}

local function matches(app, spec)
    if not app then return false end
    local id = app:bundleID()
    if id and util.contains(spec.bundleIDs, id) then return true end
    return util.contains(spec.names, app:name())
end

function A.isResolve(app)      return matches(app, config.apps.resolve) end
function A.isFusionStudio(app) return matches(app, config.apps.fusionStudio) end

function A.resolveActive()      return A.isResolve(hs.application.frontmostApplication()) end
function A.fusionStudioActive() return A.isFusionStudio(hs.application.frontmostApplication()) end

-- Focused window of the frontmost app (used for window-relative coordinates).
function A.focusedWindow()
    return hs.window.focusedWindow()
end

local listeners = {}

-- fn(app, isActivation) runs whenever another app comes to the front.
function A.onChange(fn)
    table.insert(listeners, fn)
end

A.watcher = hs.application.watcher.new(function(_, event, app)
    if event == hs.application.watcher.activated
        or event == hs.application.watcher.deactivated
        or event == hs.application.watcher.terminated then
        for _, fn in ipairs(listeners) do
            fn(app, event == hs.application.watcher.activated)
        end
    end
end)

return A
