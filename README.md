# Resolve Hammerspoon Macros

A macOS port of **Resolve AutoHotkey** (`../resolve-auto-hotkey`) for [Hammerspoon](https://www.hammerspoon.org/). It has the same layouts, plugins, utilities and settings. Resolve shortcuts work **only while DaVinci Resolve is the frontmost app**.

All settings live in [`config.lua`](config.lua): modifier mapping, coordinates, effect names, folders and timing. When you save a `.lua` file, Hammerspoon reloads it automatically.

---

## Setup

1. **Load it.** `~/.hammerspoon/init.lua` should contain:
   ```lua
   require("hs.ipc")
   dofile(os.getenv("HOME") .. "/Projects_Git/resolve-hammerspoon/init.lua")
   ```
2. **Accessibility.** Go to System Settings → Privacy & Security → Accessibility and turn on **Hammerspoon**. Without it, hotkeys still fire, but no keystrokes or clicks reach Resolve.
3. **Function keys.** For F1–F8, either turn on *System Settings → Keyboard → Keyboard Shortcuts → Function Keys → "Use F1, F2, etc. keys as standard function keys"* or hold `fn`.
4. **Recalibrate coordinates.** The GregTextPlus, WippZoom and Caption positions in `config.lua` are still the Windows values. Hover over each control and press `Ctrl+Shift+Alt+P` to read the position.
5. **Resolve keyboard preset.** The macros press Resolve shortcuts for you, with Ctrl turned into Cmd (see below). For example, the effect search shortcut (sent as literal **Ctrl+Space**, see `config.searchKey`), `Tab`, `h`, `Cmd+Shift+Alt+1` and `Cmd+Shift+Alt+9` must exist in your Mac keyboard preset.
6. **Resolve scripting** (Open Project Folder only). Go to Preferences → System → General → *External scripting using* = **Local**.

---

## Keys: Windows → Mac

Hotkeys are written AutoHotkey-style (`^` Ctrl, `!` Alt, `+` Shift, `#` Win) and translated in two directions (`config.modifiers`):

| Symbol | Keys **you press** (`trigger`) | Keys **sent to Resolve** (`send`) |
|---|---|---|
| `^` | Ctrl | **Cmd** (Resolve for Mac uses Cmd where Windows uses Ctrl) |
| `!` | Option | Option |
| `+` | Shift | Shift |
| `#` | Cmd | — |

So every shortcut in this README uses the **same physical keys as on Windows**, with Ctrl staying Ctrl. Only the Windows key becomes Cmd.

---

## Macro Layout (`Ctrl+Shift+Q`)

Hold `Ctrl+Shift+Q` and a menu opens at the cursor. Move the cursor onto a layout and release Q to pick it. Releasing Q off the menu cancels. The choices are **Edit** (default), Fusion, Color, Fairlight, Delivery and None.

Picking a layout switches Resolve to that page (`Shift+4`…`8`; Fusion also sends `h` first). It also switches the Swiftpoint X1 mouse profile (see *Mouse*). Page keys are only sent when Resolve is in front.

**Caption** (`macros/caption.lua`) is ported but left out of the menu, as in the AHK version. Add `"Caption"` to `config.macroModes` to use it.

## Plugin Mode (`Ctrl+Alt+Q`)

This is the same hold menu, for **GregTextPlus** (default), **WippZoom** and **None**. Only one plugin is active at a time because they share hotkeys.

---

## Edit Shortcuts (`macros/edit.lua`)

| Shortcut | Action |
|---|---|
| `F1` | Ripple Start (click, Tab, `q`) |
| `F2` | Ripple End (click, Tab, `w`) |
| `F3` | Cut (click, Tab, `b`) |
| `Option+P` | Purge Fusion memory cache |
| `Option+Shift+3` | Render in place |
| `F4` | Greg's Text+ (`GregsText_CLS`) |
| `F5` | John Simple Fill |
| `F6` | John Simple Shadow |
| `F7` | Gradual Animation Layer |
| `F8` | Basic Mask (+ `Cmd+Shift+Alt+9`) |
| `Shift+F1` | Fade Right Animation |
| `Shift+F2` | Fade Left Animation |
| `Shift+F3` | Fade Down Animation (on release: mouse up + `v`, as in the AHK file) |
| `Shift+F4` | Fade Up Animation |
| `Shift+F5` | Push Up Animation (Multi Transform) |
| `Shift+F6` | WippMarker Clean |
| `Shift+F7` | WippHighlight Center |
| `Shift+F8` | WippUnderlay |

The effect, title and generator names are in `config.spawn`.

## Fusion Shortcuts (`macros/fusion.lua`)

These work in the **Fusion** layout, and always in standalone Fusion Studio.

| Shortcut | Action |
|---|---|
| `Ctrl+Shift+1`–`9`, `0` | Copy the selected nodes and save them to slot 1–10 |
| `Cmd+1`–`9`, `0` | Paste slot 1–10 into the node editor (Ctrl+1/2 are held by another app on this Mac, so paste moved to Cmd; these override Resolve's own Cmd+number shortcuts while the Fusion layout is active) |

Slots are text files in `slots/` (git-ignored): `resolve_slotN.txt` and `studio_slotN.txt`. A small tooltip by the cursor confirms each save and paste.

## Caption Shortcuts (`macros/caption.lua`, when enabled)

| Shortcut | Action |
|---|---|
| `F1` | Loop: copy each subtitle's in point to the previous subtitle's out point |
| `F2` | Stop the loop |
| `F3` | Manual copy for the clicked row |

The loop also stops if Resolve loses focus.

## GregTextPlus Plugin (`plugins/gregtextplus.lua`)

Hold the shortcut and the cursor jumps to that slider with the left button held down. Drag left or right to change the value, then release the key (or Ctrl/Option) to let go.

| Shortcut | Action |
|---|---|
| `Ctrl+Option+A` | Drag X |
| `Ctrl+Option+W` | Drag Y |
| `Ctrl+Option+S` | Drag Size |

Ctrl and Option are stripped from the drag (`stripModifiers`), because Ctrl+click is a right-click on macOS.

## WippZoom Plugin (`plugins/wippzoom.lua`)

| Shortcut | Action |
|---|---|
| `Ctrl+Option+A` | Refresh match |
| `Ctrl+Option+D` | Swap |
| `Ctrl+Option+W` | Refresh size, increment up |
| `Ctrl+Option+S` | Refresh size, increment down |

---

## Utilities (active in every app)

| Shortcut | Action |
|---|---|
| `Ctrl+Shift+Option+V` | Clipboard case menu: ALL CAPS, lowercase, Title Case, Capitalize Each Word, Sentence case. It converts the clipboard text and pastes it. |
| `Ctrl+Shift+Option+O` | Open Project Folder: a menu for ARoll, BRoll, Audio, Images, Footages, Exports and Project Root of the current Resolve project. Press 1–7 or click; Esc closes. |
| `Ctrl+Shift+Option+P` | Show the mouse position (screen, window and monitor) with a button to copy it in `config.lua` format |
| `Ctrl+Cmd+Option+Delete` | Free inactive memory with `purge`, the Mac stand-in for RAMMap `-Et` |
| `Ctrl+Cmd+Option+Esc` (press twice) | Force-quit a frozen DaVinci Resolve (`pkill -9`). Mac-only addition for when a hung Resolve also freezes the mouse; the first press only arms it for 2 seconds, and unsaved work is lost. |

**Open Project Folder** asks Resolve through its bundled `fuscript`, so it needs no Python. Projects made on Windows still store Windows paths (e.g. `D:/Work/...`). Map them with `config.openProjectFolder.pathMappings`.

**Memory purge** needs root. To let it run without a password prompt, run this once in Terminal:
```bash
echo "$(whoami) ALL=(root) NOPASSWD: /usr/sbin/purge" | sudo tee /etc/sudoers.d/purge && sudo chmod 440 /etc/sudoers.d/purge
```

---

## Coordinates

`config.coordMode = "screen"` uses absolute Hammerspoon coordinates: the origin is the top-left of the main display and y grows downward. `"window"` makes every point relative to Resolve's focused window, so points still line up after the window moves. `Ctrl+Shift+Option+P` shows both and copies whichever mode is active.

## Mouse (Swiftpoint X1)

Each layout switches the X1 mouse profile (`mouseProfile` in `config.layouts`): Edit → `DavinciResolve`, Fusion → `Resolve-Fusion`, and so on. This happens when you pick a layout and whenever Resolve comes to the front, as in the AHK version. Hammerspoon sends `Profile Set <name>` to the X1 Control Panel's API socket, `/tmp/swiftpoint.x1.v2.command` (the macOS version of the Windows pipe). If the X1 app can't be reached, a tooltip says so; an error reply shows an alert.

This needs **"Enable X1 API"** turned on in the X1 Control Panel options; restart the X1 app after turning it on. Set `config.mouseProfile.enabled = false` to turn this off.

## Differences from the AHK version

- The layout and plugin menus include **None**, as the AHK README described (the AHK code had dropped it).
- A short on-screen note confirms each layout or plugin change.
- X1 API errors show a brief alert instead of a blocking message box.
- Page-switch keys are only sent when Resolve is frontmost.
- Open Project Folder uses `fuscript` instead of Python and tkinter.
- Explorer Focus (Win+Ctrl+Alt+Space) is not ported.
- The RAMMap hotkey uses the Mac `delete` key (Windows Backspace), since Mac keyboards have no forward-delete key.

## Debugging

- Open the Hammerspoon console from the menu bar icon → Console.
- From a terminal: `/Applications/Hammerspoon.app/Contents/Frameworks/hs/hs -c 'return RESOLVE_HS.status()'` shows the current layout, plugin, frontmost app and live hotkey groups.

## Layout of this project

```
init.lua                  entry point (= ResolveMacros.ahk)
config.lua                all settings
lib/                      keys, mouse, app detection, #HotIf groups, menus, tooltip
macros/                   macros.lua (layout switcher) + edit/fusion/caption/color/fairlight/delivery
plugins/                  plugins.lua (plugin switcher) + gregtextplus/wippzoom
utilities/                general, clipboard, open_project_folder, mouse_profile
```

To add a layout or plugin, create a module that exports `bind(group)`, add its name to `config.macroModes` / `config.pluginModes`, and register it in `macros/macros.lua` / `plugins/plugins.lua`.
