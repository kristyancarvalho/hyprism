import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: window
    required property var shellScreen
    required property var controller
    required property var theme
    readonly property bool fullscreenActive: HyprlandService.monitorHasFullscreen(shellScreen)
    screen: shellScreen
    visible: shellScreen !== null && !fullscreenActive
    anchors.top: true
    margins.top: Design.compactTopMargin(controller.config.shell)
    implicitWidth: 1
    implicitHeight: Design.compactHeight(controller.config.shell)
    color: "transparent"
    surfaceFormat.opaque: false
    exclusiveZone: fullscreenActive ? 0 : Design.compactHeight(controller.config.shell) + Design.compactGap(controller.config.shell)
    mask: Region { width: 0; height: 0 }
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
}
