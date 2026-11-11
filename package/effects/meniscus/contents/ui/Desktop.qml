import QtQuick
import org.kde.kwin as KWin

// A desktop as it looks on one screen: its wallpaper and its windows, live, in stacking order.
// While Meniscus is up KWin draws only Meniscus, so this is what stands in for the desktop.
Item {
    id: desk

    required property var output
    property var desktop: KWin.Workspace.currentDesktop
    readonly property rect area: output ? output.geometry : Qt.rect(0, 0, width, height)

    clip: true

    KWin.DesktopBackground {
        anchors.fill: parent
        activity: KWin.Workspace.currentActivity
        desktop: desk.desktop
        outputName: desk.output ? desk.output.name : ""
    }

    Repeater {
        model: KWin.WindowFilterModel {
            activity: KWin.Workspace.currentActivity
            desktop: desk.desktop
            screenName: desk.output ? desk.output.name : ""
            windowModel: KWin.WindowModel {}
            windowType: 0x1 | 0x2 | 0x4         // normal, dialog, dock
            minimizedWindows: false
        }
        KWin.WindowThumbnail {
            required property var window
            wId: window.internalId
            x: window.x - desk.area.x
            y: window.y - desk.area.y
            width: window.width
            height: window.height
            z: window.stackingOrder
        }
    }
}
