import QtQuick
import QtQuick.Effects
import org.kde.kwin as KWin
import org.kde.kirigami as Kirigami
import "../../package/effects/meniscus/contents/ui"

// A working desk for the example renders: the windows the scene opens, the floating ones casting
// a shadow, and the glass `surface` names ("tray" or "palette") resting where it lives.
Item {
    id: show

    property string surface: "tray"
    property string query: "fi"
    property var results: [
        { name: "Firefox", sub: "Web Browser", icon: "org.mozilla.firefox", keys: ["Meta", "2"] },
        { name: "Files", sub: "File Manager", icon: "system-file-manager", keys: ["Meta", "1"] },
        { name: "Firewall", sub: "System Settings", icon: "preferences-system", keys: [] },
        { name: "fireflies.jpg", sub: "Pictures", icon: "image-jpeg", keys: [] }
    ]

    readonly property var running: KWin.Workspace.windows.map(window => window.desktopFileName)

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
                layer.enabled: !model.window.noBorder
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowBlur: 1
                    blurMax: 48
                    shadowOpacity: 0.5
                    shadowVerticalOffset: 14
                }
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

    component Cap: Rectangle {
        property alias text: legend.text
        width: Math.max(height, legend.implicitWidth + 12)
        height: 22
        radius: 7
        color: look.faint
        border.width: 1
        border.color: look.line
        Text {
            id: legend
            anchors.centerIn: parent
            color: look.dim
            font.pixelSize: look.textSmall
        }
    }

    Sheet {
        ui: look
        shell: shell
        side: "top"
        rest: Qt.rect((show.width - 640) / 2, look.edgeMargin, 640, list.implicitHeight + 2 * look.pad)
        m: show.surface === "palette" ? 0 : 1

        Column {
            id: list
            x: look.pad
            y: look.pad
            width: 640 - 2 * look.pad
            spacing: look.gap

            Rectangle {
                width: parent.width
                height: look.row
                radius: height / 2
                color: look.faint

                Item {
                    id: lens
                    x: look.pad
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18
                    height: 18
                    Rectangle {
                        width: 13
                        height: 13
                        radius: 6.5
                        color: "transparent"
                        border.width: 2
                        border.color: look.dim
                    }
                    Rectangle {
                        x: 11
                        y: 11
                        width: 8
                        height: 2.4
                        radius: 1.2
                        rotation: 45
                        transformOrigin: Item.Left
                        color: look.dim
                    }
                }
                Text {
                    id: typed
                    x: lens.x + lens.width + 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: show.query
                    color: look.ink
                    font.pixelSize: look.textTitle
                }
                Rectangle {
                    x: typed.x + typed.contentWidth + 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: 2
                    height: 22
                    radius: 1
                    color: look.accent
                }
            }

            Repeater {
                model: show.results
                Rectangle {
                    id: result
                    required property var modelData
                    required property int index
                    width: list.width
                    height: 52
                    radius: 16
                    color: index === 0 ? look.faint : "transparent"

                    Kirigami.Icon {
                        id: glyph
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32
                        height: 32
                        source: result.modelData.icon
                    }
                    Column {
                        x: glyph.x + glyph.width + 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1
                        Text {
                            text: result.modelData.name
                            color: look.ink
                            font.pixelSize: look.textBody
                        }
                        Text {
                            text: result.modelData.sub
                            color: look.dim
                            font.pixelSize: look.textSmall
                        }
                    }
                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Repeater {
                            model: result.modelData.keys
                            Cap {
                                required property string modelData
                                text: modelData
                            }
                        }
                    }
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
        rest: Qt.rect((show.width - 664) / 2, show.height - 88, 664, 88 + look.radius)
        m: show.surface === "tray" ? 0 : 1

        Row {
            x: look.pad
            y: look.pad
            spacing: look.gap
            Repeater {
                model: 10
                Rectangle {
                    id: tile
                    required property int index
                    readonly property var app: look.trayApps[index] || { id: "", icon: "" }
                    readonly property string slot: String((index + 1) % 10)
                    width: 56
                    height: 56
                    radius: 14
                    color: look.faint

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 34
                        height: 34
                        visible: tile.app.id !== ""
                        source: tile.app.icon
                    }
                    Text {
                        x: tile.app.id ? 6 : (tile.width - contentWidth) / 2
                        y: tile.app.id ? 3 : (tile.height - contentHeight) / 2
                        text: tile.slot
                        color: look.dim
                        font.pixelSize: tile.app.id ? 10 : look.textTitle
                    }
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: tile.height - 7
                        width: 4
                        height: 4
                        radius: 2
                        visible: show.running.indexOf(tile.app.id) >= 0
                        color: look.ink
                    }
                }
            }
        }
    }
}
