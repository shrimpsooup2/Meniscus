import QtQuick
import ".."

// python tools/preview.py glasslab --root tools/preview/GlassLab.qml
Runner {
    steps: [
        [50, () => {
            workspace.mockOpen("Light through water", "firefox", "browser", 40, 30, 940, 640)
            workspace.mockOpen("glass.frag", "org.kde.kate", "editor", 900, 120, 640, 520)
        }],
        [700, () => harness.shot("glasslab")]
    ]
}
