import QtQuick
import ".."

// python tools/preview.py showcase --root tools/preview/Showcase.qml --size 1920x1080 --theme amethyst
// Firefox and Kate docked frameless side by side, Konsole floating in its frame; the tray up,
// then the palette down.
Runner {
    steps: [
        [50, () => {
            workspace.mockOpen("Light through water — Mozilla Firefox", "org.mozilla.firefox", "browser",
                               0, 0, 960, 1080).noBorder = true
            workspace.mockOpen("glass.frag — Kate", "org.kde.kate", "editor", 960, 0, 960, 1080).noBorder = true
            workspace.mockOpen("~ : bash — Konsole", "org.kde.konsole", "terminal", 1150, 560, 640, 330)
            effect.surface = "tray"
        }],
        [700, () => harness.shot("showcase")],
        [50, () => effect.surface = "palette"],
        [700, () => harness.shot("showcase_palette")]
    ]
}
