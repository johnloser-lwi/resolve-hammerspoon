-- Context-sensitive hotkey groups — the Hammerspoon version of AHK's #HotIf.
--
--   local g = bindings.group("Edit", function() return apps.resolveActive() and macros.is("Edit") end)
--   g:bind("F1", fn)
--
-- Hotkeys in a group are only registered while its condition is true, so F1
-- etc. reach other apps normally. `bindings.refresh()` re-evaluates every
-- group; it runs on app switches and whenever a layout/plugin changes.
local keys = require("lib.keys")
local apps = require("lib.apps")

local B = {}
local groups = {}

local Group = {}
Group.__index = Group

-- pressed/released are plain functions; wrap long macros in util.async.
function Group:bind(spec, pressed, released)
    local b = keys.bind(spec, pressed, released)
    if b then table.insert(self.bindings, b) end
    return b
end

function B.group(name, condition)
    local g = setmetatable({ name = name, condition = condition, bindings = {} }, Group)
    table.insert(groups, g)
    return g
end

function B.refresh()
    -- Disable first, then enable, so a combo moving between groups (e.g. F1 in
    -- Edit vs Caption, Ctrl+Alt+A in GregTextPlus vs WippZoom) never collides.
    local want = {}
    for i, g in ipairs(groups) do
        local ok, res = pcall(g.condition)
        want[i] = ok and res and true or false
    end
    for i, g in ipairs(groups) do
        if not want[i] then
            for _, b in ipairs(g.bindings) do b:setWanted(false) end
        end
    end
    for i, g in ipairs(groups) do
        if want[i] then
            for _, b in ipairs(g.bindings) do b:setWanted(true) end
        end
    end
end

function B.activeGroups()
    local names = {}
    for _, g in ipairs(groups) do
        local ok, res = pcall(g.condition)
        if ok and res then names[#names + 1] = g.name end
    end
    return names
end

apps.onChange(function() B.refresh() end)

return B
