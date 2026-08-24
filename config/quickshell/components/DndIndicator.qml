import QtQuick
import ".."

Item {
    id: indicator
    required property var theme
    required property var notifications
    implicitWidth: Design.compactItemHeight
    implicitHeight: Design.compactItemHeight
    opacity: notifications.doNotDisturb ? 1 : 0
    scale: notifications.doNotDisturb ? 1 : .82

    StatusIcon {
        anchors.centerIn: parent
        name: "notificationOff"
        iconSize: Design.compactIconSize
        color: indicator.theme.colors.accent
    }

    Behavior on opacity { NumberAnimation { duration: Design.animationFast; easing.type: Design.easingEnter } }
    Behavior on scale { NumberAnimation { duration: Design.animationFast; easing.type: Design.easingEnter } }
}
