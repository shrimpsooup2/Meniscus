import QtQuick

QtObject {
    enum Edge { TopEdge, TopRightEdge, RightEdge, BottomRightEdge, BottomEdge, BottomLeftEdge, LeftEdge, TopLeftEdge, NoEdge }
    enum Mode { Pointer, Touch }

    property bool enabled: true
    property int edge: ScreenEdgeHandler.NoEdge
    property int mode: ScreenEdgeHandler.Pointer

    signal activated()
}
