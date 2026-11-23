-- Open Project Folder — port of utilities/OpenProjectFolder.ahk +
-- open_project_folder.py. Active everywhere.
--
--   Ctrl+Shift+Alt+O  read the current Resolve project's "Project media
--                     location", take its parent as the project root and
--                     pop up a menu of subfolders to open in Finder.
--
-- Talks to Resolve through the `fuscript` interpreter bundled with Resolve,
-- so no Python setup is needed. Requires Preferences > System > General >
-- "External scripting using" = Local.
local config     = require("config")
local util       = require("lib.util")
local buttonmenu = require("lib.buttonmenu")

local O = {}

local QUERY = [[
local r = Resolve()
if not r then print("RHS_ERR=noresolve") return end
local p = r:GetProjectManager():GetCurrentProject()
if not p then print("RHS_ERR=noproject") return end
print("RHS_NAME=" .. tostring(p:GetName()))
print("RHS_MEDIA=" .. tostring(p:GetSetting("projectMediaLocation") or ""))
]]

local function fail(msg)
    hs.dialog.blockAlert("Open Project Folder", msg, "OK", nil, "critical")
end

local function normalize(path)
    path = path:gsub("\\", "/")
    path = path:gsub("/+$", "")
    return path
end

-- Apply config.openProjectFolder.pathMappings (Windows paths -> Mac paths).
function O.mapPath(path)
    path = normalize(path)
    for _, m in ipairs(config.openProjectFolder.pathMappings) do
        local from = normalize(m.from)
        if path:sub(1, #from):lower() == from:lower() then
            return normalize(m.to) .. path:sub(#from + 1)
        end
    end
    return path
end

-- Parent of the "Project media location" (os.path.dirname(normpath(...))).
function O.projectRoot(mediaLocation)
    local p = O.mapPath(mediaLocation)
    return p:match("^(.*)/[^/]*$") or p
end

local function showMenu(root, name)
    local folders = config.openProjectFolder.folders
    local labels = {}
    for i, f in ipairs(folders) do labels[i] = f[1] end
    buttonmenu.show(name, root, labels, function(i)
        local rel = folders[i][2]
        local target = rel ~= "" and (root .. "/" .. rel) or root
        if util.isDir(target) then
            hs.task.new("/usr/bin/open", nil, { target }):start()
        else
            fail("Folder not found:\n" .. target)
        end
    end)
end

local running = nil

function O.run()
    if running then return end
    local cfg = config.openProjectFolder
    if not util.fileExists(cfg.fuscript) then
        fail("Could not find Resolve's fuscript at:\n" .. cfg.fuscript)
        return
    end

    local timeout, timedOut = nil, false
    local task
    task = hs.task.new(cfg.fuscript, function(_, stdout)
        if timeout then timeout:stop() end
        if timedOut then return end
        running = nil
        stdout = stdout or ""
        local err = stdout:match("RHS_ERR=(%w+)")
        local name = stdout:match("RHS_NAME=([^\r\n]*)")
        local media = stdout:match("RHS_MEDIA=([^\r\n]*)")
        if err == "noproject" then
            fail("No project is currently open in Resolve.")
        elseif err or not name then
            fail("Could not connect to DaVinci Resolve.\nIs it running with external scripting set to Local?")
        elseif not media or media == "" or media == "nil" then
            fail("The 'Project media location' working folder is not set for this project.\n"
                .. "Set it in Project Settings > General Options > Working Folders.")
        else
            showMenu(O.projectRoot(media), name)
        end
    end, { "-l", "lua", "-x", QUERY })

    running = task
    task:start()
    timeout = hs.timer.doAfter(cfg.timeout, function()
        if running == task then
            timedOut = true
            task:terminate()
            running = nil
            fail("Timed out waiting for DaVinci Resolve to answer.")
        end
    end)
end

function O.bind(g)
    g:bind("^+!o", O.run)
end

return O
