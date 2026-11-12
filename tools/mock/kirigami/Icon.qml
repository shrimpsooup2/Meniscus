import QtQuick
import org.kde.kwin as KWin

// Stand-in for Kirigami.Icon: the picture cached for the name in tools/mock/icons if there is
// one, else a coloured tile with the name's initial.
Item {
    id: icon

    property var source
    property color color: "transparent"
    property bool active: false

    readonly property string name: typeof source === "string" ? source : ""
    readonly property string picture: KWin.Workspace.mockIcon(name)
    readonly property string label: name.substring(name.lastIndexOf(".") + 1)
    readonly property real hue: {
        let h = 7
        for (let i = 0; i < label.length; ++i)
            h = (h * 31 + label.charCodeAt(i)) % 360
        return h / 360
    }

    implicitWidth: 32
    implicitHeight: 32

    Image {
        anchors.fill: parent
        visible: icon.picture !== ""
        source: icon.picture
        sourceSize: Qt.size(Math.ceil(width * 2), Math.ceil(height * 2))
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: Math.round(parent.width * 0.06)
        visible: icon.picture === ""
        radius: width * 0.26
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.hsla(icon.hue, 0.62, 0.64, 1) }
            GradientStop { position: 1; color: Qt.hsla(icon.hue, 0.66, 0.44, 1) }
        }

        Text {
            anchors.centerIn: parent
            text: icon.label.charAt(0).toUpperCase()
            color: "#ffffff"
            font.pixelSize: Math.round(parent.height * 0.52)
            font.weight: Font.DemiBold
        }
    }
}
