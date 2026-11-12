import QtQuick
import org.kde.kwin as KWin
import "../../package/effects/meniscus/contents/ui"

// Toggles and sliders on a glass panel over the desktop, each owner following what is asked of it.
Item {
    id: lab

    property bool wifi: true
    property bool bluetooth: false
    property bool quiet: true
    property bool night: false
    property real volume: 40
    property real brightness: 70

    property alias wifiToggle: wifiToggle
    property alias nightToggle: nightToggle
    property alias volumeSlider: volumeSlider
    property alias brightnessSlider: brightnessSlider

    // The middle of an item, in window coordinates, for the harness's pointer.
    function spot(item, dx) {
        return item.mapToItem(null, item.width / 2 + (dx || 0), item.height / 2)
    }

    Item {
        id: scene
        anchors.fill: parent
        KWin.DesktopBackground { anchors.fill: parent }
    }

    Style {
        id: look
        config: KWin.Workspace.mockConfig
        backdrop: scene
    }

    component Line: Item {
        property alias text: label.text
        default property alias control: holder.data
        width: parent.width
        height: look.row
        Text {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            color: look.ink
            font.pixelSize: look.textBody
        }
        Item {
            id: holder
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: childrenRect.width
            height: childrenRect.height
        }
    }

    Glass {
        ui: look
        anchors.centerIn: parent
        width: 420
        height: column.implicitHeight + 2 * look.pad

        Column {
            id: column
            x: 2 * look.pad
            y: look.pad
            width: parent.width - 4 * look.pad

            Line {
                text: "Wi-Fi"
                Toggle { id: wifiToggle; ui: look; checked: lab.wifi; onToggled: v => lab.wifi = v }
            }
            Line {
                text: "Bluetooth"
                Toggle { ui: look; checked: lab.bluetooth; onToggled: v => lab.bluetooth = v }
            }
            Line {
                text: "Do Not Disturb"
                Toggle { ui: look; checked: lab.quiet; onToggled: v => lab.quiet = v }
            }
            Line {
                text: "Night Light"
                Toggle { id: nightToggle; ui: look; checked: lab.night; onToggled: v => lab.night = v }
            }
            Line {
                text: "Volume"
                Slider { id: volumeSlider; ui: look; width: 220; value: lab.volume; onMoved: v => lab.volume = v }
            }
            Line {
                text: "Brightness"
                Slider { id: brightnessSlider; ui: look; width: 220; value: lab.brightness; onMoved: v => lab.brightness = v }
            }
        }
    }
}
