import QtQuick
import ".."

Item {
    id: surface
    required property Item host
    required property Item target
    required property var theme
    property bool hovered: false
    property int inset: 0
    property real cornerRadius: Design.radiusSm
    property color baseColor: theme.colors.surfaceVariant
    property color hoverColor: theme.colors.surfaceElevated

    parent: host
    x: target ? target.x + inset : 0
    y: target ? target.y + inset : 0
    width: target ? Math.max(0, target.width - inset * 2) : 0
    height: target ? Math.max(0, target.height - inset * 2) : 0
    visible: target && target.visible
    z: 0

    Rectangle {
        anchors.fill: parent
        radius: surface.cornerRadius
        color: surface.hovered ? surface.hoverColor : surface.baseColor

        Behavior on color { ColorAnimation { duration: Design.animationFast; easing.type: Design.easingMorph } }
    }
}
