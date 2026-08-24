import QtQuick
import ".."

Item {
    id: indicator
    required property var theme
    required property var notifications
    readonly property bool active: notifications.doNotDisturb
    implicitWidth: active ? Design.iconXs : 0
    implicitHeight: Design.compactItemHeight
    visible: active || opacity > 0
    opacity: active ? 1 : 0
    scale: active ? 1 : .82

    StatusIcon {
        anchors.centerIn: parent
        name: "notificationOff"
        iconSize: Design.iconXs
        color: indicator.theme.colors.foreground
    }

    Behavior on implicitWidth { NumberAnimation { duration: Design.animationFast; easing.type: Design.easingEnter } }
    Behavior on opacity { NumberAnimation { duration: Design.animationFast; easing.type: Design.easingEnter } }
    Behavior on scale { NumberAnimation { duration: Design.animationFast; easing.type: Design.easingEnter } }
}
