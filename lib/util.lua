-- Small shared helpers: logging, colors, file IO, async sleeps.
local U = {}

U.log = hs.logger.new("ResolveHS", "info")

function U.color(hex, alpha)
    return { hex = hex, alpha = alpha or 1 }
end

function U.contains(list, value)
    for _, v in ipairs(list) do
        if v == value then return true end
    end
    return false
end

function U.readFile(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local data = f:read("*a")
    f:close()
    return data
end

function U.writeFile(path, data)
    local f, err = io.open(path, "wb")
    if not f then return false, err end
    f:write(data)
    f:close()
    return true
end

function U.fileExists(path)
    return hs.fs.attributes(path, "mode") == "file"
end

function U.isDir(path)
    return hs.fs.attributes(path, "mode") == "directory"
end

-- Number of UTF-8 characters (StrLen equivalent).
function U.charCount(s)
    local _, n = s:gsub("[^\128-\191]", "")
    return n
end

-- ---------------------------------------------------------------------------
-- Async: lets macros `sleep` like AHK without freezing Hammerspoon, so other
-- hotkeys (e.g. the Caption F2 "stop") keep working while a macro runs.
--
--   util.async(function() ...; util.sleep(0.1); ... end)
--
-- Outside a coroutine, sleep falls back to a short blocking wait.
-- ---------------------------------------------------------------------------
local pending = {}   -- keeps timers alive until they fire

local function resume(co, ...)
    local ok, err = coroutine.resume(co, ...)
    if not ok then
        U.log.e("macro error: " .. tostring(err))
        hs.alert.show("Resolve macro error:\n" .. tostring(err), 3)
    end
end

function U.async(fn, ...)
    local co = coroutine.create(fn)
    resume(co, ...)
    return co
end

function U.sleep(seconds)
    local co, isMain = coroutine.running()
    if co == nil or isMain then
        hs.timer.usleep(math.floor(seconds * 1000000))
        return
    end
    local t
    t = hs.timer.doAfter(seconds, function()
        pending[t] = nil
        resume(co)
    end)
    pending[t] = true
    coroutine.yield()
end

return U
