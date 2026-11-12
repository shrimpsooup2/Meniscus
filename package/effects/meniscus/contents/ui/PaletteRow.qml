import QtQuick
import org.kde.kirigami as Kirigami

// One row of the palette: an icon, a name over a line of detail, and the keys that reach it.
Rectangle {
    id: row

    required property Style ui
    property string name
    property string sub
    property var icon
    property var keys: []
    property bool current: false

    signal pointed()
    signal chosen()

    height: 52
    radius: 16
    color: current ? ui.faint : "transparent"

    Kirigami.Icon {
        id: glyph
        x: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 32
        height: 32
        source: row.icon
    }
    Column {
        x: glyph.x + glyph.width + 14
        width: keys.x - x - 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1
        Text {
            width: parent.width
            text: row.name
            elide: Text.ElideRight
            color: row.ui.ink
            font.pixelSize: row.ui.textBody
        }
        Text {
            width: parent.width
            visible: text !== ""
            text: row.sub
            elide: Text.ElideRight
            color: row.ui.dim
            font.pixelSize: row.ui.textSmall
        }
    }
    Row {
        id: keys
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        Repeater {
            model: row.keys
            Cap {
                required property string modelData
                ui: row.ui
                text: modelData
            }
        }
    }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: row.pointed()
        onClicked: row.chosen()
    }
}
