import QtQuick
import org.kde.kwin as KWin

// Plays a scene script. `steps` is a list of [delay in ms, function] run in
// order; the functions use `effect`, `workspace` and the global `harness`.
Item {
    id: runner

    required property var effect
    property bool keep: false
    property var steps: []
    property int at: 0
    readonly property var workspace: KWin.Workspace

    function next() {
        if (at >= steps.length) {
            if (!keep)
                harness.done()
            return
        }
        timer.interval = Math.max(1, steps[at][0])
        timer.restart()
    }

    Timer {
        id: timer
        onTriggered: {
            try {
                runner.steps[runner.at][1]()
            } catch (error) {
                harness.fail("step " + runner.at + ": " + error)
            }
            runner.at += 1
            runner.next()
        }
    }

    Component.onCompleted: next()
}
