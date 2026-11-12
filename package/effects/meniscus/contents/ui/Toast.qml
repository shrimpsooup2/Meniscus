import QtQuick
import org.kde.kirigami as Kirigami

// What a key just did, for a moment: a small glass pill over the bottom border, above the tray
// when it is up. It forms out of the glass and rises a little, then goes the same way.
Item {
    id: toast

    required property Style ui
    property var note: null                     // {text, keys, icon}
    property real lift: 0                       // room kept clear above the bottom border
    property real m: 0                          // 0 gone, 1 shown

    anchors.fill: parent

    onNoteChanged: if (note) {
        m = 1
        hold.restart()
    }

    Behavior on m {
        NumberAnimation { duration: toast.ui.brisk; easing.type: Easing.OutCubic }
    }
    Timer {
        id: hold
        interval: 1600
        onTriggered: toast.m = 0
    }

    Glass {
        ui: toast.ui
        visible: toast.m > 0.01
        width: line.implicitWidth + 2 * toast.ui.pad
        height: 44
        radius: height / 2
        x: (toast.width - width) / 2
        y: toast.height - toast.lift - 24 - height + 14 * (1 - toast.m)
        materialize: toast.m

        Row {
            id: line
            anchors.centerIn: parent
            spacing: toast.ui.gap
            opacity: toast.m

            Kirigami.Icon {
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                height: 22
                visible: !!toast.note && toast.note.icon !== ""
                source: toast.note ? toast.note.icon : ""
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: toast.note ? toast.note.text : ""
                color: toast.ui.ink
                font.pixelSize: toast.ui.textBody
            }
            Repeater {
                model: toast.note ? toast.note.keys : []
                Cap {
                    required property string modelData
                    anchors.verticalCenter: parent.verticalCenter
                    ui: toast.ui
                    text: modelData
                }
            }
        }
    }
}
