import QtQuick
import org.kde.kwin as KWin
import "../../package/effects/meniscus/contents/ui"

// Film card for how glass comes and goes: a palette pulled from the top border and the tray's
// drawer at the bottom, both posed at `m` of the film `arriving` picks.
Item {
    id: lab

    property real m: 0
    property bool arriving: true
    property real gap: look.edgeMargin     // the palette's distance from the top border

    Item {
        id: scene
        anchors.fill: parent

        KWin.DesktopBackground { anchors.fill: parent }
        Repeater {
            model: KWin.WindowFilterModel { windowModel: KWin.WindowModel {} }
            KWin.WindowThumbnail {
                wId: model.window.internalId
                x: model.window.x
                y: model.window.y
                z: model.window.stackingOrder
                width: model.window.width
                height: model.window.height
            }
        }
    }

    Style {
        id: look
        config: KWin.Workspace.mockConfig
        backdrop: scene
    }

    QtObject {
        id: shell
        property int present: 0
        function settle() {}
    }

    Sheet {
        ui: look
        shell: shell
        side: "top"
        rest: Qt.rect((lab.width - 640) / 2, lab.gap, 640, 300)
        m: lab.m
        arriving: lab.arriving

        Column {
            x: look.pad
            y: look.pad
            width: 640 - 2 * look.pad
            spacing: look.gap
            Rectangle {
                width: parent.width
                height: look.row
                radius: height / 2
                color: look.faint
                Text {
                    x: look.pad
                    anchors.verticalCenter: parent.verticalCenter
                    text: "fire"
                    color: look.ink
                    font.pixelSize: look.textTitle
                }
            }
            Repeater {
                model: ["Firefox", "Firewall", "Fireplace.jpg", "Fire Emblem"]
                Text {
                    required property string modelData
                    x: look.pad
                    height: 44
                    verticalAlignment: Text.AlignVCenter
                    text: modelData
                    color: look.ink
                    font.pixelSize: look.textBody
                }
            }
        }
    }

    Sheet {
        ui: look
        shell: shell
        side: "bottom"
        drawer: true
        // Its foot runs a radius past the border, so only the top corners are round.
        rest: Qt.rect((lab.width - 664) / 2, lab.height - 88, 664, 88 + look.radius)
        m: lab.m
        arriving: lab.arriving

        Row {
            x: look.pad
            y: look.pad
            spacing: look.gap
            Repeater {
                model: 10
                Rectangle {
                    id: tile
                    required property int index
                    width: 56
                    height: 56
                    radius: 14
                    color: look.faint
                    Text {
                        anchors.centerIn: parent
                        text: (tile.index + 1) % 10
                        color: look.ink
                        font.pixelSize: look.textTitle
                    }
                }
            }
        }
    }
}
