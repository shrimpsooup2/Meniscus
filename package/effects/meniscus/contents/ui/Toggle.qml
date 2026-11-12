import QtQuick

// An on/off switch with a glass knob. Pressed, the knob swells into glass; it slides across with
// the track's colour following it, and settles white on the far side. It can also be dragged.
// `checked` is the owner's and is never written here: a flip asks with `toggled` and shows the
// asked state until `checked` follows, sliding back if it never does.
Item {
    id: toggle

    required property Style ui
    property bool checked: false
    signal toggled(bool checked)

    property var wanted: null       // the state asked for, until `checked` catches up
    readonly property bool on: wanted === null ? checked : wanted
    readonly property bool held: area.pressed || slide.running || pulse.running

    readonly property real inset: 2
    readonly property real knobWidth: Math.round((height - 2 * inset) * 1.6)
    readonly property real travel: width - 2 * inset - knobWidth
    readonly property color offColor: Qt.rgba(ui.ink.r, ui.ink.g, ui.ink.b, ui.dark ? 0.26 : 0.16)

    implicitWidth: 60
    implicitHeight: 26
    opacity: enabled ? 1 : 0.4
    onCheckedChanged: wanted = null

    property real shown: on ? 1 : 0     // the knob's place, 0 off .. 1 on; dragging writes it
    Behavior on shown {
        enabled: !area.dragging
        NumberAnimation {
            id: slide
            duration: toggle.ui.brisk
            easing.type: Easing.OutBack
            easing.overshoot: 1.3
        }
    }

    property real lens: held ? 1 : 0
    Behavior on lens {
        NumberAnimation { duration: toggle.held ? toggle.ui.quick : toggle.ui.brisk; easing.type: Easing.OutCubic }
    }

    function flip() {
        ask(!on)
        pulse.restart()
    }

    function ask(state) {
        if (state === on)
            return
        wanted = state
        toggled(state)
        linger.restart()
    }

    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t)
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
            flip()
        else if (event.key === (on ? Qt.Key_Left : Qt.Key_Right))
            flip()
        else
            return
        event.accepted = true
    }

    Timer { id: pulse; interval: toggle.ui.quick }
    Timer { id: linger; interval: 900; onTriggered: toggle.wanted = null }

    Rectangle {
        id: rail
        anchors.fill: parent
        radius: height / 2
        color: toggle.mix(toggle.offColor, toggle.ui.accent, Math.max(0, Math.min(1, toggle.shown)))
    }

    Knob {
        ui: toggle.ui
        track: rail
        x: toggle.inset + toggle.shown * toggle.travel
        y: toggle.inset
        width: toggle.knobWidth
        height: toggle.height - 2 * toggle.inset
        lens: toggle.lens
    }

    MouseArea {
        id: area

        property bool dragging: false
        property real startX: 0
        property real startShown: 0

        anchors.fill: parent
        anchors.margins: -6
        onPressed: mouse => {
            startX = mouse.x
            startShown = toggle.shown
            dragging = false
        }
        onPositionChanged: mouse => {
            if (!dragging && Math.abs(mouse.x - startX) > 4)
                dragging = true
            if (dragging)
                toggle.shown = Math.max(0, Math.min(1, startShown + (mouse.x - startX) / Math.max(1, toggle.travel)))
        }
        onReleased: {
            if (!dragging) {
                toggle.flip()
                return
            }
            const state = toggle.shown > 0.5
            dragging = false
            toggle.ask(state)
            toggle.shown = Qt.binding(() => toggle.on ? 1 : 0)
        }
        onCanceled: {
            dragging = false
            toggle.shown = Qt.binding(() => toggle.on ? 1 : 0)
        }
    }
}
