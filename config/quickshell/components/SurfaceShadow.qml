import QtQuick
import ".."

Item {
    id: shadow
    readonly property int extent: Design.surfaceShadowExtent

    BorderImage {
        x: -shadow.extent
        y: -shadow.extent
        width: Math.ceil(shadow.width) + 2 * shadow.extent
        height: Math.ceil(shadow.height) + 2 * shadow.extent
        source: Qt.resolvedUrl("../data/surface-shadow.png")
        border { left: Design.surfaceShadowSlice; top: Design.surfaceShadowSlice; right: Design.surfaceShadowSlice; bottom: Design.surfaceShadowSlice }
        smooth: false
        opacity: Design.surfaceShadowOpacity
    }
}
