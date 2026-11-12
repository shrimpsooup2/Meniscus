import QtQuick

// The knob of a toggle or a slider, as iOS 26 draws it: a white pill at rest that, while held,
// swells into clear glass bending the track beneath it, and turns white again where it settles.
// A quick move stretches it along the way and thins it, like a drop.
Item {
    id: knob

    required property Style ui
    required property Item track    // what the knob runs along: a sibling under it
    property real lens: 0           // 0 at rest .. 1 held
    property real grow: 0.5         // how much bigger the held knob is

    property real speed: 0          // knob widths per second, smoothed
    readonly property real stretch: 1 + Math.min(0.15, speed * 0.04)
    readonly property real size: 1 + grow * lens
    readonly property bool lensing: lens > 0.01

    // The drawn glass of the nearest Glass this rests on, or null.
    function paneUnder() {
        for (let p = knob.parent; p; p = p.parent) {
            if (p.pane !== undefined)
                return p.pane
        }
        return null
    }

    // The glass is drawn under the white pill even at rest, so its textures and pipeline exist before
    // the first press rather than costing a frame then; they only refresh while the knob is glass.
    // The sheet may scale while it morphs, so where the knob sits on the pane is taken again per press.
    function aim() {
        bed.pane = paneUnder()
        if (bed.pane)
            under.sourceRect = bed.pane.mapFromItem(bed, 0, 0, bed.width, bed.height)
    }
    onLensingChanged: if (lensing) aim()
    Component.onCompleted: aim()

    FrameAnimation {
        property real last: 0
        running: knob.lens > 0
        onRunningChanged: {
            last = knob.x
            if (!running)
                knob.speed = 0
        }
        onTriggered: {
            const v = Math.abs(knob.x - last) / Math.max(frameTime, 0.004) / Math.max(1, knob.width)
            last = knob.x
            knob.speed += (v - knob.speed) * Math.min(1, frameTime * 20)
        }
    }

    // What the glass bends: the glass it rests on with the track over it, copied and held still
    // under the moving knob. Drawn only into the knob.
    Item {
        id: bed

        readonly property real margin: 2 * knob.height
        property Item pane: null

        visible: false
        x: knob.track.x - knob.x - margin
        y: knob.track.y - knob.y - margin
        width: knob.track.width + 2 * margin
        height: knob.track.height + 2 * margin

        Rectangle {
            anchors.fill: parent
            color: knob.ui.plate
        }
        ShaderEffectSource {
            id: under
            anchors.fill: parent
            sourceItem: bed.pane && bed.pane.visible ? bed.pane : null
            live: knob.lensing
        }
        ShaderEffectSource {
            x: bed.margin
            y: bed.margin
            width: knob.track.width
            height: knob.track.height
            sourceItem: knob.track
            live: knob.lensing
        }
    }

    Glass {
        id: glass
        anchors.centerIn: parent
        width: knob.width * knob.size * knob.stretch
        height: knob.height * knob.size / Math.sqrt(knob.stretch)
        ui: knob.ui
        backdrop: bed
        radius: height / 2
        followsMovement: knob.lensing
        live: knob.lensing
        tintAmount: 0
        tintColor: "transparent"
        frost: 0.1
        shadow: knob.ui.shadow * 0.7

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: "white"
            opacity: 1 - knob.lens
        }
    }
}
