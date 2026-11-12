import QtQuick
import QtQuick.Effects
import "pull.js" as Pull

// A surface's glass. It comes out of the screen border it belongs to and goes back into it the
// way a droplet meets a puddle, morphing like Liquid Glass (pull.js); a drawer slides out of its
// border and stays joined to it; with Pull off the glass only forms in place. Content is laid out
// at the resting size, scales with the glass and blurs while it morphs, and the whole sheet
// streaks with motion blur while it travels.
FocusScope {
    id: sheet

    required property Style ui
    required property var shell
    required property rect rest             // resting place, in screen coordinates
    property string side: "top"             // the border it comes out of and returns to
    property bool drawer: false             // slides out of its border and never leaves it
    property bool shown: false
    property real radius: ui.radius
    default property alias content: holder.data
    // A bulge of the glass, in the content's coordinates: a rect merged into the outline.
    property rect swell: Qt.rect(0, 0, 0, 0)
    property real swellRadius: 0
    property real swellReach: 0

    property real m: 1                      // 0 at rest, 1 gone
    property bool arriving: false           // the film m plays: coming out, or going back
    readonly property bool present: m < 1
    readonly property bool moving: film.running
    readonly property var frame: {
        const screen = Qt.rect(0, 0, width, height)
        if (drawer)
            return Pull.drawer(m, arriving, rest, screen, side, ui.pull ? ui.stretch : 0, ui.bounce)
        return ui.pull ? Pull.frame(m, arriving, rest, screen, side, ui.stretch, ui.bounce)
                       : Pull.drift(m, arriving, rest, screen, side, ui.bounce)
    }
    property vector2d streak: Qt.vector2d(0, 0)
    property point last

    anchors.fill: parent
    focus: shown
    enabled: shown

    function play() {
        film.stop()
        // Turned back halfway, a sheet plays its film backwards rather than jumping to the other.
        if (m <= 0 || m >= 1)
            arriving = shown
        film.from = m
        film.to = shown ? 0 : 1
        film.duration = Math.max(1, Math.abs(film.to - film.from) * ui.calm)
        film.start()
    }
    function centre() {
        return Qt.point(glass.x + glass.width / 2, glass.y + glass.height / 2)
    }

    onShownChanged: play()
    Component.onCompleted: if (shown) play()
    onPresentChanged: {
        shell.present += present ? 1 : -1
        if (!present)
            shell.settle()
    }
    Component.onDestruction: if (present) shell.present -= 1

    NumberAnimation {
        id: film
        target: sheet
        property: "m"
        easing.type: Easing.Linear          // the films ease themselves
    }

    FrameAnimation {
        running: sheet.moving && sheet.ui.motionBlur
        onRunningChanged: {
            sheet.last = sheet.centre()
            sheet.streak = Qt.vector2d(0, 0)
        }
        onTriggered: {
            // A sixtieth of a second of travel per unit of strength, whatever the refresh rate.
            const c = sheet.centre()
            const k = 0.016 * sheet.ui.blurStrength / Math.max(frameTime, 0.001)
            sheet.streak = Qt.vector2d((c.x - sheet.last.x) * k, (c.y - sheet.last.y) * k)
            sheet.last = c
        }
    }
    layer.enabled: ui.motionBlur && moving && streak.length() > 0.75
    layer.effect: Motion {
        velocity: Qt.vector2d(sheet.streak.x / Math.max(1, sheet.width), sheet.streak.y / Math.max(1, sheet.height))
    }

    Glass {
        id: glass
        ui: sheet.ui
        visible: sheet.present
        x: sheet.frame.x
        y: sheet.frame.y
        width: sheet.frame.width
        height: sheet.frame.height
        radius: {
            // Rounder while it morphs, up to a blob.
            const blob = Math.min(glass.width, glass.height) / 2
            return Math.min(sheet.radius, blob) + Math.max(0, blob - sheet.radius) * sheet.frame.round
        }
        fuse: sheet.frame.fuse
        fuseRadius: sheet.frame.fuseRadius
        fuseReach: sheet.frame.fuseReach
        swell: {
            // From the content's resting layout to the glass, as the content scales about its centre.
            const s = sheet.frame.scale
            return Qt.rect(holder.x + holder.width * (1 - s) / 2 + sheet.swell.x * s,
                           holder.y + holder.height * (1 - s) / 2 + sheet.swell.y * s,
                           sheet.swell.width * s, sheet.swell.height * s)
        }
        swellRadius: sheet.swellRadius * sheet.frame.scale
        swellReach: sheet.swellReach * sheet.frame.scale
        materialize: sheet.frame.materialize

        MouseArea {
            // The glass is solid to the pointer: clicks on it never reach the screen behind.
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }
        Item {
            id: holder
            x: (glass.width - width) / 2
            y: (glass.height - height) / 2
            width: sheet.rest.width
            height: sheet.rest.height
            scale: sheet.frame.scale
            opacity: sheet.frame.opacity
            visible: opacity > 0
            layer.enabled: sheet.ui.morphBlur && sheet.frame.blur > 0.01
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: sheet.frame.blur
                blurMax: 32
            }
        }
    }
}
