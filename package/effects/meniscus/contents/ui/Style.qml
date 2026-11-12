import QtQuick
import org.kde.kirigami as Kirigami
import "themes.js" as Themes
import "apps.js" as Apps

// The one place that knows how Meniscus looks and moves: the user's settings,
// the palette of the active theme, sizes and timing. One per screen, handed to
// every component as `ui`.
Item {
    id: ui

    required property var config            // the effect's configuration map
    property Item backdrop: null            // the scene the glass bends
    property real dpr: Screen.devicePixelRatio > 0 ? Screen.devicePixelRatio : 1

    // ---- glass -----------------------------------------------------------
    // Scales are 1 at the measured iOS material.
    readonly property bool glass: config.Glass
    readonly property real tint: config.Tint                 // 0..100
    readonly property bool themeTint: config.ThemeTint
    readonly property real refraction: config.Refraction / 100
    readonly property real curvature: config.Curvature / 100
    readonly property real frost: config.Frost / 100
    readonly property real highlights: config.Highlights / 100
    readonly property real dispersion: config.Dispersion / 100
    readonly property real shadow: config.Shadow / 100
    readonly property bool reduceTransparency: config.ReduceTransparency
    readonly property bool increaseContrast: config.IncreaseContrast
    readonly property bool liveBackdrop: config.LiveBackdrop

    // ---- motion ----------------------------------------------------------
    readonly property bool pull: config.Pull
    readonly property real stretch: config.PullStretch / 100
    readonly property real bounce: config.Bounce / 100
    readonly property bool morphBlur: config.MorphBlur
    readonly property bool motionBlur: config.MotionBlur
    readonly property real blurStrength: config.MotionBlurStrength / 100
    readonly property real pace: 100 / Math.max(25, config.Speed)   // duration multiplier
    readonly property int quick: Math.round(130 * pace)
    readonly property int brisk: Math.round(220 * pace)
    readonly property int calm: Math.round(380 * pace)
    readonly property int slow: Math.round(620 * pace)
    // Leaves fast, lands softly.
    readonly property var glide: [0.2, 0.0, 0.0, 1.0, 1.0, 1.0]

    readonly property bool beads: config.Beads
    readonly property bool full: config.Edition !== "flow"
    readonly property bool tray: config.Tray
    // Tray slots in order, 1 to 9 then 0, as {id, icon}; an empty id is an empty slot.
    readonly property var trayApps: Apps.parse(config.TrayApps)

    // ---- palette ---------------------------------------------------------
    readonly property bool system: config.Theme === "system"
    readonly property var theme: Themes.find(config.Theme)
    readonly property color plate: system ? Kirigami.Theme.backgroundColor : theme.plate
    readonly property color ink: system ? Kirigami.Theme.textColor : theme.ink
    readonly property color accent: system ? Kirigami.Theme.highlightColor : theme.accent
    readonly property color accentInk: system ? Kirigami.Theme.highlightedTextColor : theme.accentInk
    readonly property bool dark: system ? 0.2126 * plate.r + 0.7152 * plate.g + 0.0722 * plate.b < 0.5 : theme.dark
    readonly property color dim: Qt.rgba(ink.r, ink.g, ink.b, 0.62)
    readonly property color faint: Qt.rgba(ink.r, ink.g, ink.b, 0.10)
    readonly property color line: Qt.rgba(ink.r, ink.g, ink.b, 0.16)
    // The glass takes the theme's colour, deepened: its hue at twice the plate's saturation, so
    // it reads as coloured glass rather than grey. Transparent leaves the measured neutral grey.
    readonly property color glassTint: !themeTint ? "transparent"
        : plate.hslHue < 0 ? plate
        : Qt.hsla(plate.hslHue, Math.min(1, 2 * plate.hslSaturation), plate.hslLightness, 1)

    // ---- metrics ---------------------------------------------------------
    readonly property real gap: 8
    readonly property real pad: 16
    readonly property real row: 46
    readonly property real radius: 26
    readonly property real edgeMargin: 18       // distance kept between a panel and the screen border
    readonly property int textSmall: 12
    readonly property int textBody: 14
    readonly property int textTitle: 17
}
