import QtQuick
import QtQml.Models
import org.kde.kwin as KWin
import "apps.js" as Apps

// Meniscus: one glass surface at a time over the desktop, opened with a key or a hot corner and
// put away once it has done its job. The state lives here rather than in the views, because KWin
// builds a Shell for every screen each time the effect starts and drops them when it stops.
KWin.SceneEffect {
    id: effect

    // What is up: palette, tray, controls, modes, deck, settings or keymap; "" for nothing.
    property string surface: ""
    // The screen it is up on, by name. The other screens show their desktop and nothing more.
    property string screen: ""
    // Opened, or moved on, with Meta down, and Meta not let go of since.
    property bool held: false
    // The highlight was moved with Meta down (Meta+Tab again, Meta+M again).
    property bool moved: false
    property double openedAt: 0
    // Sheets on screen across the views; the effect stops once the last one has gone.
    property int present: 0
    property var stamps: ({})

    readonly property bool full: configuration.Edition !== "flow"
    readonly property var trayApps: Apps.parse(configuration.TrayApps)
    // Tab walks the surfaces in this order.
    readonly property var order: ["palette", "tray"]
    readonly property System system: System {}

    // Move a surface's highlight; Meta+Tab and Meta+M step it while their surface is up.
    signal advance(string surface, int step)
    // Take a surface's highlighted choice: Meta was let go after moving it (HoldToCommit).
    signal commit(string surface)

    function available(name) {
        return order.indexOf(name) >= 0 && (name !== "tray" || configuration.Tray) && (name !== "deck" || full)
    }

    // `how` is "key" (Meta is down), "corner" (the pointer is in it) or "tab" (from another surface).
    function open(name, how) {
        if (!available(name))
            return
        if (how === "corner") {
            const at = KWin.Workspace.screenAt(KWin.Workspace.cursorPos)
            screen = at ? at.name : ""
        } else if (how !== "tab" || !visible) {
            const active = KWin.Workspace.activeScreen
            screen = active ? active.name : ""
        }
        surface = name
        held = how === "key"
        moved = false
        visible = true
        openedAt = Date.now()
    }

    function close() {
        surface = ""
        held = false
        moved = false
        settle()
    }

    // The sheets call this as they go; the views go once nothing is left on screen.
    function settle() {
        if (present <= 0 && surface === "")
            visible = false
    }

    function toggle(name, how) {
        if (surface === name)
            close()
        else
            open(name, how)
    }

    function corner(name) {
        toggle(name, "corner")
    }

    function cycle(step) {
        let at = order.indexOf(surface)
        for (let i = 0; i < order.length; ++i) {
            at = (at + step + order.length) % order.length
            if (available(order[at]))
                return open(order[at], "tab")
        }
    }

    // Meta+Tab or Meta+M again: open the surface, or step its highlight if it is up.
    function step(name) {
        if (surface !== name)
            return open(name, "key")
        held = true
        moved = true
        advance(name, 1)
    }

    // KWin repeats a shortcut's action while its key is held. `action(fresh)` runs on every
    // activation; `fresh` is a new press: a key has gone up since the last one, or the last one is
    // older than a repeat would be. The time is taken after the action, which may have blocked.
    function press(name, action) {
        action(Date.now() - (stamps[name] || 0) > 700)
        stamps[name] = Date.now()
    }

    // Every key a view sees going up. Letting go of Meta ends a peek at the tray (a tap leaves it
    // up) and, with HoldToCommit, takes the deck's choice or one moved to with Meta down.
    function keyUp(key) {
        stamps = ({})
        if (!held || key !== Qt.Key_Super_L && key !== Qt.Key_Super_R && key !== Qt.Key_Meta)
            return
        held = false
        if (surface === "tray") {
            if (Date.now() - openedAt > 300)
                close()
        } else if (configuration.HoldToCommit && (moved || surface === "deck")) {
            commit(surface)
        }
    }

    // Tray slot 0 to 9 (keys 1 to 9, then 0): to the app's window if it is running, through its
    // windows on repeated use, otherwise started.
    function launch(slot) {
        const app = trayApps[slot]
        if (!configuration.Tray || !app || !app.id)
            return
        close()
        const windows = []
        const stack = KWin.Workspace.stackingOrder
        for (let i = stack.length - 1; i >= 0; --i) {
            const window = stack[i]
            if (window.desktopFileName === app.id && window.normalWindow && !window.deleted)
                windows.push(window)
        }
        if (windows.length === 0)
            system.ctl(["launch", app.id])
        else
            KWin.Workspace.activeWindow = windows[0].active ? windows[windows.length - 1] : windows[0]
    }

    // Writes one setting and saves it.
    function set(key, value) {
        configuration[key] = value
        configuration.writeConfig()
    }

    delegate: Shell {}

    KWin.ShortcutHandler {
        name: "Meniscus Palette"
        text: "Meniscus: Palette"
        sequence: "Meta+Space"
        onActivated: effect.press(name, fresh => { if (fresh) effect.toggle("palette", "key") })
    }
    KWin.ShortcutHandler {
        // Held: it stays up until Meta is let go. Tapped: until Meta+A again, Esc or a click.
        name: "Meniscus Tray"
        text: "Meniscus: Tray"
        sequence: "Meta+A"
        onActivated: effect.press(name, fresh => {
            if (effect.surface !== "tray")
                effect.open("tray", "key")
            else if (fresh && !effect.held)
                effect.close()
        })
    }
    Instantiator {
        model: 10
        delegate: KWin.ShortcutHandler {
            required property int index
            name: "Meniscus Tray App " + (index + 1)
            text: "Meniscus: Tray app " + (index + 1)
            sequence: "Meta+" + Apps.key(index)
            onActivated: effect.press(name, fresh => { if (fresh) effect.launch(index) })
        }
    }
    KWin.ShortcutHandler {
        name: "Meniscus Controls"
        text: "Meniscus: Controls"
        sequence: "Meta+C"
        onActivated: effect.press(name, fresh => { if (fresh) effect.toggle("controls", "key") })
    }
    KWin.ShortcutHandler {
        name: "Meniscus Modes"
        text: "Meniscus: Modes"
        sequence: "Meta+M"
        onActivated: effect.press(name, fresh => { if (fresh) effect.step("modes") })
    }
    KWin.ShortcutHandler {
        name: "Meniscus Keymap"
        text: "Meniscus: Keymap"
        sequence: "Meta+K"
        onActivated: effect.press(name, fresh => { if (fresh) effect.toggle("keymap", "key") })
    }
    KWin.ShortcutHandler {
        name: "Meniscus Deck"
        text: "Meniscus: Deck"
        sequence: "Meta+Tab"
        onActivated: effect.press(name, fresh => { if (fresh) effect.step("deck") })
    }

    KWin.ScreenEdgeHandler {
        edge: KWin.ScreenEdgeHandler.TopLeftEdge
        enabled: effect.configuration.HotCorners && effect.configuration.CornerTopLeft !== "none"
        onActivated: effect.corner(effect.configuration.CornerTopLeft)
    }
    KWin.ScreenEdgeHandler {
        edge: KWin.ScreenEdgeHandler.TopRightEdge
        enabled: effect.configuration.HotCorners && effect.configuration.CornerTopRight !== "none"
        onActivated: effect.corner(effect.configuration.CornerTopRight)
    }
    KWin.ScreenEdgeHandler {
        edge: KWin.ScreenEdgeHandler.BottomLeftEdge
        enabled: effect.configuration.HotCorners && effect.configuration.CornerBottomLeft !== "none"
        onActivated: effect.corner(effect.configuration.CornerBottomLeft)
    }
    KWin.ScreenEdgeHandler {
        edge: KWin.ScreenEdgeHandler.BottomRightEdge
        enabled: effect.configuration.HotCorners && effect.configuration.CornerBottomRight !== "none"
        onActivated: effect.corner(effect.configuration.CornerBottomRight)
    }
}
