-- WippZoom plugin — port of plugins/WippZoom.ahk.
-- Button positions: config.wippZoom. Each macro puts the cursor back after.
--
--   Ctrl+Alt+A  refresh match       Ctrl+Alt+W  refresh size, increment up
--   Ctrl+Alt+D  swap                Ctrl+Alt+S  refresh size, increment down
local config = require("config")
local keys   = require("lib.keys")
local mouse  = require("lib.mouse")

local W = {}

local function clickAndReturn(pt)
    local orig = mouse.pos()
    mouse.clickAt(pt)
    mouse.warp(orig)
end

local function refreshSize(arrow)
    local c = config.wippZoom
    local orig = mouse.pos()
    mouse.clickAt(c.refreshSize)
    keys.send("{Right}")
    keys.send(arrow)
    mouse.clickAt({ x = c.refreshSize.x + c.refreshSizeApplyOffsetX, y = c.refreshSize.y })
    mouse.warp(orig)
end

function W.bind(g)
    local c = config.wippZoom
    g:bind("^!a", function() clickAndReturn(c.matchRefresh) end)
    g:bind("^!d", function() clickAndReturn(c.swap) end)
    g:bind("^!w", function() refreshSize("{Up}") end)
    g:bind("^!s", function() refreshSize("{Down}") end)
end

return W
