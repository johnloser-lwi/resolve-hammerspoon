-- Numbered button menu centered on screen (the tkinter window from
-- open_project_folder.py). Press a number key or click a button; Esc closes.

local B = {}
local open = nil

local W, PAD, ROW, GAP = 340, 12, 28, 4
local FONT = ".AppleSystemUIFont"

local function close()
    if not open then return end
    open.modal:exit()
    open.canvas:delete()
    open = nil
end

-- title: bold heading; subtitle: grey line; items: list of labels;
-- onPick(index) runs after the menu closes.
function B.show(title, subtitle, items, onPick)
    close()

    local headerH = 22 + 18 + 8
    local h = PAD * 2 + headerH + #items * (ROW + GAP) - GAP
    local screen = hs.screen.mainScreen():frame()
    local frame = { x = screen.x + math.floor((screen.w - W) / 2),
                    y = screen.y + math.floor((screen.h - h) / 2), w = W, h = h }

    local c = hs.canvas.new(frame)
    c:level(hs.canvas.windowLevels.modalPanel)
    c:behavior({ "canJoinAllSpaces" })
    c[1] = { type = "rectangle", action = "fill", fillColor = { hex = "#262626", alpha = 0.98 },
             strokeColor = { hex = "#4A4A4A" }, roundedRectRadii = { xRadius = 8, yRadius = 8 } }
    c[2] = { type = "text", text = title, textColor = { white = 1 }, textFont = "Helvetica-Bold",
             textSize = 14, textLineBreak = "truncateTail",
             frame = { x = PAD, y = PAD, w = W - PAD * 2, h = 20 } }
    c[3] = { type = "text", text = subtitle, textColor = { white = 0.6 }, textFont = FONT,
             textSize = 11, textLineBreak = "truncateMiddle",
             frame = { x = PAD, y = PAD + 22, w = W - PAD * 2, h = 16 } }

    local top = PAD + headerH
    for i, label in ipairs(items) do
        local y = top + (i - 1) * (ROW + GAP)
        c[#c + 1] = { id = "btn" .. i, type = "rectangle", action = "fill",
                      fillColor = { hex = "#3A3A3A" }, roundedRectRadii = { xRadius = 5, yRadius = 5 },
                      frame = { x = PAD, y = y, w = W - PAD * 2, h = ROW },
                      trackMouseDown = true, trackMouseUp = true, trackMouseEnterExit = true }
        c[#c + 1] = { type = "text", text = i .. ". " .. label, textColor = { white = 1 },
                      textFont = FONT, textSize = 13,
                      frame = { x = PAD + 10, y = y + 5, w = W - PAD * 2 - 20, h = ROW - 6 } }
    end

    local function pick(i)
        close()
        hs.timer.doAfter(0, function() onPick(i) end)
    end

    c:mouseCallback(function(_, msg, id)
        local i = tonumber(tostring(id):match("^btn(%d+)$"))
        if not i then return end
        if msg == "mouseEnter" then c[id].fillColor = { hex = "#0A64C8" }
        elseif msg == "mouseExit" then c[id].fillColor = { hex = "#3A3A3A" }
        elseif msg == "mouseUp" then pick(i) end
    end)

    local modal = hs.hotkey.modal.new()
    for i = 1, math.min(#items, 9) do
        modal:bind({}, tostring(i), function() pick(i) end)
    end
    modal:bind({}, "escape", close)
    modal:enter()

    c:show()
    open = { canvas = c, modal = modal }
end

function B.close() close() end

return B
