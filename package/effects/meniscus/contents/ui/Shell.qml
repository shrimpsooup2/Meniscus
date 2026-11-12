import QtQuick
import org.kde.kwin as KWin

// One screen's view while Meniscus is up: its desktop and, on the screen it was opened on, the
// surface that is up. Esc or a click on the desktop puts it away, Tab walks to the next surface,
// and every key going up is passed on so letting go of Meta can end a peek.
FocusScope {
    id: view

    readonly property var effect: KWin.SceneView.effect
    readonly property bool here: effect.screen === ""
                                 || !!KWin.SceneView.screen && KWin.SceneView.screen.name === effect.screen

    focus: true
    Component.onCompleted: forceActiveFocus()

    Keys.onEscapePressed: effect.close()
    Keys.onTabPressed: effect.cycle(1)
    Keys.onBacktabPressed: effect.cycle(-1)
    Keys.onReleased: event => effect.keyUp(event.key)

    Desktop {
        id: desk
        anchors.fill: parent
        output: KWin.SceneView.screen
    }
    Style {
        id: look
        config: view.effect.configuration
        backdrop: desk
    }
    MouseArea {
        // A click anywhere off the glass puts the surface away.
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: view.effect.close()
    }

    PaletteSheet {
        ui: look
        shell: view.effect
        shown: view.here && view.effect.surface === "palette"
    }
    Tray {
        ui: look
        shell: view.effect
        shown: view.here && view.effect.surface === "tray"
    }
    Toast {
        ui: look
        note: view.here ? view.effect.toast : null
        lift: view.effect.surface === "tray" ? 124 : 0
    }
}
