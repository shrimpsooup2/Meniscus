import QtQuick

// A slider with a glass knob: held or stepped from the keyboard, the knob swells into glass over
// the fill, which ends under its middle, and settles white when let go. `value` is the owner's
// and is never written here: a move asks with `moved` and shows the asked value until `value`
// follows.
Item {
    id: slider

    required property Style ui
    property real value: 0
    property real from: 0
    property real to: 100
    property real step: 5           // per arrow key
    signal moved(real value)

    property real wanted: NaN       // the value asked for, until `value` catches up
    readonly property real current: isNaN(wanted) ? value : wanted
    readonly property real fraction: to > from ? Math.max(0, Math.min(1, (current - from) / (to - from))) : 0
    readonly property bool held: area.pressed || pulse.running

    readonly property real knobWidth: 34
    readonly property real knobHeight: 22
    readonly property real trackHeight: 6
    readonly property real travel: width - knobWidth
    readonly property color restColor: Qt.rgba(ui.ink.r, ui.ink.g, ui.ink.b, ui.dark ? 0.22 : 0.14)

    implicitWidth: 240
    implicitHeight: knobHeight
    opacity: enabled ? 1 : 0.4

    property real shown: fraction       // the knob's place, 0 .. 1
    Behavior on shown {
        enabled: !area.dragging
        NumberAnimation { duration: slider.ui.brisk; easing.type: Easing.OutCubic }
    }

    property real lens: held ? 1 : 0
    Behavior on lens {
        NumberAnimation { duration: slider.held ? slider.ui.quick : slider.ui.brisk; easing.type: Easing.OutCubic }
    }

    function ask(v) {
        v = Math.max(from, Math.min(to, v))
        linger.restart()
        if (v === current)
            return
        wanted = v
        moved(v)
    }

    function nudge(steps) {
        ask(current + steps * step)
        pulse.restart()
    }

    function valueAt(x) {
        return from + (to - from) * Math.max(0, Math.min(1, (x - knobWidth / 2) / Math.max(1, travel)))
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Left || event.key === Qt.Key_Down)
            nudge(-1)
        else if (event.key === Qt.Key_Right || event.key === Qt.Key_Up)
            nudge(1)
        else if (event.key === Qt.Key_Home)
            nudge(-(to - from) / step)
        else if (event.key === Qt.Key_End)
            nudge((to - from) / step)
        else
            return
        event.accepted = true
    }

    Timer { id: pulse; interval: 450 }
    Timer { id: linger; interval: 900; onTriggered: if (!area.pressed) slider.wanted = NaN }

    Item {
        id: rail
        anchors.fill: parent

        Rectangle {
            y: (parent.height - height) / 2
            width: parent.width
            height: slider.trackHeight
            radius: height / 2
            color: slider.restColor
        }
        Rectangle {
            y: (parent.height - height) / 2
            width: slider.knobWidth / 2 + slider.shown * slider.travel
            height: slider.trackHeight
            radius: height / 2
            color: slider.ui.accent
        }
    }

    Knob {
        ui: slider.ui
        track: rail
        x: slider.shown * slider.travel
        y: (slider.height - height) / 2
        width: slider.knobWidth
        height: slider.knobHeight
        grow: 0.3
        lens: slider.lens
    }

    MouseArea {
        id: area

        property bool dragging: false
        property real startX: 0

        anchors.fill: parent
        anchors.margins: -8
        onPressed: mouse => {
            startX = mouse.x
            dragging = false
            slider.ask(slider.valueAt(mouse.x + anchors.margins))
        }
        onPositionChanged: mouse => {
            if (!dragging && Math.abs(mouse.x - startX) > 3)
                dragging = true
            if (dragging)
                slider.ask(slider.valueAt(mouse.x + anchors.margins))
        }
        onReleased: {
            dragging = false
            linger.restart()
        }
        onCanceled: dragging = false
    }
}
