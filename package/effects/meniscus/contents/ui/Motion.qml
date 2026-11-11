import QtQuick

// Motion blur for a layer: streaks it along `velocity`, given in the layer's texture coordinates.
// At zero it is a plain copy.
ShaderEffect {
    property vector2d velocity: Qt.vector2d(0, 0)
    fragmentShader: Qt.resolvedUrl("../shaders/motion.frag.qsb")
}
