import QtQuick
import ".."

// Throwaway: the palette and tray at rest over two windows.
Runner {
    steps: [
        [50, () => {
            workspace.mockOpen("Light through water", "firefox", "browser", 40, 30, 940, 640)
            workspace.mockOpen("glass.frag", "org.kde.kate", "editor", 900, 120, 640, 520)
        }],
        [100, () => { effect.arriving = true; effect.m = 0 }],
        [150, () => harness.shot("rest")],
    ]
}
