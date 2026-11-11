import QtQuick
import org.kde.kwin as KWin
import "../../package/effects/meniscus/contents/ui"

// Test card for the optics: bare glass over a ruled sheet, so the bend of
// every line that crosses a rim can be read off directly.
Item {
    id: lab

    Item {
        id: scene
        anchors.fill: parent

        Rectangle { anchors.fill: parent; color: "#f3efe6" }
        Repeater {
            model: Math.ceil(lab.width / 20)
            Rectangle {
                required property int index
                x: index * 20
                width: index % 5 === 0 ? 2 : 1
                height: lab.height
                color: index % 5 === 0 ? "#1d2733" : "#9aa3ad"
            }
        }
        Repeater {
            model: Math.ceil(lab.height / 20)
            Rectangle {
                required property int index
                y: index * 20
                width: lab.width
                height: index % 5 === 0 ? 2 : 1
                color: index % 5 === 0 ? "#1d2733" : "#9aa3ad"
            }
        }
        Repeater {
            model: ["#e4572e", "#17bebb", "#ffc914", "#76b041", "#8a4fff"]
            Rectangle {
                required property int index
                required property string modelData
                x: 110 + index * 290
                y: 470
                width: 210
                height: 150
                radius: 26
                color: modelData
            }
        }
        Text {
            x: 90
            y: 660
            text: "Sphinx of black quartz, judge my vow 0123456789"
            color: "#1d2733"
            font.pixelSize: 52
            font.weight: Font.Bold
        }
        Text {
            x: 90
            y: 740
            width: lab.width - 180
            wrapMode: Text.WordWrap
            lineHeight: 1.35
            text: "Where a liquid meets its container the surface curves. That curve gathers the light that crosses it, bends it towards the rim and returns it brighter, tighter and folded over at its border, and when the pane moves the picture inside it slides the other way. Nothing is painted on: everything you see in it is somewhere else, relocated."
            color: "#1d2733"
            font.pixelSize: 19
        }
    }

    Style {
        id: style
        config: KWin.Workspace.mockConfig
        backdrop: scene
    }

    // Untinted, so the optics read clearly.
    component Bare: Glass {
        tintAmount: 0
        tintColor: "transparent"
    }

    Bare { ui: style; x: 70; y: 50; width: 420; height: 260 }
    Bare { ui: style; x: 540; y: 50; width: 520; height: 56; radius: 28 }
    Bare { ui: style; x: 540; y: 140; width: 150; height: 150; radius: 75 }
    Bare { ui: style; x: 730; y: 140; width: 150; height: 150; radius: 40 }
    Bare { ui: style; x: 920; y: 140; width: 64; height: 64; radius: 32 }
    Bare { ui: style; x: 920; y: 230; width: 140; height: 60; radius: 30 }
    Bare { ui: style; x: 1110; y: 50; width: 420; height: 260; radius: 44 }

    // The same bodies across colour, type and the shipped material.
    Bare { ui: style; x: 60; y: 400; width: 620; height: 150 }
    Bare { ui: style; x: 730; y: 520; width: 520; height: 56; radius: 28 }
    Glass { ui: style; x: 1290; y: 400; width: 250; height: 300 }
    Bare { ui: style; x: 240; y: 640; width: 520; height: 56; radius: 28 }
    Bare { ui: style; x: 820; y: 630; width: 110; height: 110; radius: 55 }
    Glass { ui: style; x: 300; y: 770; width: 700; height: 100 }
}
