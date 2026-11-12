import QtQuick
import org.kde.kwin as KWin
import org.kde.kirigami as Kirigami

// The tray: ten apps in a drawer on the bottom border, Meta and 1 to 0 for each. Pointing at an
// app sizes it up and the glass swells over it; a click or its number goes to the app, or starts
// it when it is not running.
Sheet {
    id: tray

    readonly property real tile: 56
    readonly property real pitch: tile + ui.gap
    readonly property real span: 10 * tile + 9 * ui.gap + 2 * ui.pad
    readonly property real depth: tile + 2 * ui.pad
    readonly property real grow: 0.3            // the app pointed at, at full size
    readonly property real rise: 16             // how far the swell rises over the glass
    readonly property real reach: 28            // the swell's neck

    property real pointer: NaN                  // over the apps, in the content's coordinates
    property real at: span / 2                  // the swell's centre, springing after the pointer
    property real lift: pointing ? 1 : 0        // how far the swell and the apps have grown
    readonly property bool pointing: !isNaN(pointer)

    property int epoch: 0                       // bumped as windows come and go
    readonly property var running: {
        epoch
        return shown ? KWin.Workspace.windows.map(window => window.desktopFileName) : []
    }

    // Each app's scale, by its distance from the swell, and its shift: grown apps push their
    // neighbours aside so the gaps between them stay even.
    readonly property var poses: {
        const scales = []
        let total = 0
        for (let i = 0; i < 10; ++i) {
            const d = (ui.pad + i * pitch + tile / 2 - at) / (0.8 * pitch)
            scales.push(1 + grow * lift * Math.exp(-d * d))
            total += tile * (scales[i] - 1)
        }
        const poses = []
        let before = 0
        for (let i = 0; i < 10; ++i) {
            const extra = tile * (scales[i] - 1)
            poses.push({ scale: scales[i], shift: (before - (total - before - extra)) / 2 })
            before += extra
        }
        return poses
    }

    side: "bottom"
    drawer: true
    // Its foot runs a radius past the border, so only the top corners are round.
    rest: Qt.rect((width - span) / 2, height - depth, span, depth + ui.radius)
    // Sunk a neck's reach into the glass it leaves no mark; risen, it bulges over the apps.
    swell: {
        const w = tile + 2 * ui.pad
        return Qt.rect(Math.max(0, Math.min(span - w, at - w / 2)), reach + 2 - (rise + reach + 2) * lift, w, 48)
    }
    swellRadius: 24
    swellReach: lift > 0.002 ? reach : 0

    Behavior on lift {
        SpringAnimation { spring: 3.5; damping: 0.32; epsilon: 0.002 }
    }
    Behavior on at {
        enabled: tray.lift > 0.05
        SpringAnimation { spring: 4; damping: 0.42; epsilon: 0.25 }
    }

    function middle(i) {
        return ui.pad + i * pitch + tile / 2 + poses[i].shift
    }
    function tileAt(x) {
        for (let i = 0; i < 10; ++i) {
            if (Math.abs(x - middle(i)) <= tile * poses[i].scale / 2 + ui.gap / 2)
                return i
        }
        return -1
    }

    onShownChanged: if (!shown) pointer = NaN
    Keys.onPressed: event => {
        const n = event.key - Qt.Key_0
        if (n >= 0 && n <= 9 && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier))) {
            tray.shell.launch((n + 9) % 10)
            event.accepted = true
        }
    }

    Connections {
        target: KWin.Workspace
        function onWindowAdded() { tray.epoch++ }
        function onWindowRemoved() { Qt.callLater(() => tray.epoch++) }
    }

    MouseArea {
        // Over the apps and the room they grow into.
        y: -tray.rise - 12
        width: tray.span
        height: tray.depth + tray.rise + 12
        hoverEnabled: true
        onPositionChanged: mouse => {
            tray.pointer = mouse.x
            tray.at = mouse.x
        }
        onExited: tray.pointer = NaN
        onClicked: mouse => {
            const i = tray.tileAt(mouse.x)
            if (i >= 0)
                tray.shell.launch(i)
        }
    }

    Repeater {
        model: 10
        Rectangle {
            id: slot
            required property int index
            readonly property var app: tray.ui.trayApps[index]
            readonly property var pose: tray.poses[index]
            readonly property bool filled: app.id !== ""
            x: tray.ui.pad + index * tray.pitch + pose.shift
            y: tray.ui.pad
            z: pose.scale
            width: tray.tile
            height: tray.tile
            radius: 14
            scale: pose.scale
            transformOrigin: Item.Bottom
            color: tray.ui.faint

            Kirigami.Icon {
                anchors.centerIn: parent
                width: 34
                height: 34
                visible: slot.filled
                source: slot.app.icon
            }
            Text {
                x: slot.filled ? 6 : (slot.width - contentWidth) / 2
                y: slot.filled ? 3 : (slot.height - contentHeight) / 2
                text: String((slot.index + 1) % 10)
                color: tray.ui.dim
                font.pixelSize: slot.filled ? 10 : tray.ui.textTitle
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: slot.height - 7
                width: 4
                height: 4
                radius: 2
                visible: slot.filled && tray.running.indexOf(slot.app.id) >= 0
                color: tray.ui.ink
            }
        }
    }
}
