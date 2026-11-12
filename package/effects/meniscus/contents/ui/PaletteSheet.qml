import QtQuick
import org.kde.milou as Milou
import "apps.js" as Apps
import "themes.js" as Themes

// The palette: type for an app, a file, a setting or one of Meniscus's own commands. Enter runs
// the highlighted row, Up and Down move it, Ctrl and a number pins its app to that tray slot.
Sheet {
    id: finder

    readonly property real span: 640
    readonly property int most: 6               // rows at once
    property int current: 0
    property real fit: list.implicitHeight

    // Meniscus's own, found by any word of `name` or `words`.
    readonly property var commands: {
        const effect = shell
        const act = what => () => { effect.system.act(what); effect.close() }
        const surfaces = [
            { surface: "tray", name: "Tray", sub: "Your ten apps", icon: "view-app-grid", keys: ["Meta", "A"] },
            { surface: "controls", name: "Controls", sub: "Media, sound, light, theme and power",
              icon: "preferences-system", keys: ["Meta", "C"], words: "volume brightness media" },
            { surface: "modes", name: "Modes", sub: "Switch modes, or send a window to one", icon: "virtual-desktops",
              keys: ["Meta", "M"], words: "desktops workspaces" },
            { surface: "keymap", name: "Keymap", sub: "See and change every key", icon: "input-keyboard",
              keys: ["Meta", "K"], words: "shortcuts keys binds" },
            { surface: "settings", name: "Meniscus Settings", sub: "Glass, motion, corners and windows",
              icon: "configure", keys: [], words: "preferences options" },
            { surface: "deck", name: "Deck", sub: "Every open window", icon: "window", keys: ["Meta", "Tab"],
              words: "windows switch" },
        ]
        const list = surfaces.filter(command => effect.available(command.surface)).map(command =>
            Object.assign(command, { run: () => effect.open(command.surface, "tab") }))
        for (const theme of Themes.list)
            list.push({ name: "Theme: " + theme.name, sub: theme.dark ? "Dark theme" : "Light theme",
                        icon: "color-management", keys: [], words: "colour color",
                        run: () => { effect.set("Theme", theme.id); effect.close() } })
        list.push({ name: "Lock", sub: "Lock the screen", icon: "system-lock-screen", keys: [], run: act("lock") },
                  { name: "Sleep", sub: "Suspend to memory", icon: "system-suspend", keys: [], words: "suspend", run: act("sleep") },
                  { name: "Log Out", sub: "End the session", icon: "system-log-out", keys: [], words: "logout", run: act("logout") },
                  { name: "Restart", sub: "Reboot", icon: "system-reboot", keys: [], words: "reboot", run: act("restart") },
                  { name: "Shut Down", sub: "Power off", icon: "system-shutdown", keys: [], words: "shutdown power off", run: act("shutdown") })
        return list
    }
    readonly property var matched: {
        const needle = query.text.trim().toLowerCase()
        if (!needle)
            return []
        return commands.filter(command => (command.name + " " + (command.words || "")).toLowerCase()
                                   .split(/[\s:]+/).some(word => word.startsWith(needle))
                               || command.name.toLowerCase().startsWith(needle)).slice(0, 3)
    }
    readonly property int shownResults: Math.min(found.count, most - matched.length)
    readonly property int count: matched.length + shownResults

    side: "top"
    rest: Qt.rect((width - span) / 2, ui.edgeMargin, span, fit + 2 * ui.pad)

    Behavior on fit {
        NumberAnimation { duration: finder.ui.brisk; easing.type: Easing.OutCubic }
    }

    function move(step) {
        if (count > 0)
            current = (current + step + count) % count
    }
    function run(row) {
        if (row < 0 || row >= count)
            return
        if (row < matched.length)
            return matched[row].run()
        results.run(results.index(row - matched.length, 0))
        shell.close()
    }
    // The tray slot (0 to 9) holding this row's app, or -1.
    function slotOf(urls) {
        const id = urls && urls.length ? Apps.idOf(String(urls[0])) : ""
        return id ? shell.trayApps.findIndex(app => app.id === id) : -1
    }
    function pin(slot) {
        const row = found.itemAt(current - matched.length)
        const id = row && row.urls && row.urls.length ? Apps.idOf(String(row.urls[0])) : ""
        if (!id)
            return
        const apps = shell.trayApps.map(app => app.id === id ? { id: "", icon: "" } : app)
        apps[slot] = { id: id, icon: id }
        shell.set("TrayApps", Apps.format(apps))
    }

    onShownChanged: if (shown) {
        query.text = ""
        current = 0
    }
    onCountChanged: current = Math.min(current, Math.max(0, count - 1))

    Milou.ResultsModel {
        id: results
        queryString: query.text
        limit: finder.most
    }

    Column {
        id: list
        x: finder.ui.pad
        y: finder.ui.pad
        width: finder.span - 2 * finder.ui.pad
        spacing: finder.ui.gap

        Rectangle {
            width: parent.width
            height: finder.ui.row
            radius: height / 2
            color: finder.ui.faint

            Item {
                id: lens
                x: finder.ui.pad
                anchors.verticalCenter: parent.verticalCenter
                width: 18
                height: 18
                Rectangle {
                    width: 13
                    height: 13
                    radius: 6.5
                    color: "transparent"
                    border.width: 2
                    border.color: finder.ui.dim
                }
                Rectangle {
                    x: 11
                    y: 11
                    width: 8
                    height: 2.4
                    radius: 1.2
                    rotation: 45
                    transformOrigin: Item.Left
                    color: finder.ui.dim
                }
            }
            TextInput {
                id: query
                x: lens.x + lens.width + 12
                width: parent.width - x - finder.ui.pad
                anchors.verticalCenter: parent.verticalCenter
                focus: true
                clip: true
                color: finder.ui.ink
                selectionColor: finder.ui.accent
                selectedTextColor: finder.ui.accentInk
                font.pixelSize: finder.ui.textTitle
                cursorDelegate: Rectangle {
                    width: 2
                    radius: 1
                    color: finder.ui.accent
                    visible: query.cursorVisible
                }
                onTextChanged: finder.current = 0

                Keys.onPressed: event => {
                    const digit = event.key - Qt.Key_0
                    if (event.key === Qt.Key_Down)
                        finder.move(1)
                    else if (event.key === Qt.Key_Up)
                        finder.move(-1)
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                        finder.run(finder.current)
                    else if (event.key === Qt.Key_Tab)
                        finder.shell.cycle(1)
                    else if (event.key === Qt.Key_Backtab)
                        finder.shell.cycle(-1)
                    else if (event.key === Qt.Key_Escape)
                        finder.shell.close()
                    else if ((event.modifiers & Qt.ControlModifier) && digit >= 0 && digit <= 9)
                        finder.pin((digit + 9) % 10)
                    else
                        return
                    event.accepted = true
                }
            }
        }

        Repeater {
            model: finder.matched
            PaletteRow {
                id: command
                required property var modelData
                required property int index
                ui: finder.ui
                width: list.width
                name: modelData.name
                sub: modelData.sub
                icon: modelData.icon
                keys: modelData.keys
                current: finder.current === index
                onPointed: finder.current = command.index
                onChosen: finder.run(command.index)
            }
        }

        Repeater {
            id: found
            model: results
            PaletteRow {
                id: result
                required property int index
                required property string display
                required property var decoration
                required property string subtext
                required property var urls
                readonly property int row: finder.matched.length + index
                readonly property int slot: finder.slotOf(urls)
                ui: finder.ui
                width: list.width
                visible: index < finder.shownResults
                name: display
                sub: subtext
                icon: decoration
                keys: slot >= 0 ? ["Meta", Apps.key(slot)] : []
                current: finder.current === row
                onPointed: finder.current = result.row
                onChosen: finder.run(result.row)
            }
        }
    }
}
