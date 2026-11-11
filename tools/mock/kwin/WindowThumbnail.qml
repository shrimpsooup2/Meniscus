import QtQuick
import org.kde.kwin as KWin

// Stand-in for KWin's WindowThumbnail: paints something that looks enough
// like an application for the glass to have detail to bend.
Item {
    id: thumb

    property string wId
    property var client: null

    readonly property var window: client ? client : KWin.Workspace.mockWindow(wId)
    readonly property string kind: window ? window.mockKind : ""
    readonly property bool framed: window !== null && !window.noBorder && !window.dock
    readonly property color paper: window ? window.mockColor : "#808080"
    readonly property bool dark: paper.hslLightness < 0.5
    readonly property color ink: dark ? "#e6e9ef" : "#22262b"
    readonly property color soft: dark ? "#8b93a5" : "#6c737d"
    readonly property string mono: "Consolas"

    implicitWidth: window ? window.width : 0
    implicitHeight: window ? window.height : 0

    function noise(i) {
        const v = Math.sin(i * 127.1 + 311.7) * 43758.5453
        return v - Math.floor(v)
    }

    Rectangle {
        anchors.fill: parent
        radius: thumb.framed ? 10 : 0
        color: thumb.paper
        border.width: thumb.framed ? 1 : 0
        border.color: Qt.rgba(0, 0, 0, 0.35)
        clip: true

        Rectangle {
            id: bar
            visible: thumb.framed
            width: parent.width
            height: visible ? 34 : 0
            topLeftRadius: 10
            topRightRadius: 10
            color: thumb.dark ? "#2a2d36" : "#dfe2e7"

            Text {
                anchors.centerIn: parent
                text: thumb.window ? thumb.window.caption : ""
                color: thumb.ink
                font.pixelSize: 13
            }
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                Repeater {
                    model: ["#8a8f98", "#8a8f98", "#e5534b"]
                    Rectangle { width: 12; height: 12; radius: 6; color: modelData }
                }
            }
        }

        Loader {
            anchors.top: bar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            sourceComponent: thumb.kind === "browser" ? browser
                           : thumb.kind === "editor" ? editor
                           : thumb.kind === "terminal" ? terminal
                           : thumb.kind === "files" ? files
                           : thumb.kind === "player" ? player
                           : thumb.kind === "panel" ? panel : page
        }
    }

    Component {
        id: browser
        Item {
            Rectangle {
                width: parent.width
                height: 44
                color: "#f6f7f9"
                Row {
                    x: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12
                    Repeater {
                        model: 3
                        Rectangle { width: 16; height: 16; radius: 8; color: "#c4c9d0" }
                    }
                }
                Rectangle {
                    x: 104
                    y: 8
                    width: parent.width - 208
                    height: 28
                    radius: 14
                    color: "#e3e6ea"
                    Text {
                        x: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: "https://fieldnotes.example/light-through-water"
                        color: "#4a5058"
                        font.pixelSize: 12
                    }
                }
            }
            Column {
                id: article
                x: Math.max(40, (parent.width - width) / 2)
                y: 76
                width: Math.min(parent.width - 80, 760)
                spacing: 16
                Text {
                    text: "Light through water"
                    color: "#16191d"
                    font.pixelSize: 34
                    font.weight: Font.Bold
                }
                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    color: "#3a4048"
                    font.pixelSize: 15
                    lineHeight: 1.35
                    text: "Where a liquid meets its container the surface curves. That curve, the meniscus, "
                        + "is a lens: it gathers what lies behind it, bends it towards the rim and returns it "
                        + "brighter, tighter and very slightly coloured at the edges."
                }
                Row {
                    spacing: 16
                    Repeater {
                        model: [["#f97316", "#facc15"], ["#0ea5e9", "#22d3ee"], ["#a855f7", "#ec4899"]]
                        Rectangle {
                            width: (article.width - 32) / 3
                            height: 150
                            radius: 10
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: modelData[0] }
                                GradientStop { position: 1; color: modelData[1] }
                            }
                        }
                    }
                }
                Repeater {
                    model: 3
                    Text {
                        width: article.width
                        wrapMode: Text.WordWrap
                        color: "#3a4048"
                        font.pixelSize: 15
                        lineHeight: 1.35
                        text: "Glass does the same on a smaller scale. A thick pane with a rounded edge shows "
                            + "the world straight through its middle and folded over at its border, and when the "
                            + "pane moves the picture inside it slides the other way. Nothing is painted on: "
                            + "everything you see in it is somewhere else, relocated."
                    }
                }
            }
        }
    }

    Component {
        id: editor
        Item {
            id: code
            readonly property var lines: [
                "float field(vec2 p)", "{", "    float k = max(smoothK, 0.001);",
                "    float d = sdShape(p, rectA, radii.x);", "    d = smin(d, sdShape(p, rectB, radii.y), k);",
                "    d = smin(d, sdShape(p, rectC, radii.z), k);", "    return d;", "}", "",
                "// Convex bezel: a ray crossing it is bent with Snell's law.",
                "vec2 ray = refract(vec2(0.0, -1.0), nrm, 1.0 / ior);",
                "float shift = ray.x / max(-ray.y, 0.05) * depth;", "",
                "col.r = texture(source, (q + bend * (1.0 - split)) * inv).r;",
                "col.g = texture(source, uv).g;", "col.b = texture(source, (q + bend * (1.0 + split)) * inv).b;", ""]
            readonly property var inks: ["#c792ea", "#e6e9ef", "#82aaff", "#c3e88d", "#ffcb6b", "#89ddff"]
            Rectangle { width: 56; height: parent.height; color: Qt.darker(thumb.paper, 1.25) }
            Column {
                x: 12
                y: 12
                Repeater {
                    model: Math.max(0, Math.floor((code.height - 24) / 21))
                    Row {
                        height: 21
                        spacing: 22
                        Text {
                            width: 28
                            horizontalAlignment: Text.AlignRight
                            text: index + 1
                            color: "#5b6078"
                            font.family: thumb.mono
                            font.pixelSize: 13
                        }
                        Text {
                            text: code.lines[index % code.lines.length]
                            color: code.inks[Math.floor(thumb.noise(index) * code.inks.length)]
                            font.family: thumb.mono
                            font.pixelSize: 13
                        }
                    }
                }
            }
        }
    }

    Component {
        id: terminal
        Item {
            id: shell
            readonly property var lines: [
                "$ ./install.sh", "Meniscus 1.0 for KWin 6", "  effects   -> ~/.local/share/kwin/effects",
                "  schemes   -> ~/.local/share/color-schemes", "  wallpapers-> ~/.local/share/wallpapers",
                "  helper    -> ~/.local/bin/meniscusctl", "done. Meta+Space to begin.", "$ meniscusctl theme tide",
                "$ meniscusctl doctor", "ok  kwin 6.8.2", "ok  qsb-qt6", "ok  shortcuts free", "$ "]
            Column {
                x: 14
                y: 12
                Repeater {
                    model: Math.min(shell.lines.length, Math.max(0, Math.floor((shell.height - 24) / 21)))
                    Text {
                        height: 21
                        text: shell.lines[index]
                        color: text.startsWith("$") ? "#7ee787" : text.startsWith("ok") ? "#79c0ff" : "#d6dbe4"
                        font.family: thumb.mono
                        font.pixelSize: 13
                    }
                }
            }
        }
    }

    Component {
        id: files
        Item {
            id: folder
            Rectangle {
                width: 180
                height: parent.height
                color: "#e9ebef"
                Column {
                    x: 16
                    y: 16
                    spacing: 14
                    Repeater {
                        model: ["Home", "Desktop", "Documents", "Downloads", "Music", "Pictures", "Videos", "Trash"]
                        Text { text: modelData; color: "#2f353c"; font.pixelSize: 13 }
                    }
                }
            }
            Grid {
                x: 204
                y: 22
                columns: Math.max(1, Math.floor((folder.width - 220) / 118))
                spacing: 22
                Repeater {
                    model: 24
                    Column {
                        width: 96
                        spacing: 6
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 64
                            height: 52
                            radius: 8
                            color: Qt.hsla(0.56 + 0.1 * thumb.noise(index), 0.7, 0.58, 1)
                        }
                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: ["Projects", "Notes", "Renders", "Scans", "Archive", "Themes"][index % 6] + " " + (index + 1)
                            color: "#2f353c"
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }

    Component {
        id: player
        Item {
            Rectangle {
                id: art
                x: 28
                y: 28
                width: Math.min(parent.height - 56, parent.width * 0.4)
                height: width
                radius: 14
                gradient: Gradient {
                    GradientStop { position: 0; color: "#fb7185" }
                    GradientStop { position: 1; color: "#7c3aed" }
                }
            }
            Column {
                x: art.x + art.width + 28
                y: 40
                spacing: 10
                Text { text: "Surface Tension"; color: "#f3f0fa"; font.pixelSize: 26; font.weight: Font.Bold }
                Text { text: "The Capillaries"; color: "#a79fc0"; font.pixelSize: 15 }
                Repeater {
                    model: ["Meniscus", "Clear Water", "Refraction", "Caustics", "Still", "Overflow"]
                    Text { text: (index + 1) + "   " + modelData; color: index === 2 ? "#fb7185" : "#d9d3ea"; font.pixelSize: 14 }
                }
            }
        }
    }

    Component {
        id: panel
        Item {
            Row {
                x: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                Repeater {
                    model: ["#3daee9", "#f67400", "#27ae60", "#9b59b6", "#e74c3c", "#f1c40f"]
                    Rectangle { width: parent.parent.height - 14; height: width; radius: 7; color: modelData }
                }
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: "14:32"
                color: "#e6e9ef"
                font.pixelSize: 14
            }
        }
    }

    Component {
        id: page
        Item {
            id: sheet
            Column {
                x: 40
                y: 32
                spacing: 12
                Repeater {
                    model: Math.max(0, Math.floor((sheet.height - 64) / 22))
                    Rectangle {
                        width: (sheet.width - 80) * (0.45 + 0.55 * thumb.noise(index))
                        height: 10
                        radius: 5
                        color: index % 7 === 0 ? thumb.ink : thumb.soft
                        opacity: index % 7 === 0 ? 0.85 : 0.45
                    }
                }
            }
        }
    }
}
