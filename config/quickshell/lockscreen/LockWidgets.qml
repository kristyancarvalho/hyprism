import QtQuick
import "../widgets"
import ".."

Item {
    id: cluster
    required property var controller
    required property var theme
    required property var shellScreen
    required property real availableWidth
    required property real availableHeight
    readonly property real fit: board.logicalHeight > 0 ? Math.min(Design.widgetScale, availableWidth / board.logicalWidth, availableHeight / board.logicalHeight) : 1

    visible: board.logicalHeight > 0
    width: board.logicalWidth * fit
    height: board.logicalHeight * fit
    enabled: false

    WidgetBoard {
        id: board
        shellScreen: cluster.shellScreen
        controller: cluster.controller
        theme: cluster.theme
        playingOnly: true
        scale: cluster.fit
        transformOrigin: Item.TopLeft
        layer.enabled: true
        layer.smooth: true
        layer.textureSize: Qt.size(Math.ceil(width * scale * 2), Math.ceil(height * scale * 2))
    }
}
