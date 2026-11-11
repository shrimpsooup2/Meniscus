import QtQuick
import ".."

// python tools/preview.py leave --root tools/preview/PullLab.qml --sheet leave
Runner {
    steps: {
        const s = [[50, () => {
            workspace.mockOpen("Light through water", "firefox", "browser", 40, 30, 940, 640)
            workspace.mockOpen("glass.frag", "org.kde.kate", "editor", 900, 120, 640, 520)
        }]]
        for (const t of [0, 0.04, 0.08, 0.14, 0.2, 0.26, 0.32, 0.36, 0.44, 0.52, 0.6, 0.8]) {
            s.push([100, () => { effect.arriving = false; effect.m = t }])
            s.push([60, () => harness.shot("leave_" + t.toFixed(2))])
        }
        return s
    }
}
