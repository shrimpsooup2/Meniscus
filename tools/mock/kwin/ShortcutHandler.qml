import QtQuick
import org.kde.kwin as KWin

// Stand-in for KWin's ShortcutHandler: activated when the harness fires its sequence.
QtObject {
    id: handler

    property string name
    property string text
    property var sequence

    signal activated()

    property Connections fire: Connections {
        target: KWin.Workspace
        function onMockShortcut(fired) {
            if (fired === String(handler.sequence))
                handler.activated()
        }
    }
}
