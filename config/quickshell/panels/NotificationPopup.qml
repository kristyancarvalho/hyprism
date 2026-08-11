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
    signal dismissRequested(var notification)

    screen: shellScreen
    visible: shellScreen !== null && notifications && notifications.length > 0
    anchors.top: true
    margins.top: Design.compactReservedHeight(controller.config.shell) + 6
    implicitWidth: 350
    implicitHeight: stack.implicitHeight
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Column {
        id: stack
        width: parent.width
        spacing: 8

        Repeater {
            model: popup.notifications || []

            NotificationCard {
                required property var modelData
                width: stack.width
                notification: modelData
                controller: popup.controller
                theme: popup.theme
                onDismissed: popup.dismissRequested(modelData)
            }
        }
    }
}
