-- Swiftpoint mouse profile switching — PLACEHOLDER.
--
-- The AHK version (SendCommand in macros/Macros.ahk) wrote
-- "Profile SET <name>" to the Windows named pipe
-- \\.\pipe\swiftpoint.x1.v2.command whenever the layout changed or Resolve
-- gained focus. The macOS side of the Swiftpoint X1 API still needs research,
-- so for now this only records which profile *would* be selected. Every call
-- site is already wired up; implementing `set` here is all that's left.
local config = require("config")
local util   = require("lib.util")

local P = {}
P.current = nil

function P.set(profileName)
    P.current = profileName
    if not config.mouseProfile.enabled then
        util.log.d("mouse profile (not implemented): " .. tostring(profileName))
        return
    end
    -- TODO: send "Profile SET " .. profileName to the Swiftpoint X1 API on macOS.
    util.log.i("mouse profile requested: " .. tostring(profileName))
end

return P
