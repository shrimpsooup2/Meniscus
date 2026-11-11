import QtQuick
import ".."

// python tools/preview.py glassgrid --root tools/preview/GlassGrid.qml
Runner {
    steps: [
        [600, () => harness.shot("glassgrid")]
    ]
}
