import QtQuick
import org.kde.kwin as KWin

// The rest of the desktop, over D-Bus: KDE's own global shortcuts for media, volume and
// brightness, the screen saver for locking, and the meniscus@ user unit, which runs
// bin/meniscusctl for whatever needs a shell (themes, power, syncing the window effect).
QtObject {
    id: system

    readonly property Component call: Component { KWin.DBusCall {} }

    function dbus(service, path, iface, method, args) {
        const c = call.createObject(system, {
            service: service, path: path, dbusInterface: iface, method: method, arguments: args || [],
        })
        c.finished.connect(() => c.destroy())
        c.failed.connect(() => {
            console.warn("meniscus:", service, method, "failed")
            c.destroy()
        })
        c.call()
    }

    // `meniscusctl a b` runs as meniscus@a:b.service. The instance is escaped the way
    // systemd-escape does, so the unit gets the arguments back with %I.
    function ctl(args) {
        let instance = ""
        let first = true
        for (const c of args.join(":")) {
            const code = c.charCodeAt(0)
            if (c === "/")
                instance += "-"
            else if (/[A-Za-z0-9:_]/.test(c) || (c === "." && !first))
                instance += c
            else if (code < 0x80)
                instance += "\\x" + code.toString(16).padStart(2, "0")
            else
                instance += encodeURIComponent(c).toLowerCase().replace(/%/g, "\\x")
            first = false
        }
        dbus("org.freedesktop.systemd1", "/org/freedesktop/systemd1", "org.freedesktop.systemd1.Manager",
             "StartUnit", ["meniscus@" + instance + ".service", "replace"])
    }

    function shortcut(component, name) {
        dbus("org.kde.kglobalaccel", "/component/" + component, "org.kde.kglobalaccel.Component",
             "invokeShortcut", [name])
    }

    function act(what) {
        switch (what) {
        case "play": return shortcut("mediacontrol", "playpausemedia")
        case "next": return shortcut("mediacontrol", "nextmedia")
        case "previous": return shortcut("mediacontrol", "previousmedia")
        case "louder": return shortcut("kmix", "increase_volume")
        case "quieter": return shortcut("kmix", "decrease_volume")
        case "mute": return shortcut("kmix", "mute")
        case "brighter": return shortcut("org_kde_powerdevil", "Increase Screen Brightness")
        case "dimmer": return shortcut("org_kde_powerdevil", "Decrease Screen Brightness")
        case "lock": return dbus("org.freedesktop.ScreenSaver", "/ScreenSaver", "org.freedesktop.ScreenSaver", "Lock", [])
        case "sleep":
        case "logout":
        case "restart":
        case "shutdown": return ctl(["power", what])
        }
        console.warn("meniscus: unknown action", what)
    }
}
