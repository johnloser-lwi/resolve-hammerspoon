-- Clipboard utilities — port of utilities/Clipboard.ahk. Active everywhere.
--
--   Ctrl+Shift+Alt+V  pop up a menu at the cursor, convert the clipboard text
--                     and paste it.
--   Ctrl+Alt+V        open the clipboard history in Spotlight (Mac only).
local config = require("config")
local keys   = require("lib.keys")
local util   = require("lib.util")

local C = {}

-- ---------------------------------------------------------------------------
-- Unicode-aware upper/lower. Lua's string.upper only knows ASCII, so anything
-- else (é, ß, ...) goes through NSString via hs.styledtext, like AHK's
-- StrUpper/StrLower.
-- ---------------------------------------------------------------------------
local function isAscii(s) return not s:find("[\128-\255]") end

local function nsCase(s, method)
    local ok, res = pcall(function()
        local st = hs.styledtext.new(s)
        return st[method](st):getString()
    end)
    if ok and type(res) == "string" then return res end
    return nil
end

function C.upper(s)
    if isAscii(s) then return s:upper() end
    return nsCase(s, "upper") or s:upper()
end

function C.lower(s)
    if isAscii(s) then return s:lower() end
    return nsCase(s, "lower") or s:lower()
end

local UTF8_CHAR = "[%z\1-\127\194-\244][\128-\191]*"

-- Uppercase the first character, leave the rest untouched.
local function upperFirst(word)
    local first = word:match("^" .. UTF8_CHAR)
    if not first then return word end
    return C.upper(first) .. word:sub(#first + 1)
end

-- StrSplit(text, " "): keeps empty pieces so runs of spaces survive.
local function splitSpaces(text)
    local parts, start = {}, 1
    while true do
        local i = text:find(" ", start, true)
        if not i then
            parts[#parts + 1] = text:sub(start)
            return parts
        end
        parts[#parts + 1] = text:sub(start, i - 1)
        start = i + 1
    end
end

-- Articles, coordinating conjunctions, and short prepositions stay lowercase.
C.minorWords = {}
for w in ("a an the and but or nor for so yet at by in of on to up as via"):gmatch("%S+") do
    C.minorWords[w] = true
end

function C.titleCase(text)
    local words = splitSpaces(C.lower(text))
    local total = #words
    local out = {}
    for i, word in ipairs(words) do
        if word == "" then
            out[#out + 1] = ""
        else
            -- First and last word always capitalized.
            local capitalize = (i == 1 or i == total or not C.minorWords[word])
            out[#out + 1] = capitalize and upperFirst(word) or word
        end
    end
    return table.concat(out, " ")
end

function C.sentenceCase(text)
    text = C.lower(text)
    local out, capitalizeNext = {}, true
    for ch in text:gmatch(UTF8_CHAR) do
        if capitalizeNext and ch:match("^[a-z]$") then
            ch = ch:upper()
            capitalizeNext = false
        end
        if ch:match("^[%.!%?]$") then capitalizeNext = true end
        out[#out + 1] = ch
    end
    return table.concat(out)
end

function C.capEachWord(text)
    local words = splitSpaces(text)
    for i, word in ipairs(words) do
        if word ~= "" then words[i] = upperFirst(word) end
    end
    return table.concat(words, " ")
end

C.options = {
    { "ALL CAPS",             C.upper },
    { "lowercase",            C.lower },
    { "Title Case",           C.titleCase },
    { "Capitalize Each Word", C.capEachWord },
    { "Sentence case",        C.sentenceCase },
}

local function apply(fn)
    local text = hs.pasteboard.getContents()
    if not text then
        hs.alert.show("Clipboard has no text", 1)
        return
    end
    hs.pasteboard.setContents(fn(text))
    -- Let the popup menu finish closing so the paste reaches the original app.
    hs.timer.doAfter(0.05, function() keys.send("^v") end)
end

local menu = nil
function C.showMenu()
    if menu then menu:delete() end
    menu = hs.menubar.new(false)
    local items = {}
    for _, opt in ipairs(C.options) do
        items[#items + 1] = { title = opt[1], fn = function() apply(opt[2]) end }
    end
    menu:setMenu(items)
    menu:popupMenu(hs.mouse.absolutePosition())
end

-- Clipboard history: open Spotlight (Cmd+Space), then its Clipboard view
-- (Cmd+4). Sent as exact Mac keys, not through the ^ -> Cmd translation.
function C.showHistory()
    util.async(function()
        keys.send({ { "cmd" }, "space" })
        util.sleep(config.timing.spotlightOpen)
        keys.send({ { "cmd" }, "4" })
    end)
end

function C.bind(g)
    g:bind("^+!v", C.showMenu)
    g:bind("^!v", C.showHistory)   -- Ctrl+Option+V
end

return C
