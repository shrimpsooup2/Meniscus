import QtQuick
import org.kde.kwin as KWin
import "../../package/effects/meniscus/contents/ui"

// Test card for the glass material on its own: no shell, just samples.
Item {
    id: lab

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
        id: style
        config: KWin.Workspace.mockConfig
        backdrop: scene
    }

    component Sample: Glass {
        property string label
        Text {
            x: 18
            y: 14
            text: label
            color: ui.ink
            font.pixelSize: ui.textBody
            font.weight: Font.DemiBold
        }
    }

    Sample { ui: style; x: 70; y: 70; width: 420; height: 250; label: "neutral, tint 0"; tintAmount: 0; tintColor: "transparent" }
    Sample { ui: style; x: 530; y: 70; width: 420; height: 250; label: "theme, tint " + style.tint + " (setting)" }
    Sample { ui: style; x: 990; y: 70; width: 520; height: 56; radius: 28; label: "capsule" }
    Sample { ui: style; x: 990; y: 160; width: 150; height: 150; radius: 75; label: "lens"; tintAmount: 0; tintColor: "transparent" }
    Sample { ui: style; x: 1180; y: 160; width: 330; height: 150; label: "neutral, tint " + style.tint; tintColor: "transparent" }
    Sample { ui: style; x: 70; y: 360; width: 880; height: 150; label: "theme tint 100"; tintAmount: 100 }
}
