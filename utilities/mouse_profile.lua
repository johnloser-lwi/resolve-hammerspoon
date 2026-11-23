-- Swiftpoint X1 mouse profile switching — port of SendCommand in
-- macros/Macros.ahk.
--
-- Windows used the named pipe \\.\pipe\swiftpoint.x1.v2.command; on macOS the
-- X1 Control Panel serves the same API on a Unix socket
-- (/tmp/swiftpoint.x1.v2.command). Requires "Enable X1 API" in the X1
-- Control Panel options (then restart the app). Docs:
-- https://support.swiftpoint.com/portal/en/kb/articles/x1-api
--
-- Called when you pick a layout (Ctrl+Shift+Q) and whenever Resolve comes to
-- the front, with the layout's `mouseProfile` from config.lua.
local config  = require("config")
local util    = require("lib.util")
local tooltip = require("lib.tooltip")

local P = {}
P.current = nil

local live = {}   -- keeps sockets alive until they finish

-- Send one X1 API command; cb(response) gets the trimmed reply ("OK",
-- "ERROR: ...", or command output). cb(nil, err) if the socket isn't there.
function P.sendCommand(command, cb)
    local path = config.mouseProfile.socketPath
    if hs.fs.attributes(path, "mode") ~= "socket" then
        if cb then cb(nil, "socket not found: " .. path) end
        return
    end

    local sock
    local finished = false
    local function done(resp, err)
        if finished then return end
        finished = true
        live[sock] = nil
        if sock:connected() then sock:disconnect() end
        if cb then cb(resp, err) end
    end

    sock = hs.socket.new(function(data)
        local resp = (data or ""):gsub("^%s+", ""):gsub("%s+$", "")
        done(resp)
    end)
    live[sock] = true
    sock:setTimeout(config.mouseProfile.timeout)
    sock:connect(path, function()
        sock:write(command .. "\n", function()
            sock:read("\n")
        end)
    end)
    -- Safety net if the X1 app never answers.
    hs.timer.doAfter(config.mouseProfile.timeout + 0.5, function()
        done(nil, "no response")
    end)
end

function P.set(profileName)
    P.current = profileName
    if not config.mouseProfile.enabled then return end

    P.sendCommand("Profile Set " .. profileName, function(resp, err)
        if not resp then
            util.log.w("X1 API: " .. tostring(err))
            tooltip.show("Could not connect to the X1 API.", 3)
        elseif resp ~= "OK" then
            util.log.w("X1 API reply to Profile Set " .. profileName .. ": " .. resp)
            hs.alert.show("X1 API: " .. resp, 3)
        else
            util.log.d("X1 profile -> " .. profileName)
        end
    end)
end

return P
