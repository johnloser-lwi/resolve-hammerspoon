-- General utilities — port of utilities/General.ahk. Active everywhere.
--
--   Ctrl+Shift+Alt+P     show mouse coordinates (for calibrating config.lua)
--   Ctrl+Cmd+Alt+Delete  free inactive memory (Mac stand-in for RAMMap -Et)
local config = require("config")
local util   = require("lib.util")

local G = {}

function G.showPointer()
    local p = hs.mouse.absolutePosition()
    local sx, sy = math.floor(p.x), math.floor(p.y)

    local win = hs.window.focusedWindow()
    local wx, wy, title = "-", "-", "(none)"
    if win then
        local f = win:frame()
        wx, wy = math.floor(p.x - f.x), math.floor(p.y - f.y)
        local app = win:application()
        title = (app and app:name() or "?") .. " — " .. (win:title() or "")
    end

    local scr = hs.mouse.getCurrentScreen()
    local lx, ly, scrName = "-", "-", "?"
    if scr then
        local f = scr:fullFrame()
        lx, ly, scrName = math.floor(p.x - f.x), math.floor(p.y - f.y), scr:name() or "?"
    end

    local msg = string.format(
        "Screen   X=%d  Y=%d\nWindow   X=%s  Y=%s\nMonitor  X=%s  Y=%s  (%s)\n\nActive window: %s\ncoordMode in config.lua: %s",
        sx, sy, tostring(wx), tostring(wy), tostring(lx), tostring(ly), scrName, title, config.coordMode)

    local useWindow = config.coordMode == "window" and win
    local copyLabel = useWindow and "Copy Window X, Y" or "Copy Screen X, Y"
    local choice = hs.dialog.blockAlert("Pointer Location", msg, "OK", copyLabel, "informational")
    if choice == copyLabel then
        local x, y = sx, sy
        if useWindow then x, y = wx, wy end
        hs.pasteboard.setContents(string.format("{ x = %d, y = %d }", x, y))
    end
end

function G.purgeMemory()
    local cmd = config.purgeCommand
    local args = {}
    for i = 2, #cmd do args[#args + 1] = cmd[i] end
    local task = hs.task.new(cmd[1], function(code, _, stderr)
        if code == 0 then
            hs.alert.show("Inactive memory purged", 1)
        else
            util.log.w("purge failed: " .. tostring(stderr))
            hs.alert.show("Memory purge needs a sudoers entry — see README (Memory Purge).", 4)
        end
    end, args)
    task:start()
end

function G.bind(g)
    g:bind("^+!p", G.showPointer)
    -- Windows used Ctrl+Win+Alt+Delete; Mac keyboards have no forward-delete
    -- key, so this is the key labeled "delete" (Windows Backspace).
    g:bind("^#!{Backspace}", G.purgeMemory)
end

return G
