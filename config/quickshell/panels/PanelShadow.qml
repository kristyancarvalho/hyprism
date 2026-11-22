import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../components"

PanelWindow {
    id: shadowWindow
    required property var overlay

    screen: overlay.shellScreen
    visible: overlay.visible
    anchors.top: true
    margins.top: overlay.margins.top
    implicitWidth: overlay.implicitWidth
    implicitHeight: overlay.implicitHeight
    color: "transparent"
    surfaceFormat.opaque: false
    exclusionMode: ExclusionMode.Ignore
    mask: Region { width: 0; height: 0 }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "hyprism-shadow"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    SurfaceShadow {
        x: Math.round((shadowWindow.width - width) / 2)
        y: overlay.shadowTopInset
        width: overlay.morphWidthRounded
        height: overlay.morphHeightRounded
        opacity: overlay.localMode === "compact" ? 0 : 1

        Behavior on opacity {
            NumberAnimation { duration: Design.surfaceShadowTransition; easing.type: Design.easingMorph }
        }
    }
}
