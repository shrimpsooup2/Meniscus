import QtQuick
import ".."

// python tools/preview.py shell --size 1920x1080 --theme amethyst
// Drives the real effect through its shortcuts, keys and corners and checks where it ends up.
Runner {
    function expect(what, value, wanted) {
        if (value !== wanted)
            throw new Error(what + " is " + JSON.stringify(value) + ", wanted " + JSON.stringify(wanted))
    }
    // Middle of tray slot i (0 to 9) at 1920x1080.
    function slot(i) {
        return 672 + 64 * i
    }

    steps: [
        [50, () => {
            workspace.mockOpen("Light through water", "org.mozilla.firefox", "browser", 40, 30, 940, 640)
            workspace.mockOpen("glass.frag", "org.kde.kate", "editor", 900, 120, 640, 520)
        }],
        // Palette: a held key repeats, which must not toggle it shut.
        [100, () => harness.shortcut("Meta+Space", 3)],
        [600, () => { expect("surface", effect.surface, "palette"); harness.shot("shell_palette") }],
        [50, () => harness.type("fire")],
        [400, () => harness.shot("shell_palette_apps")],
        // Ctrl+3 pins the highlighted app to slot 3, and the glass says so.
        [50, () => harness.key("3", Qt.ControlModifier)],
        [400, () => { expect("toast", effect.toast ? effect.toast.text : "", "Pinned Firefox to"); harness.shot("shell_toast") }],
        [50, () => { harness.key("Backspace"); harness.key("Backspace"); harness.key("Backspace"); harness.key("Backspace") }],
        [50, () => harness.type("theme")],
        [50, () => harness.key("Down")],
        [400, () => harness.shot("shell_palette_commands")],
        [50, () => harness.key("Escape")],
        [50, () => expect("surface", effect.surface, "")],
        [800, () => expect("visible", effect.visible, false)],

        // Tray held: Meta going up puts it away.
        [800, () => harness.shortcut("Meta+A")],
        [400, () => harness.keyUp("Super_L")],
        [50, () => expect("surface after a held peek", effect.surface, "")],
        // Tray tapped: it stays.
        // In one step, so a slow frame cannot turn the tap into a hold.
        [800, () => { harness.shortcut("Meta+A"); harness.keyUp("Super_L") }],
        [500, () => { expect("surface after a tap", effect.surface, "tray"); harness.shot("shell_tray") }],
        [50, () => harness.move(slot(2), 1036)],
        [700, () => harness.shot("shell_tray_hover_3")],
        [50, () => harness.move(slot(6), 1036)],
        [700, () => harness.shot("shell_tray_hover_7")],
        // Firefox is running behind Kate: its slot brings it forward.
        [50, () => harness.click(slot(1), 1036)],
        [50, () => {
            expect("surface after a launch", effect.surface, "")
            expect("active window", workspace.activeWindow.caption, "Light through water")
        }],
        // Dolphin is not running: Meta+1 starts it.
        [800, () => harness.shortcut("Meta+1")],

        // The top left corner opens the palette; Tab walks on to the tray.
        [300, () => harness.corner(7)],
        [500, () => expect("surface from the corner", effect.surface, "palette")],
        [50, () => harness.key("Tab")],
        [500, () => { expect("surface after Tab", effect.surface, "tray"); harness.shot("shell_tab_tray") }],
        [50, () => harness.click(960, 400)],
        [800, () => {
            expect("surface after a click away", effect.surface, "")
            expect("visible", effect.visible, false)
        }],
    ]
}
