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
    visible: shellScreen !== null
    anchors.top: true
    margins.top: Design.compactTopMargin(controller.config.shell)
    implicitWidth: 1
    implicitHeight: Design.compactHeight(controller.config.shell)
    color: "transparent"
    surfaceFormat.opaque: false
    exclusiveZone: Design.compactHeight(controller.config.shell) + Design.compactGap(controller.config.shell)
    mask: Region { width: 0; height: 0 }
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
}
