import QtQuick
import ".."

// python tools/preview.py arrive --root tools/preview/PullLab.qml --sheet arrive
Runner {
    steps: {
        const s = [[50, () => {
            workspace.mockOpen("Light through water", "firefox", "browser", 40, 30, 940, 640)
            workspace.mockOpen("glass.frag", "org.kde.kate", "editor", 900, 120, 640, 520)
        }]]
        for (const t of [0.04, 0.1, 0.2, 0.3, 0.4, 0.46, 0.52, 0.56, 0.64, 0.76, 0.88, 1]) {
            s.push([100, () => { effect.arriving = true; effect.m = 1 - t }])
            s.push([60, () => harness.shot("arrive_" + t.toFixed(2))])
        }
        return s
    }
}
