import QtQuick

// A key, drawn next to whatever it opens or runs.
Rectangle {
    id: cap

    required property Style ui
    property alias text: legend.text

    width: Math.max(height, legend.implicitWidth + 12)
    height: 22
    radius: 7
    color: ui.faint
    border.width: 1
    border.color: ui.line

    Text {
        id: legend
        anchors.centerIn: parent
        color: cap.ui.dim
        font.pixelSize: cap.ui.textSmall
    }
}
