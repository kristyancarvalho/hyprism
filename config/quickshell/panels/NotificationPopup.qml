import QtQuick
import Quickshell
import Quickshell.Wayland
import "../notifications"
import ".."

PanelWindow {
    id: popup
    required property var shellScreen
    required property var notifications
    required property var controller
    required property var theme
    property int overflowCount: 0
    property bool suppressed: false
    signal dismissRequested(var notification)
    signal expireRequested(var notification)

    function notificationKey(notification) {
        return notification ? String(notification.id) : ""
    }

    function modelIndex(key) {
        for (let index = 0; index < popupModel.count; index++) {
            if (popupModel.get(index).key === key) return index
        }
        return -1
    }

    function syncModel() {
        const current = notifications || []
        const desiredKeys = current.map(notification => notificationKey(notification))
        for (let index = popupModel.count - 1; index >= 0; index--) {
            if (desiredKeys.indexOf(popupModel.get(index).key) < 0) popupModel.remove(index)
        }
        for (let target = 0; target < current.length; target++) {
            const notification = current[target]
            const key = notificationKey(notification)
            const existing = modelIndex(key)
            if (existing < 0) popupModel.insert(target, { key: key, payload: notification })
            else {
                popupModel.setProperty(existing, "payload", notification)
                if (existing !== target) popupModel.move(existing, target, 1)
            }
        }
    }

    screen: shellScreen
    visible: shellScreen !== null && !suppressed && popupModel.count > 0
    anchors.top: true
    margins.top: Design.compactReservedHeight(controller.config.shell) + 6
    implicitWidth: 360
    implicitHeight: Math.min(stack.contentHeight + (overflow.visible ? overflow.height + Design.spacingSm : 0), Math.max(120, shellScreen ? shellScreen.height - margins.top - 16 : 600))
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    ListModel { id: popupModel; dynamicRoles: true }

    ListView {
        id: stack
        width: parent.width
        height: parent.height - (overflow.visible ? overflow.height + Design.spacingSm : 0)
        spacing: 8
        clip: true
        interactive: false
        model: popupModel

        delegate: NotificationCard {
            required property var payload
            notification: payload
            width: stack.width
            controller: popup.controller
            theme: popup.theme
            onDismissed: popup.dismissRequested(notification)
            onExpired: popup.expireRequested(notification)
        }

        add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Design.animationFast; easing.type: Easing.OutCubic } }
        remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: Design.animationFast; easing.type: Easing.OutCubic } }
        displaced: Transition { NumberAnimation { property: "y"; duration: Design.animationMorph; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        id: overflow
        visible: popup.overflowCount > 0
        anchors {
            top: stack.bottom
            topMargin: Design.spacingSm
            horizontalCenter: parent.horizontalCenter
        }
        implicitWidth: overflowText.implicitWidth + 20
        width: implicitWidth
        height: 26
        radius: Design.radiusSm
        color: popup.theme.colors.surfaceElevated

        Text {
            id: overflowText
            anchors.centerIn: parent
            text: "+" + popup.overflowCount + " no histórico"
            color: popup.theme.colors.mutedForeground
            font.family: Design.fontFamily
            font.pixelSize: Design.fontSizeXs
            font.weight: Design.fontWeightMedium
        }
    }

    onNotificationsChanged: syncModel()
    Component.onCompleted: syncModel()
}
