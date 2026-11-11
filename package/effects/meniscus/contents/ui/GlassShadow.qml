import QtQuick
import QtQuick.Effects

// The soft shadow under a piece of glass. A file of its own so Glass still loads on Qt older
// than 6.9, which has no RectangularShadow: there the loader fails and the glass goes without.
// Bigger glass is thicker, so its shadow falls deeper and softer.
RectangularShadow {
    required property Glass glass
    readonly property real size: Math.min(width, height)

    anchors.fill: parent
    radius: Math.min(glass.radius, width / 2, height / 2)
    offset: Qt.vector2d(0, 4 + 0.03 * size)
    blur: 14 + 0.08 * size
    color: Qt.rgba(0, 0, 0, (glass.ui.dark ? 0.5 : 0.28) * glass.shadow * glass.materialize)
}
