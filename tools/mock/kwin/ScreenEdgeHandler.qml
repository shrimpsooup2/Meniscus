import QtQuick
import org.kde.kwin as KWin

// Stand-in for KWin's ScreenEdgeHandler: activated when the harness pushes into its edge.
QtObject {
    id: handler

    enum Edge { TopEdge, TopRightEdge, RightEdge, BottomRightEdge, BottomEdge, BottomLeftEdge, LeftEdge, TopLeftEdge, NoEdge }
    enum Mode { Pointer, Touch }

    property bool enabled: true
    property int edge: ScreenEdgeHandler.NoEdge
    property int mode: ScreenEdgeHandler.Pointer

    signal activated()

    property Connections fire: Connections {
        target: KWin.Workspace
        function onMockEdge(edge) {
            if (handler.enabled && edge === handler.edge)
                handler.activated()
        }
    }
}
