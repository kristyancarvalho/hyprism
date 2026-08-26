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
    property bool removalPending: false
    signal dismissRequested(var notification)

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
        let removed = false
        for (let index = popupModel.count - 1; index >= 0; index--) {
            if (desiredKeys.indexOf(popupModel.get(index).key) < 0) {
                removed = true
                popupModel.remove(index)
            }
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
        if (removed) {
            removalPending = true
            removalTimer.restart()
        } else if (current.length > 0) {
            removalPending = false
            removalTimer.stop()
        }
    }

    screen: shellScreen
    visible: shellScreen !== null && !suppressed && (popupModel.count > 0 || removalPending)
    anchors.top: true
    margins.top: Design.compactReservedHeight(controller.config.shell) + 6
    implicitWidth: 360
    implicitHeight: Math.min(stack.contentHeight + (overflow.visible ? overflow.height + Design.spacingSm : 0), Math.max(120, shellScreen ? shellScreen.height - margins.top - 16 : 600))
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    ListModel { id: popupModel; dynamicRoles: true }

    Timer {
        id: removalTimer
        interval: Design.animationMorph
        onTriggered: popup.removalPending = false
    }

    ListView {
        id: stack
        width: parent.width
        height: parent.height - (overflow.visible ? overflow.height + Design.spacingSm : 0)
        spacing: Design.notificationSpacing
        clip: true
        interactive: false
        cacheBuffer: 1000
        model: popupModel

        delegate: NotificationCard {
            required property var payload
            notification: payload
            width: stack.width
            controller: popup.controller
            theme: popup.theme
            onDismissed: popup.dismissRequested(notification)
        }

        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Design.animationFast; easing.type: Design.easingEnter }
                NumberAnimation { property: "x"; from: 16; to: 0; duration: Design.animationMorph; easing.type: Design.easingEnter }
            }
        }
        remove: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; to: 0; duration: Design.animationFast; easing.type: Design.easingExit }
                NumberAnimation { property: "x"; to: 16; duration: Design.animationMorph; easing.type: Design.easingExit }
            }
        }
        displaced: Transition { NumberAnimation { property: "y"; duration: Design.animationMorph; easing.type: Design.easingMove } }
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
            text: I18n.tr("notifications.inHistory", { count: popup.overflowCount })
            color: popup.theme.colors.mutedForeground
            font.family: Design.fontFamily
            font.pixelSize: Design.fontSizeXs
            font.weight: Design.fontWeightMedium
        }
    }

    onNotificationsChanged: syncModel()
    Component.onCompleted: syncModel()
}
