-- ===========================================================================
-- Resolve Hammerspoon — settings
--
-- Everything you are likely to tweak lives here: modifier mapping, app
-- detection, layouts, screen coordinates, Resolve item names and timing.
-- Edit, save, and Hammerspoon reloads automatically (see `autoReload`).
-- ===========================================================================

local C = {}

-- ---------------------------------------------------------------------------
-- Modifier mapping
--
-- Hotkeys and keystrokes are written AutoHotkey-style so they read the same as
-- the original project:  ^ = Ctrl   ! = Alt/Option   + = Shift   # = Win
--
-- `trigger` is what YOU press. Ctrl stays Ctrl, so the muscle memory from
-- Windows carries over and nothing collides with Resolve's own Cmd shortcuts.
-- The Windows key (#) becomes Cmd.
--
-- `send` is what gets typed INTO Resolve. Resolve for Mac uses Cmd wherever
-- Resolve for Windows uses Ctrl (Cmd+C, Cmd+V, Cmd+A, ...), so ^ becomes Cmd.
-- If you built your Mac keyboard preset with Ctrl instead, change "cmd" to
-- "ctrl" here.
-- ---------------------------------------------------------------------------
C.modifiers = {
    trigger = { ["^"] = "ctrl", ["!"] = "alt", ["+"] = "shift", ["#"] = "cmd" },
    send    = { ["^"] = "cmd",  ["!"] = "alt", ["+"] = "shift", ["#"] = "ctrl" },
}

-- ---------------------------------------------------------------------------
-- Apps (the equivalent of `WinActive("ahk_exe Resolve.exe")`)
-- ---------------------------------------------------------------------------
C.apps = {
    resolve = {
        bundleIDs = { "com.blackmagic-design.DaVinciResolve", "com.blackmagic-design.DaVinciResolveLite" },
        names     = { "DaVinci Resolve", "Resolve" },
    },
    -- Standalone Fusion Studio (Fusion.exe on Windows)
    fusionStudio = {
        bundleIDs = { "com.blackmagic-design.Fusion", "com.blackmagic-design.FusionStudio" },
        names     = { "Fusion", "Fusion Studio" },
    },
}

-- ---------------------------------------------------------------------------
-- Macro layouts (Ctrl+Shift+Q) and plugins (Ctrl+Alt+Q)
--
-- `pageKeys` are sent to Resolve when you pick the layout from the menu
-- (Shift+4..8 are Resolve's default page shortcuts). `mouseProfile` is the
-- Swiftpoint profile name; mouse support is not wired up yet (see
-- utilities/mouse_profile.lua), so it is only logged for now.
--
-- "Caption" (macros/caption.lua) exists in the original project but was never
-- added to the menu there either. Add "Caption" to `macroModes` to use it.
-- ---------------------------------------------------------------------------
C.macroModes       = { "Edit", "Fusion", "Color", "Fairlight", "Delivery", "None" }
C.defaultMacroMode = "Edit"

C.layouts = {
    Edit      = { pageKeys = { "+4" },      mouseProfile = "DavinciResolve" },
    Fusion    = { pageKeys = { "h", "+5" }, mouseProfile = "Resolve-Fusion" },
    Color     = { pageKeys = { "+6" },      mouseProfile = "Resolve-Color" },
    Fairlight = { pageKeys = { "+7" },      mouseProfile = "Resolve-Fairlight" },
    Delivery  = { pageKeys = { "+8" },      mouseProfile = "Resolve-Delivery" },
    Caption   = { pageKeys = {},            mouseProfile = "DavinciResolve" },
    None      = { pageKeys = {} },
}

C.pluginModes       = { "GregTextPlus", "WippZoom", "None" }
C.defaultPluginMode = "GregTextPlus"

-- ---------------------------------------------------------------------------
-- Hold menu look (the Ctrl+Shift+Q / Ctrl+Alt+Q popup)
-- ---------------------------------------------------------------------------
C.holdMenu = {
    width       = 180,
    rowHeight   = 26,
    background  = "#202020",
    highlight   = "#0A64C8",
    textColor   = "#FFFFFF",
    font        = ".AppleSystemUIFont",
    fontSize    = 13,
}

-- ---------------------------------------------------------------------------
-- Screen coordinates
--
-- "screen": absolute Hammerspoon coordinates (origin = top-left of the main
--           display, y grows downward; other monitors can be negative).
-- "window": relative to the top-left corner of Resolve's focused window, so
--           the points survive moving the window. Pick one and calibrate with
--           Ctrl+Shift+Alt+P, which shows both.
--
-- !! The numbers below are the Windows values copied from the AHK project.
-- !! They will not line up on the Mac until you recalibrate them.
-- ---------------------------------------------------------------------------
C.coordMode = "screen"

C.gregTextPlus = {
    x    = { x = 2344, y = 535 },
    y    = { x = 2474, y = 535 },
    size = { x = 2479, y = 568 },
    -- Strip Ctrl/Alt from the synthetic click + drag. On macOS Ctrl+click can
    -- act as a right-click, which would open a context menu instead of
    -- grabbing the slider.
    stripModifiers = true,
}

C.wippZoom = {
    matchRefresh = { x = 2245, y = 344 },
    swap         = { x = 2385, y = 590 },
    refreshSize  = { x = 2477, y = 428 },
    refreshSizeApplyOffsetX = 30,   -- second click lands this far right of refreshSize
}

C.caption = {
    inPoint  = { x = 1599, y = 240 },
    outPoint = { x = 1720, y = 241 },
    previous = { x = 1777, y = 408 },
}

-- ---------------------------------------------------------------------------
-- Effects / generators / titles spawned by the Edit layout (via Resolve's
-- effect search). Names must match Resolve exactly.
--
-- `searchKey` is the shortcut that opens that search. It is written as an
-- exact Mac combo ({ modifiers, key }), so it is NOT run through the ^ -> Cmd
-- translation above: this really sends Ctrl+Space. (Written as "^{Space}" it
-- would become Cmd+Space, which is Spotlight.) It must match the shortcut
-- for the search in Resolve's Mac keyboard preset.
-- ---------------------------------------------------------------------------
C.searchKey = { { "ctrl" }, "space" }

C.spawn = {
    gregsText            = "GregsText_CLS",
    simpleFill           = "John Simple Fill",
    simpleShadow         = "John Simple Shadow",
    gradualAnimation     = "Gradual Animation Layer",
    basicMask            = "Basic Mask",
    fadeRight            = "AnimateAtoBEffect_FadeRight",
    fadeLeft             = "AnimateAtoBEffect_FadeLeft",
    fadeDown             = "AnimateAtoBEffect_FadeDown",
    fadeUp               = "AnimateAtoBEffect_FadeUp",
    pushUp               = "Multi Transform",
    wippMarkerClean      = "WippMarker_Clean",
    wippHighlightCenter  = "WippHighlight_Center",
    wippUnderlay         = "WippUnderlay",
}

-- ---------------------------------------------------------------------------
-- Open Project Folder (Ctrl+Shift+Alt+O)
-- ---------------------------------------------------------------------------
C.openProjectFolder = {
    fuscript = "/Applications/DaVinci Resolve/DaVinci Resolve.app/Contents/Libraries/Fusion/fuscript",
    timeout  = 20,   -- seconds to wait for Resolve to answer

    -- label -> path relative to the project root
    folders = {
        { "ARoll",        "Captures/ARoll" },
        { "BRoll",        "Captures/BRoll" },
        { "Audio",        "Captures/Audio" },
        { "Images",       "Images" },
        { "Footages",     "Footages" },
        { "Exports",      "_Exports" },
        { "Project Root", "" },
    },

    -- Projects created on Windows keep Windows paths (e.g. "D:/Work/...").
    -- Map those prefixes to where the same folders live on this Mac.
    -- Matching is case-insensitive; "\" and "/" are treated the same.
    pathMappings = {
        -- { from = "D:/Work", to = "/Volumes/Work" },
    },
}

-- ---------------------------------------------------------------------------
-- Memory purge (Ctrl+Cmd+Alt+Delete) — the Mac stand-in for RAMMap -Et.
-- `purge` needs root; see README for the one-line sudoers entry.
-- ---------------------------------------------------------------------------
C.purgeCommand = { "/usr/bin/sudo", "-n", "/usr/sbin/purge" }

-- ---------------------------------------------------------------------------
-- Swiftpoint X1 mouse profiles (per-layout names are in C.layouts above).
-- Needs "Enable X1 API" turned on in the X1 Control Panel options.
-- ---------------------------------------------------------------------------
C.mouseProfile = {
    enabled    = true,
    socketPath = "/tmp/swiftpoint.x1.v2.command",
    timeout    = 2,   -- seconds
}

-- ---------------------------------------------------------------------------
-- Keyboard modifiers + mouse keys (utilities/modifier_merge.lua)
--
-- The X1 sends keys like Up/Down from mouse buttons, but on macOS those keys
-- ignore the Option/Ctrl/Shift/Cmd you hold on the keyboard (Windows merged
-- them). Keys listed here get the held modifiers added back, so holding
-- Option + the mouse's Up button gives Option+Up again.
-- ---------------------------------------------------------------------------
C.modifierMerge = {
    enabled = true,
    keys    = { "up", "down", "left", "right", "home", "end", "pageup", "pagedown" },
}

-- ---------------------------------------------------------------------------
-- Timing (seconds). AHK's own Sleep values are kept in the macro code; these
-- are the Mac-only knobs.
-- ---------------------------------------------------------------------------
C.timing = {
    keyStroke       = 0.01,   -- key down -> key up for each synthetic keystroke
    click           = 0.01,   -- mouse down -> mouse up for each synthetic click
    afterSearchOpen = 0.05,   -- after the search key, before typing the effect name
    beforeEnter     = 0.25,   -- after typing the name, before Return (lets Resolve filter the list)
}

-- Reload Hammerspoon automatically when a .lua file in this folder changes.
C.autoReload = true

return C
