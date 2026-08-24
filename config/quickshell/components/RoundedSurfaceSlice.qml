import QtQuick
import ".."

Item {
    id: slice
    property real surfaceWidth: width
    property real surfaceHeight: height
    property real cornerRadius: Design.radiusDefault
    property color color: "transparent"
    property bool rightAligned: false
    property bool bottomAligned: false

    clip: true

    Rectangle {
        x: slice.rightAligned ? slice.width - slice.surfaceWidth : 0
        y: slice.bottomAligned ? slice.height - slice.surfaceHeight : 0
        width: slice.surfaceWidth
        height: slice.surfaceHeight
        radius: slice.cornerRadius
        color: slice.color

        Behavior on color { ColorAnimation { duration: Design.animationFast; easing.type: Design.easingMorph } }
    }
}
