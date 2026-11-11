import QtQuick
import org.kde.kwin as KWin
import "../../package/effects/meniscus/contents/ui"

// Side by side with Apple: the stripes of shayann07/liquidglass's rest-toolbar reference, a
// Photos-style capsule and round button over them at 3x, and the reference itself on the right
// (top row real iOS 27, the rows under it the port's own renders).
// Rows: dark neutral, light neutral, amethyst default, dune default.
Item {
    id: lab

    function conf(over) {
        const c = KWin.Workspace.mockConfig
        const o = {}
        for (const k of ["Glass", "Tint", "ThemeTint", "Refraction", "Frost", "Highlights", "Dispersion",
                         "Shadow", "ReduceTransparency", "IncreaseContrast", "LiveBackdrop", "Pull",
                         "PullStretch", "MotionBlur", "MotionBlurStrength", "Speed", "Beads", "Edition", "Theme"])
            o[k] = c[k]
        return Object.assign(o, over)
    }

    Rectangle { anchors.fill: parent; color: "#808080" }

    // Points; drawn at 3x like an iPhone.
    component Strip: Item {
        id: strip
        required property var over
        width: 260
        height: 57

        Item {
            id: scene
            anchors.fill: parent
            clip: true
            Rectangle { anchors.fill: parent; color: "white" }
            Repeater {
                model: 130
                Rectangle { required property int index; x: index * 2; width: 1; height: 17; color: "black" }
            }
            Repeater {
                model: 26
                Rectangle { required property int index; x: index * 31 / 3 + 5; y: 17; width: 16 / 3; height: 27; color: "black" }
            }
            Rectangle { y: 44; width: parent.width; height: 6; color: "black" }
            Text { x: 1; y: 47; text: "yes 0123456789 quick brown fox"; font.pixelSize: 12; color: "black" }
        }
        Style {
            id: style
            config: lab.conf(strip.over)
            backdrop: scene
            dpr: 3
        }
        Glass { ui: style; x: 7.5; y: 5; width: 162; height: 47; radius: 23.5 }
        Glass { ui: style; x: 207; y: 5; width: 48; height: 47; radius: 23.5 }
    }

    Item {
        scale: 3
        transformOrigin: Item.TopLeft
        Strip { y: 0; over: ({ Theme: "amethyst", ThemeTint: false, Tint: 50 }) }
        Strip { y: 60; over: ({ Theme: "dune", ThemeTint: false, Tint: 50 }) }
        Strip { y: 120; over: ({ Theme: "amethyst", ThemeTint: true, Tint: 50 }) }
        Strip { y: 180; over: ({ Theme: "dune", ThemeTint: true, Tint: 50 }) }
    }

    Image {
        x: 800
        width: 780
        height: 530
        source: Qt.resolvedUrl("../../.scratch/ref/grid/rest-toolbar.png")
        smooth: true
    }
}
