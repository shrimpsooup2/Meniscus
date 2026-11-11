import QtQuick
import ".."

// python tools/preview.py glasscard --root tools/preview/GlassCard.qml
Runner {
    steps: [
        [500, () => harness.shot("glasscard")]
    ]
}
