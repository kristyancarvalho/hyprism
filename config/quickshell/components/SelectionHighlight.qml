import QtQuick
import ".."

Item {
    id: highlight
    required property var theme
    property bool active: true
    property int inset: 0
    property real strength: 1

    opacity: active ? strength : 0

    Rectangle {
        anchors.fill: parent
        anchors.margins: highlight.inset
        radius: Design.radiusSm
        color: highlight.theme.colors.surfaceActive
    }

    Behavior on x { NumberAnimation { duration: Design.animationMorph; easing.type: Design.easingMove } }
    Behavior on y { NumberAnimation { duration: Design.animationMorph; easing.type: Design.easingMove } }
    Behavior on width { NumberAnimation { duration: Design.animationFast; easing.type: Design.easingMorph } }
    Behavior on height { NumberAnimation { duration: Design.animationFast; easing.type: Design.easingMorph } }
    Behavior on opacity { NumberAnimation { duration: Design.animationFast; easing.type: Design.easingMorph } }
}
