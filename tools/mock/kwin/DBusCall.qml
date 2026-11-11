import QtQuick
import org.kde.kwin as KWin

// Stand-in for KWin's DBusCall: logs the call and reports success.
QtObject {
    property string service
    property string path
    property string dbusInterface
    property string method
    property var arguments: []

    signal finished(var returnValue)
    signal failed()

    function call() {
        KWin.Workspace.mockSay("dbus " + service + " " + path + " " + dbusInterface + "." + method
                               + " " + JSON.stringify(arguments))
        finished([])
    }
}
