import QtQuick
import org.kde.kwin as KWin

// Stand-in for KWin's SceneEffect: a single view that exists while `visible`.
Item {
    id: effect

    property Component delegate
    property var configuration: KWin.Workspace.mockConfig
    readonly property Item activeView: view.item

    visible: false

    Loader {
        id: view
        anchors.fill: parent
        active: effect.visible
        sourceComponent: effect.delegate
    }

    Component.onCompleted: configuration.writeConfig = function () { KWin.Workspace.mockSay("writeConfig") }
}
