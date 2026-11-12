.pragma library

// The tray's ten slots, 1 to 9 then 0, kept in the TrayApps setting as comma separated desktop
// file ids (as in window.desktopFileName, without ".desktop"), each written id=icon where the
// app's icon is named differently. An empty id is an empty slot.
function parse(text) {
    const apps = String(text || "").split(",").slice(0, 10).map(entry => {
        const parts = entry.trim().split("=")
        return { id: parts[0], icon: parts[1] || parts[0] }
    })
    while (apps.length < 10)
        apps.push({ id: "", icon: "" })
    return apps
}

function format(apps) {
    const entries = apps.map(app => !app.id ? "" : app.icon && app.icon !== app.id ? app.id + "=" + app.icon : app.id)
    while (entries.length && entries[entries.length - 1] === "")
        entries.pop()
    return entries.join(",")
}

// The key a slot answers to: 1 to 9, then 0.
function key(slot) {
    return String((slot + 1) % 10)
}

// The desktop file id in a .desktop file's path or URL.
function idOf(url) {
    const name = String(url || "").split("/").pop()
    return name.endsWith(".desktop") ? decodeURIComponent(name.slice(0, -8)) : ""
}

// A readable name from a desktop file id: its last part, capitalised (org.kde.dolphin: Dolphin).
function name(id) {
    const last = String(id || "").split(".").pop()
    return last ? last.charAt(0).toUpperCase() + last.slice(1) : ""
}
