-- Caption layout — port of macros/Caption.ahk.
--
-- Copies each subtitle's in point to the previous subtitle's out point,
-- closing the gaps. The AHK file was never included in the layout menu; add
-- "Caption" to config.macroModes to use it. Field positions: config.caption.
--
--   F1  start the loop     F2  stop it     F3  manual copy for the clicked row
local config = require("config")
local util   = require("lib.util")
local keys   = require("lib.keys")
local mouse  = require("lib.mouse")
local apps   = require("lib.apps")

local C = {}
local send, sleep = keys.send, util.sleep
C.running = false

function C.copyInToOut()
    local p = config.caption
    mouse.clickAt(p.inPoint)
    send("^a")
    sleep(0.1)
    send("^c")

    mouse.clickAt(p.previous)
    sleep(0.5)

    mouse.clickAt(p.outPoint)
    send("^a")
    send("^v")
    send("{Enter}")
end

function C.bind(g)
    -- Start operation (one loop at a time, like #MaxThreadsPerHotkey 1)
    g:bind("F1", function()
        if C.running then return end
        C.running = true
        util.async(function()
            -- Also stops if Resolve loses focus, so clicks never land elsewhere.
            while C.running and apps.resolveActive() do
                C.copyInToOut()
                sleep(0)   -- yield so F2 can get in
            end
            C.running = false
        end)
    end)

    -- Stop operation
    g:bind("F2", function() C.running = false end)

    -- Manual copy
    g:bind("F3", function()
        util.async(function()
            local orig = mouse.pos()
            mouse.click()
            C.copyInToOut()
            mouse.warp(orig)
        end)
    end)
end

return C
