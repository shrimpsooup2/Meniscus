# Keybinds

This file lists every key Meniscus binds and every default in Plasma 6.8.2 (Bazzite's Plasma) it could collide with. Check here before binding a key, and add the row in the same commit as the code.

Plasma defaults were read from the 6.8.2 release sources of kwin, plasma-workspace, plasma-desktop, plasma-pa, powerdevil, kscreenlocker, kscreen, spectacle, plasma-systemmonitor, systemsettings, kactivitymanagerd, plasma-activities, kdeplasma-addons, kmenuedit, bluedevil and plasma-nm. Konsole and Dolphin come from KDE's master branch, and Bazzite from its repository. Source paths are inside each project.

## Meniscus

These are the default keys. Every row is planned; nothing is bound yet. Any key can be changed in the Keymap (Meta+K) or in System Settings › Keyboard › Shortcuts › KWin. *Both* means the full edition and Meniscus Flow.

| Key | Action | Edition |
|:--|:--|:--|
| Meta+Space | Palette: apps, files, commands | both |
| Meta+A, held | Tray: the app drawer; it closes when you let go | both |
| Meta+1 … Meta+9, Meta+0 | Start tray app 1–10, with the tray up or not | both |
| Meta+C | Controls: media, volume, brightness, power | both |
| Meta+M | Modes | both |
| Meta+F | Pop the active window out into a framed float, or dock it back | both |
| Meta+K | Keymap: see and change every key, Plasma's included | both |
| Meta+Tab | Deck | full |

Hot corners, set by `HotCorners` and `Corner*`:

| Corner | Opens |
|:--|:--|
| Top left | Palette |
| Top right | Controls |
| Bottom left | Deck (nothing in Flow) |
| Bottom right | nothing |

These keys work only while a Meniscus surface is open, and they never reach other apps:

| Key | Action |
|:--|:--|
| Esc, or a click on the empty desktop | Close |
| Tab, Shift+Tab | Next, previous surface |
| Arrows, Enter | Move, run |
| 1 … 9, 0 | Tray slots, while the tray is up |
| Letting go of Meta | With `HoldToCommit` on, run the highlighted item and close |

### Leader chords (draft)

The leader key is not chosen yet. Press the leader, then a group letter, then an action letter. Each action finishes according to its kind:

- **toggle**: happens at once.
- **now**: happens at once too, but isn't an on/off switch.
- **pick**: click the target, such as a window or a mode. Enter uses the active window; Esc cancels.
- **drag**: a slider appears. Drag anywhere; how far you drag sets the value. Let go to keep it, or press Esc to put it back. Arrow keys nudge it.

| Chord | Action | Kind |
|:--|:--|:--|
| W L, W R | Dock to the left or right half | pick |
| W S | Solo: the only docked window | pick |
| W F | Float or dock | toggle |
| W B | Frame on/off | toggle |
| W C | Close | pick |
| W M | Send to a mode | pick (a mode in the HUD, or 1–5) |
| M 1 … M 5 | Go to that mode | now |
| M N, M P | Next, previous mode | now |
| T | Theme picker | pick |
| G G | Glass on/off | toggle |
| G F | Frost | drag |
| G T | Tint | drag |
| G C | Curvature | drag |
| G B | Motion blur on/off | toggle |
| G P | Pull on/off | toggle |
| A P | Play/pause | toggle |
| A N, A B | Next, previous track | now |
| A M | Mute | toggle |
| A V | Volume | drag |
| S L | Lock | now |
| S S | Sleep | now |
| S O | Log out | now |
| S R | Restart | now |
| S P | Power off | now |

## Plasma 6.8.2 defaults

*off* marks an effect or script that ships disabled. Its keys bind only once you turn it on. Actions registered with no default key are left out.

### Meta alone, Meta+letter

| Key | Action | Source |
|:--|:--|:--|
| Meta, tapped alone | Application Launcher (also Alt+F1) | plasma-workspace `shell/shellcorona.cpp:193` |
| Meta+B | Switch power profile (also the Battery key) | powerdevil `daemon/actions/bundled/powerprofile.cpp:71` |
| Meta+C | Cube, *off* | kdeplasma-addons `kwin/effects/cube/package/contents/ui/main.qml:41` |
| Meta+D | Peek at desktop | kwin `src/useractions.cpp:1012` |
| Meta+E | Dolphin | dolphin `src/org.kde.dolphin.desktop` |
| Meta+G | Overview grid | kwin `src/plugins/overview/overvieweffect.cpp:160` |
| Meta+I | System Settings (also the Tools key) | systemsettings `app/systemsettings.desktop:9` |
| Meta+L | Lock (also the ScreenSaver key) | kscreenlocker `settings/kscreensaversettings.cpp:20` |
| Meta+P | Display configuration (also the Display key) | kscreen `osd/org.kde.kscreen.desktop:105` |
| Meta+Q | Activity switcher | plasma-workspace `shell/shellcorona.cpp:204` |
| Meta+R | Record a region (also Meta+Shift+R) | spectacle `src/SpectacleCore.cpp:719` |
| Meta+T | Tiles editor | kwin `src/plugins/tileseditor/tileseditoreffect.cpp:33` |
| Meta+V | Clipboard at the pointer | plasma-workspace `klipper/klipper.cpp:137` |
| Meta+W | Overview | kwin `src/plugins/overview/overvieweffect.cpp:154` |

### Meta+other keys

| Key | Action | Source |
|:--|:--|:--|
| Meta+1 … Meta+9 | Task manager entry 1–9 (entry 10 has no key) | plasma-desktop `applets/taskmanager/backend.cpp:613` |
| Meta+0 | Zoom to actual size | kwin `src/plugins/zoom/zoom.cpp:66` |
| Meta+Plus, Meta+= | Zoom in | kwin `src/plugins/zoom/zoom.cpp:56` |
| Meta+Minus | Zoom out | kwin `src/plugins/zoom/zoom.cpp:60` |
| Meta+0, Meta+Plus, Meta+=, Meta+Minus | Magnifier, *off* | kwin `src/plugins/magnifier/magnifier.cpp:49-59` |
| Meta+Tab, Meta+Shift+Tab | Walk through windows (also Alt+Tab, Alt+Shift+Tab) | kwin `src/tabbox/tabbox.cpp:330-331` |
| Meta+\`, Meta+~ | Walk through the current app's windows (also Alt+\`, Alt+~) | kwin `src/tabbox/tabbox.cpp:334-335` |
| Meta+arrows | Quick tile left, right, top, bottom | kwin `src/useractions.cpp:890-896` |
| Meta+PgUp | Maximize | kwin `src/useractions.cpp:830` |
| Meta+PgDown | Minimize | kwin `src/useractions.cpp:838` |
| Meta+Backspace | Restore | kwin `src/useractions.cpp:836` |
| Meta+. | Emoji picker | plasma-desktop `emojier/app/org.kde.plasma.emojier.desktop:160` |
| Meta+* | Mouse click animation, *off* | kwin `src/plugins/mouseclick/mouseclick.cpp:41` |
| Meta+Esc | System Monitor | plasma-systemmonitor `org.kde.plasma-systemmonitor.desktop:209` |
| Meta+Print | Screenshot of the active window | spectacle `src/SpectacleCore.cpp:712` |
| Meta+F1 … Meta+F4 | Desktop 1–4 (also Ctrl+F1 … Ctrl+F4) | kwin `src/virtualdesktops.cpp:884-887` |
| Meta+F5, Meta+F6 | Move the pointer to the focused window, to the centre | kwin `src/useractions.cpp:1017-1018` |
| Meta+F7 | Present the app's windows (also Ctrl+F7) | kwin `src/plugins/windowview/windowvieweffect.cpp:68` |
| Meta+F9 | Present windows on this desktop (also Ctrl+F9) | kwin `src/plugins/windowview/windowvieweffect.cpp:50` |
| Meta+F10 | Present windows on all desktops (also Ctrl+F10, LaunchC) | kwin `src/plugins/windowview/windowvieweffect.cpp:59` |
| Meta+VolumeMute | Mute the microphone (also MicMute) | plasma-pa `src/kded/audioshortcutsservice.cpp:186` |

### Meta+Shift

| Key | Action | Source |
|:--|:--|:--|
| Meta+Shift+Left, Meta+Shift+Right | Window to the previous, next screen | kwin `src/useractions.cpp:970-972` |
| Meta+Shift+S | Spectacle (also Print) | spectacle `src/SpectacleCore.cpp:704` |
| Meta+Shift+Print | Screenshot of a region | spectacle `src/SpectacleCore.cpp:713` |
| Meta+Shift+R | Record a region (also Meta+R) | spectacle `src/SpectacleCore.cpp:719` |
| Meta+Shift+Esc | End input capture | kwin `src/plugins/eis/eisinputcapturemanager.cpp:37` |
| Meta+Shift+D | Minimize all, *off* | kwin `src/plugins/minimizeall/package/contents/code/main.js:112` |
| Meta+Shift+O | Minimize all others, *off* | kwin `src/plugins/minimizeall/package/contents/code/main.js:114` |
| Meta+Shift+F11, Meta+Shift+F12 | Clear all, last mouse marks, *off* | kwin `src/plugins/mousemark/mousemark.cpp:37-42` |

### Meta+Ctrl, Meta+Alt

| Key | Action | Source |
|:--|:--|:--|
| Meta+Ctrl+arrows | Switch one desktop over | kwin `src/virtualdesktops.cpp:775-778` |
| Meta+Ctrl+Shift+arrows | Take the window one desktop over | kwin `src/useractions.cpp:950-958` |
| Meta+Ctrl+A | Window demanding attention | kwin `src/useractions.cpp:860` |
| Meta+Ctrl+Esc | Kill a window | kwin `src/useractions.cpp:1015` |
| Meta+Ctrl+PgUp, Meta+Ctrl+PgDown | Previous, next task manager entry | plasma-desktop `applets/taskmanager/backend.cpp:582-589` |
| Meta+Ctrl+Shift+PgUp, Meta+Ctrl+Shift+PgDown | Move the active task entry back, forward | plasma-desktop `applets/taskmanager/backend.cpp:596-604` |
| Meta+Ctrl+Print | Screenshot of the window under the pointer | spectacle `src/SpectacleCore.cpp:714` |
| Meta+Ctrl+R | Record a window | spectacle `src/SpectacleCore.cpp:718` |
| Meta+Ctrl+I, Meta+Ctrl+U | Invert the screen, the window, *off* | kwin `src/plugins/invert/invert.cpp:45-52` |
| Meta+Ctrl+T | Thumbnail aside, *off* | kwin `src/plugins/thumbnailaside/thumbnailaside.cpp:32` |
| Meta+Ctrl+Touchpad Toggle, Meta+Ctrl+Zenkaku Hankaku | Touchpad on/off | plasma-desktop `kcms/touchpad/org.kde.touchpadshortcuts.desktop:165` |
| Meta+Alt+arrows | Focus the window in that direction | kwin `src/useractions.cpp:906-914` |
| Meta+Alt+K | Next keyboard layout | kwin `src/keyboard_layout.cpp:47` |
| Meta+Alt+L | Last keyboard layout | kwin `src/keyboard_layout.cpp:55` |
| Meta+Alt+P | Focus the panels | plasma-workspace `shell/shellcorona.cpp:271` |
| Meta+Alt+R | Record the screen | spectacle `src/SpectacleCore.cpp:717` |
| Meta+Alt+S | Screen reader | plasma-desktop `kded/screenreader/org.kde.screenreader.desktop:140` |
| Meta+Ctrl+Alt+Shift+Space | Emoji picker | plasma-desktop `emojier/app/org.kde.plasma.emojier.desktop:160` |

### Without Meta

| Key | Action | Source |
|:--|:--|:--|
| Alt+Tab, Alt+Shift+Tab, Alt+\`, Alt+~ | Task switcher | kwin `src/tabbox/tabbox.cpp:330-335` |
| Alt+F1 | Application Launcher | plasma-workspace `shell/shellcorona.cpp:193` |
| Alt+Space, Alt+F2, Search | KRunner | plasma-workspace `krunner/org.kde.krunner.desktop.cmake:71` |
| Alt+Shift+F2 | KRunner on the clipboard | plasma-workspace `krunner/org.kde.krunner.desktop.cmake:135` |
| Alt+F3 | Window menu | kwin `src/useractions.cpp:826` |
| Alt+F4 | Close the window | kwin `src/useractions.cpp:828` |
| Ctrl+F1 … Ctrl+F4 | Desktop 1–4 | kwin `src/virtualdesktops.cpp:884-887` |
| Ctrl+F7, Ctrl+F9, Ctrl+F10 | Present windows | kwin `src/plugins/windowview/windowvieweffect.cpp:50-68` |
| Ctrl+F12 | Show the desktop | plasma-workspace `shell/shellcorona.cpp:184` |
| Ctrl+Alt+Del | Log out screen | plasma-workspace `startkde/session-shortcuts/main.cpp:40` |
| Ctrl+Alt+T | Konsole | konsole `desktop/org.kde.konsole.desktop` |
| Print | Spectacle | spectacle `src/SpectacleCore.cpp:704` |
| Shift+Print | Screenshot of the full screen | spectacle `src/SpectacleCore.cpp:711` |

### Media and hardware keys

| Keys | Action | Source |
|:--|:--|:--|
| Play, Pause, Stop, Next, Previous, AudioForward, AudioRewind | Media control; the seeks jump 5 s | plasma-workspace `libkmpris/kded/mprisservice.cpp:142-163` |
| VolumeUp, VolumeDown (Shift for 1 %), VolumeMute, MicVolumeUp, MicVolumeDown, MicMute | Volume | plasma-pa `src/kded/audioshortcutsservice.cpp:85-186` |
| MonBrightnessUp, MonBrightnessDown (Shift for 1 %) | Screen brightness | powerdevil `daemon/powerdevilscreenbrightnessagent.cpp:143-164` |
| KeyboardBrightnessUp, KeyboardBrightnessDown, KeyboardLightOnOff | Keyboard backlight | powerdevil `daemon/actions/bundled/keyboardbrightnesscontrol.cpp:52-62` |
| Sleep, Hibernate, PowerOff, PowerDown | Suspend, hibernate, power off | powerdevil `daemon/actions/bundled/handlebuttonevents.cpp:52-76` |
| Touchpad On, Touchpad Off, Touchpad Toggle | Touchpad | plasma-desktop `kcms/touchpad/org.kde.touchpadshortcuts.desktop:115-165` |

Battery, Tools, ScreenSaver, Display, Search and LaunchC are listed above, next to the keys they share an action with.

### Screen edges

| Edge | Default | Source |
|:--|:--|:--|
| Top-left corner | Overview | kwin `src/plugins/overview/overviewconfig.kcfg:23-24` |
| Every other corner and edge, and all touch edges | Nothing | kwin `src/screenedge.cpp:828-849` |

## Bazzite

Bazzite (ublue-os/bazzite, main branch) changes no shortcuts. It ships no `kglobalshortcutsrc` or `khotkeysrc`, and its `kwinrc` only sets the Wayland input method and the virtual keyboard. Three things still matter:

- The terminal is Konsole (`kde-ptyxis` runs `/usr/bin/konsole`), so Ctrl+Alt+T opens Konsole.
- Discover is removed. The store is Bazaar.
- `bazzite-pins.js` pins the browser, Steam, Lutris, Konsole, Bazaar, Yafti and the file manager to the task manager. Out of the box, Meta+1 … Meta+7 open those [INFERENCE: entries follow the pin order].

## Conflicts

KWin offers each key to global shortcuts before effects see it (`src/input.cpp:3197` comes before `:3202`). So a key Plasma holds never reaches Meniscus [INFERENCE: the global shortcut filter consumes a match].

When two things claim one screen corner, KWin walks an unordered list and stops at the first that accepts (`src/screenedge.cpp:449-460`). Only one of them opens.

The installer therefore frees these keys and the corner in both editions. It first copies `~/.config/kglobalshortcutsrc` and `~/.config/kwinrc` aside, and the uninstaller puts them back.

| Meniscus | Held by | Installer |
|:--|:--|:--|
| Meta+1 … Meta+9 | Task manager entries 1–9 | Unbinds them |
| Meta+0 | Zoom to actual size (Zoom is on by default) | Unbinds Meta+0; Zoom keeps Meta+Plus, Meta+= and Meta+Minus |
| Meta+Tab (full) | Walk through windows | Unbinds Meta+Tab; Alt+Tab stays |
| Top-left corner | Overview | Sets `[Effect-overview] BorderActivate=9` (no edge) in `kwinrc`; Meta+W still opens Overview |
| Meta+C | Cube, only when turned on | Nothing; `doctor` warns |

Tapping Meta alone opens the launcher, and Meniscus leaves that alone. Letting go of Meta after a chord, such as after holding Meta+A, should not open the launcher: a modifier-only shortcut fires only when no other key was pressed in between [INFERENCE].

## Free Meta keys

Plasma 6.8.2 binds none of these by default: Meta+Space, A, C (unless Cube is on), F, H, J, K, M, N, O, S, U, X, Y, Z, F8, F11 and F12. Meniscus plans to use Space, A, C, F, K and M; the rest are open.

The scan matched the usual ways of registering a shortcut: `setGlobalShortcut`, `setDefaultShortcut`, `X-KDE-Shortcuts`, QML `ShortcutHandler`, `registerShortcut` in scripts, and a few helpers found by hand. A component that uses some other helper could still hide a default.

## Adding a key

1. Look the key up here first.
2. In the same commit as the code, add its row, plus a conflict row if it takes a key from something else.
3. On the machine, `doctor` (planned) asks kglobalaccel (`isGlobalShortcutAvailable`) whether each Meniscus key is still free. The Keymap and System Settings › Keyboard › Shortcuts show the live state too.
