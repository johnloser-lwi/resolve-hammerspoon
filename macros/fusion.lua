-- Fusion layout — port of macros/Fusion.ahk.
--
-- Quick-apply slots (StarCraft-style control groups for Fusion nodes):
--   Ctrl+Shift+1..9, Ctrl+Shift+0   copy the selected nodes, save to slot 1..10
--   Cmd+1..9, Cmd+0                 paste slot 1..10 into the node editor
--   (the 0 key is slot 10)
--
-- Each slot is a plain-text file in slots/ next to this project, with separate
-- sets for Resolve (resolve_slotN) and Fusion Studio (studio_slotN). Fusion
-- copies nodes as Lua text that can be hundreds of KB; a file has no size
-- limit, survives reloads and reboots, and can be opened to see what it holds.
local util    = require("lib.util")
local keys    = require("lib.keys")
local apps    = require("lib.apps")
local tooltip = require("lib.tooltip")

local F = {}

F.slotDir = (RESOLVE_HS_ROOT or (hs.configdir .. "/")) .. "slots"

-- Resolve's Fusion page and standalone Fusion Studio get separate slot sets,
-- since node copies aren't always compatible between the two. Which set is
-- used depends on the app focused at the moment you save or paste.
local function slotPath(n)
    local app = apps.fusionStudioActive() and "studio" or "resolve"
    return F.slotDir .. "/" .. app .. "_slot" .. n .. ".txt"
end

function F.saveSlot(n)
    if not util.isDir(F.slotDir) then hs.fs.mkdir(F.slotDir) end

    local path = slotPath(n)
    local before = hs.pasteboard.changeCount()
    local prev = hs.pasteboard.readAllData()
    keys.send("^c")

    -- ClipWait 1: poll until the clipboard changes, up to one second.
    local waited = 0
    local timer
    timer = hs.timer.doEvery(0.02, function()
        waited = waited + 0.02
        local text = hs.pasteboard.changeCount() ~= before and hs.pasteboard.getContents() or nil
        if text and text ~= "" then
            timer:stop()
            local ok, err = util.writeFile(path, text)
            if ok then
                tooltip.show("Saved slot " .. n .. " (" .. util.charCount(text) .. " chars)")
            else
                tooltip.show("Slot " .. n .. ": could not save — " .. tostring(err), 3)
            end
        elseif waited >= 1 then
            timer:stop()
            -- Nothing was copied (no selection) — put the old clipboard back.
            if hs.pasteboard.changeCount() ~= before and prev then hs.pasteboard.writeAllData(prev) end
            tooltip.show("Slot " .. n .. ": nothing selected")
        end
    end)
end

function F.pasteSlot(n)
    local path = slotPath(n)
    local text = util.readFile(path)
    if not text then
        tooltip.show("Slot " .. n .. " is empty — Ctrl+Shift+" .. (n % 10) .. " to save")
        return
    end
    -- Slots saved by the Windows AHK script start with a UTF-8 byte-order mark
    -- (FileAppend "UTF-8"); drop it so Fusion only sees the node text.
    text = text:gsub("^\239\187\191", "")
    hs.pasteboard.setContents(text)
    keys.send("^v")
    tooltip.show("Pasted slot " .. n)
end

function F.bind(g)
    -- Number row: keys 1..9 are slots 1..9, key 0 is slot 10.
    for n = 1, 10 do
        local digit = tostring(n % 10)
        g:bind("^+" .. digit, function() F.saveSlot(n) end)
        -- Paste is on Cmd (#) instead of Ctrl: another app on this Mac holds
        -- Ctrl+1 and Ctrl+2 system-wide, so they can't be registered.
        g:bind("#" .. digit, function() F.pasteSlot(n) end)
    end
end

return F
