import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: window
    required property var shellScreen
    required property var controller
    required property var theme

    screen: shellScreen
    visible: shellScreen !== null && controller.osdKind.length > 0
    anchors { top: true }
    margins.top: Design.compactReservedHeight(controller.config.shell) + 8
    implicitWidth: 320
    implicitHeight: 58
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Osd { anchors.fill: parent; controller: window.controller; theme: window.theme }
}
