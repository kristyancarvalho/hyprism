import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../components"

PanelWindow {
    id: shadowWindow
    required property var shellScreen
    required property var controller
    readonly property bool fullscreenActive: HyprlandService.monitorHasFullscreen(shellScreen)
    readonly property string localMode: controller.targetScreenName === shellScreen.name ? controller.mode : "compact"
    readonly property int shadowTopInset: Math.min(Design.surfaceShadowExtent, Design.compactTopMargin(controller.config.shell))
    property real shadowOpacity: controller.barVisible && !fullscreenActive && localMode === "compact" ? 1 : 0

    screen: shellScreen
    visible: shellScreen !== null
    anchors { top: true; left: true; right: true }
    margins.top: Design.compactTopMargin(controller.config.shell) - shadowTopInset
    implicitHeight: Design.compactHeight(controller.config.shell) + Design.surfaceShadowExtent * 2
    color: "transparent"
    surfaceFormat.opaque: false
    exclusionMode: ExclusionMode.Ignore
    mask: Region { width: 0; height: 0 }
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "hyprism-shadow"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Behavior on shadowOpacity {
        NumberAnimation { duration: Design.surfaceShadowTransition; easing.type: Design.easingMorph }
    }

    SurfaceShadow {
        x: (parent.width - width) / 2
        y: shadowWindow.shadowTopInset
        width: Design.compactWidth(shadowWindow.controller.config.shell, shadowWindow.shellScreen.width)
        height: Design.compactHeight(shadowWindow.controller.config.shell)
        opacity: shadowWindow.shadowOpacity
    }
}
