import QtQuick
import Quickshell
import Quickshell.Wayland
import "../notifications"

PanelWindow {
    id: popup
    required property var shellScreen
    required property var notification
    required property var controller
    required property var theme

    screen: shellScreen
    visible: shellScreen !== null && notification !== null
    anchors { right: true; top: true }
    margins { top: 18; right: 22 }
    implicitWidth: 330
    implicitHeight: 120
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    NotificationCard {
        anchors.top: parent.top
        notification: popup.notification
        controller: popup.controller
        theme: popup.theme
    }
}
