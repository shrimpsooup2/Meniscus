import QtQuick
import ".."

// python tools/preview.py knobs --root tools/preview/KnobLab.qml --size 800x500
// A tap, a drag and arrow keys on the lab's toggles and sliders, shot through each motion.
Runner {
    id: run

    property point p

    function expect(what, value, wanted) {
        if (value !== wanted)
            throw new Error(what + " is " + value + ", wanted " + wanted)
    }

    // Where a slider's knob is, in window coordinates.
    function knobOf(slider) {
        return effect.spot(slider, slider.knobWidth / 2 + slider.shown * slider.travel - slider.width / 2)
    }

    steps: [
        [700, () => harness.shot("knobs_rest")],

        // Tap Night Light: the knob swells into glass, slides over, settles white.
        [10, () => {
            run.p = effect.spot(effect.nightToggle, -12)
            harness.move(run.p.x, run.p.y)
            harness.press(run.p.x, run.p.y)
        }],
        [50, () => harness.shot("tap_1_press50")],
        [120, () => harness.shot("tap_2_press170")],
        [1, () => harness.release(run.p.x, run.p.y)],
        [40, () => harness.shot("tap_3_release40")],
        [50, () => harness.shot("tap_4_release90")],
        [50, () => harness.shot("tap_5_release140")],
        [80, () => harness.shot("tap_6_release220")],
        [100, () => harness.shot("tap_7_release320")],
        [250, () => {
            harness.shot("tap_8_release570")
            run.expect("night", effect.night, true)
        }],

        // Drag the volume knob right and let go.
        [100, () => {
            run.p = run.knobOf(effect.volumeSlider)
            harness.move(run.p.x, run.p.y)
            harness.press(run.p.x, run.p.y)
        }],
        [150, () => harness.drag(run.p.x + 20, run.p.y)],
        [30, () => harness.drag(run.p.x + 40, run.p.y)],
        [30, () => harness.drag(run.p.x + 60, run.p.y)],
        [10, () => harness.shot("drag_1_moving")],
        [30, () => harness.drag(run.p.x + 70, run.p.y)],
        [150, () => harness.shot("drag_2_held")],
        [1, () => harness.release(run.p.x + 70, run.p.y)],
        [80, () => harness.shot("drag_3_release80")],
        [150, () => harness.shot("drag_4_release230")],
        [400, () => {
            harness.shot("drag_5_release630")
            run.expect("volume above 40", effect.volume > 40, true)
        }],

        // Arrow keys on brightness: each step glides, the knob stays glass between them.
        [50, () => {
            effect.brightnessSlider.forceActiveFocus()
            harness.key("Right")
        }],
        [60, () => harness.key("Right")],
        [60, () => harness.key("Right")],
        [60, () => harness.shot("keys_1_stepping")],
        [900, () => {
            harness.shot("keys_2_settled")
            run.expect("brightness", effect.brightness, 85)
        }],

        // Drag Wi-Fi's knob past half way to the left: it turns off where it is let go.
        [50, () => {
            run.p = effect.spot(effect.wifiToggle, 10)
            harness.move(run.p.x, run.p.y)
            harness.press(run.p.x, run.p.y)
        }],
        [100, () => harness.drag(run.p.x - 8, run.p.y)],
        [30, () => harness.drag(run.p.x - 16, run.p.y)],
        [30, () => harness.shot("wifi_1_dragging")],
        [1, () => harness.release(run.p.x - 16, run.p.y)],
        [600, () => {
            harness.shot("wifi_2_off")
            run.expect("wifi", effect.wifi, false)
        }]
    ]
}
