-- Hold-to-select menu (ShowHoldMenu from macros/Macros.ahk).
--
-- Opens centered on the cursor and stays up while the hotkey is held. Move the
-- cursor over an item to highlight it, then release the key to pick it — no
-- clicking. Releasing off the menu cancels.
--
-- Usage: bind the hotkey with H.open as `pressed` and H.release as `released`.
-- A keyUp watcher on the same key is a second, independent way to close, so
-- the menu can never get stuck open.
local config = require("config")
local util   = require("lib.util")

local H = {}
local state = nil

local function close(fire)
    local s = state
    if not s then return end
    state = nil
    if s.timer then s.timer:stop() end
    if s.tap then s.tap:stop() end
    if s.canvas then s.canvas:delete() end
    if fire and s.hot > 0 then
        local pick = s.items[s.hot]
        -- Run after the UI is gone, outside the event callback.
        hs.timer.doAfter(0, function() s.callback(pick) end)
    end
end

-- items: list of names; key: hs key name being held ("q"); checked: current item.
function H.open(items, key, callback, checked)
    if state then return end
    local cfg = config.holdMenu
    local w, rowH = cfg.width, cfg.rowHeight
    local h = #items * rowH
    local m = hs.mouse.absolutePosition()
    local frame = { x = m.x - math.floor(w / 2), y = m.y - math.floor(h / 2), w = w, h = h }

    local c = hs.canvas.new(frame)
    c:level(hs.canvas.windowLevels.popUpMenu)
    c:behavior({ "canJoinAllSpaces", "transient" })
    c[1] = { type = "rectangle", action = "fill", fillColor = util.color(cfg.background),
             roundedRectRadii = { xRadius = 4, yRadius = 4 } }
    local textOffset = math.floor((rowH - cfg.fontSize * 1.25) / 2)
    for i, name in ipairs(items) do
        local label = (name == checked and "• " or "") .. name
        c[#c + 1] = { id = "row" .. i, type = "rectangle", action = "fill",
                      fillColor = util.color(cfg.background, 0),
                      frame = { x = 0, y = (i - 1) * rowH, w = w, h = rowH } }
        c[#c + 1] = { type = "text", text = label, textColor = util.color(cfg.textColor),
                      textFont = cfg.font, textSize = cfg.fontSize, textAlignment = "center",
                      frame = { x = 0, y = (i - 1) * rowH + textOffset, w = w, h = rowH } }
    end
    c:show()

    state = { items = items, callback = callback, canvas = c, hot = 0 }

    -- Hover tracking (the AHK version polled every 15 ms too).
    state.timer = hs.timer.doEvery(0.015, function()
        if not state then return end
        local p = hs.mouse.absolutePosition()
        local idx = 0
        if p.x >= frame.x and p.x < frame.x + w and p.y >= frame.y and p.y < frame.y + h then
            idx = math.floor((p.y - frame.y) / rowH) + 1
        end
        if idx ~= state.hot then   -- repaint only on change
            if state.hot > 0 then c["row" .. state.hot].fillColor = util.color(cfg.background, 0) end
            if idx > 0 then c["row" .. idx].fillColor = util.color(cfg.highlight) end
            state.hot = idx
        end
    end)

    local keyCode = hs.keycodes.map[key]
    state.tap = hs.eventtap.new({ hs.eventtap.event.types.keyUp }, function(e)
        if e:getKeyCode() == keyCode then close(true) end
        return false
    end)
    state.tap:start()
end

-- Hotkey released -> fire the highlighted item (if any) and close.
function H.release()
    close(true)
end

function H.isOpen()
    return state ~= nil
end

return H
