import QtQuick
import org.kde.kwin as KWin

// Stand-in for KWin's DesktopBackground: the wallpaper of the active theme.
Image {
    property string outputName
    property var output
    property var activity
    property var desktop

    source: KWin.Workspace.mockWallpaper
    sourceSize.width: 2560
    fillMode: Image.PreserveAspectCrop
    asynchronous: false
    smooth: true
}
