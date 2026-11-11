import QtQuick
import "LiquidGlass"
import "LiquidGlass/material.js" as Material

// A piece of Liquid Glass with its children on top. The material is the one measured against
// iOS by shayann07/liquidglass (LiquidGlass/, Apache-2.0); this hosts it over a live copy of the
// backdrop, applies the user's settings and the theme's tint, and adds `fuse`: a second rounded
// rect merged into the outline through a liquid neck, which is how panels pull away from the
// screen border. Falls back to a flat plate when the glass is off or its shader cannot run.
Item {
    id: glass

    required property Style ui
    property Item backdrop: ui.backdrop         // what the glass bends; keep the glass outside it
    property real radius: ui.radius
    property real tintAmount: ui.tint           // 0..100, the measured material's tint scale
    property color tintColor: ui.glassTint      // alpha 0: the measured neutral grey
    property real materialize: 1                // 0..1: glass forms out of its lensing, not alpha
    property real shadow: ui.shadow             // 0..1
    property rect fuse: Qt.rect(0, 0, 0, 0)     // this item's coordinates; may lie outside it
    property real fuseRadius: 0
    property real fuseReach: 0                  // smoothing of the neck; it parts at a gap of half this
    property bool followsMovement: false        // set while an ancestor moves the glass
    default property alias content: contentItem.data

    readonly property bool liquid: effect.visible
    readonly property real dpr: ui.dpr
    readonly property bool fused: fuseReach > 0 && fuse.width > 0 && fuse.height > 0

    // The layer the shader draws: the body, two device pixels for its outer contour, and room for
    // the fuse and the bulge of its neck. The shader places the body `lead` in from the layer's
    // top-left on both axes, so those two sides grow together.
    readonly property real pad: 2 / dpr
    readonly property real bulge: fused ? fuseReach / 4 + pad : pad
    readonly property real lead: fused ? Math.max(pad, bulge - fuse.x, bulge - fuse.y) : pad
    readonly property real trailX: fused ? Math.max(pad, fuse.x + fuse.width - width + bulge) : pad
    readonly property real trailY: fused ? Math.max(pad, fuse.y + fuse.height - height + bulge) : pad

    readonly property var material: {
        if (width <= 0 || height <= 0)
            return null
        const t = Math.max(0, Math.min(100, tintAmount))
        const tint = tintColor.a <= 0 ? null : [tintColor.r, tintColor.g, tintColor.b,
            Material.interpolate(ui.dark ? Material.DARK_OPACITY : Material.LIGHT_OPACITY, t)]
        const v = Material.uniforms({
            radius: radius, dark: ui.dark, tintAmount: t, tint: tint, materialize: materialize,
            reducedTransparency: ui.reduceTransparency ? 1 : 0,
            increasedContrast: ui.increaseContrast ? 1 : 0,
        }, width * dpr, height * dpr, dpr)
        v.uRefractGain = [ui.refraction]
        v.uRefractBand[0] *= ui.curvature     // the width of the curved rim, and so its bend
        v.uBevel[0] *= ui.curvature           // and of the light it catches
        v.uBlur[0] *= ui.frost
        v.uSpecular[0] *= ui.highlights
        v.uAberration[0] *= ui.dispersion
        v.uBase = [ui.plate.r, ui.plate.g, ui.plate.b]
        delete v.uPad   // bound on the effect: it grows with the fuse
        return v
    }
    onMaterialChanged: if (material) effect.setUniforms(material)

    function place() {
        if (!backdrop)
            return
        const r = backdrop.mapFromItem(glass, effect.x, effect.y, effect.width, effect.height)
        const s = backdropTexture.sourceRect
        if (r.x !== s.x || r.y !== s.y || r.width !== s.width || r.height !== s.height)
            backdropTexture.sourceRect = r
    }
    onXChanged: place()
    onYChanged: place()
    onWidthChanged: place()
    onHeightChanged: place()
    onLeadChanged: place()
    onTrailXChanged: place()
    onTrailYChanged: place()
    onBackdropChanged: place()
    Component.onCompleted: {
        place()
        if (material)
            effect.setUniforms(material)
    }
    Connections {
        target: glass.backdrop
        function onXChanged() { glass.place() }
        function onYChanged() { glass.place() }
        function onWidthChanged() { glass.place() }
        function onHeightChanged() { glass.place() }
    }
    FrameAnimation {
        running: glass.followsMovement && glass.visible && glass.liquid
        onTriggered: glass.place()
    }

    Loader {
        // RectangularShadow arrived in Qt 6.9; on older Qt this fails and the glass has none.
        anchors.fill: parent
        z: -1
        active: glass.shadow > 0
        Component.onCompleted: setSource(Qt.resolvedUrl("GlassShadow.qml"), { glass: glass })
    }

    ShaderEffectSource {
        id: backdropTexture
        sourceItem: effect.visible ? glass.backdrop : null
        live: glass.ui.liveBackdrop
        hideSource: false
        visible: false
        smooth: true
        mipmap: true    // the shader's wide taps read prefiltered levels (backdropSoftAt)
        textureSize: Qt.size(Math.ceil(effect.width * glass.dpr), Math.ceil(effect.height * glass.dpr))
    }

    GlassEffect {
        id: effect
        x: -glass.lead
        y: -glass.lead
        width: glass.lead + glass.width + glass.trailX
        height: glass.lead + glass.height + glass.trailY
        visible: glass.ui.glass && glass.backdrop !== null && status !== ShaderEffect.Error
                 && glass.width > 0 && glass.height > 0
        source: backdropTexture
        field: backdropTexture      // the shape is analytic; the field is bound but unread
        uLayerSize: Qt.point(width * glass.dpr, height * glass.dpr)
        uPad: glass.lead * glass.dpr
        uFuse: glass.fused
               ? Qt.vector4d((glass.fuse.x + (glass.fuse.width - glass.width) / 2) * glass.dpr,
                             (glass.fuse.y + (glass.fuse.height - glass.height) / 2) * glass.dpr,
                             glass.fuse.width / 2 * glass.dpr, glass.fuse.height / 2 * glass.dpr)
               : Qt.vector4d(0, 0, 0, 0)
        uFuseShape: Qt.point(Math.min(glass.fuseRadius, glass.fuse.width / 2, glass.fuse.height / 2) * glass.dpr,
                             glass.fused ? glass.fuseReach * glass.dpr : 0)
    }

    Rectangle {
        anchors.fill: parent
        visible: !effect.visible && width > 0 && height > 0
        radius: Math.min(glass.radius, width / 2, height / 2)
        color: Qt.rgba(glass.ui.plate.r, glass.ui.plate.g, glass.ui.plate.b, 0.92 * glass.materialize)
        border.width: 1
        border.color: glass.ui.line
    }

    Item {
        id: contentItem
        anchors.fill: parent
    }
}
