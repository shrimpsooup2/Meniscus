# Testing on the machine

What the preview harness (`tools/preview.py`) cannot prove: everything that needs the real KWin, Plasma and hardware. Run through this list on Bazzite after `install.sh`, top to bottom, and note anything that fails next to its line.

## Effect

- [ ] `meniscus` shows under System Settings › Window Management › Desktop Effects and loads without errors (`journalctl --user -b | grep -i meniscus`).
- [ ] Every key in KEYBINDS.md fires, and none of them still runs its Plasma default.

## Palette (Meta+Space)

- [ ] Typing finds apps, files and settings; Enter runs the highlighted row.
- [ ] Ctrl+digit pins the highlighted app; the glass pill says "Pinned … to Meta digit"; the tray shows it.
- [ ] Theme rows change the theme; Plasma's popup names it.

## Tray (Meta+A, Meta+1 … 0)

- [ ] Held Meta+A peeks and goes on release; a tap stays.
- [ ] Hovering grows the app and swells the glass above it.
- [ ] Meta+digit focuses a running app (again: its next window) or starts it.

## Feedback

- [ ] With nothing open, Meta+digit shows Plasma's popup with the app name and the keys.
- [ ] The palette's *Shortcut Feedback* row turns it off and on.

## Glass and motion

- [ ] No stutter on first open of a surface, or on the first press of a toggle or slider knob (the harness shows a 115–245 ms hitch on first press).
- [ ] Sheets come out of and go back into their border smoothly at the display's refresh rate.
