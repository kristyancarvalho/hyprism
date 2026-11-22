import QtQuick
import ".."

Item {
    id: shadow
    property var theme
    property real radius
    readonly property int extent: Design.surfaceShadowExtent
    readonly property int layerCount: 16
    readonly property color shadowColor: Design.surfaceShadowColor(theme)

    Repeater {
        model: shadow.layerCount

        Rectangle {
            required property int index
            readonly property real layerExtent: shadow.extent * (shadow.layerCount - index) / shadow.layerCount
            x: -layerExtent
            y: -layerExtent + Design.surfaceShadowOffsetY
            width: shadow.width + 2 * layerExtent
            height: shadow.height + 2 * layerExtent
            radius: shadow.radius + layerExtent
            color: shadow.shadowColor
            opacity: .04 + .10 * index / (shadow.layerCount - 1)
            antialiasing: true
        }
    }
}
