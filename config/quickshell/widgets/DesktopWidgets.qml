import QtQuick
import Quickshell
import Quickshell.Wayland
import "../components"
import ".."

PanelWindow {
    id: widgetWindow
    required property var shellScreen
    required property var controller
    required property var theme
    readonly property int logicalWidth: board.logicalWidth
    readonly property int logicalHeight: board.logicalHeight
    readonly property real effectiveScale: Math.min(Design.widgetScale, usableHeight / Math.max(1, logicalHeight), shellScreen ? (shellScreen.width - Design.spacingLg * 2) / logicalWidth : Design.widgetScale)
    readonly property string layoutPosition: controller.widgetLayoutPosition()
    readonly property int usableTop: Design.compactReservedHeight(controller.config.shell) + Design.spacingLg
    readonly property int usableHeight: shellScreen ? Math.max(0, shellScreen.height - usableTop - Design.spacingLg) : 0
    readonly property int centeredTop: usableTop + Math.max(0, Math.floor((usableHeight - implicitHeight) / 2))
    screen: shellScreen
    visible: shellScreen !== null && !HyprlandService.monitorHasFullscreen(shellScreen)
    anchors {
        right: widgetWindow.layoutPosition === "top-right" || widgetWindow.layoutPosition === "bottom-right"
        left: widgetWindow.layoutPosition === "top-left" || widgetWindow.layoutPosition === "bottom-left"
        top: widgetWindow.layoutPosition !== "bottom-left" && widgetWindow.layoutPosition !== "bottom-right"
        bottom: widgetWindow.layoutPosition === "bottom-left" || widgetWindow.layoutPosition === "bottom-right"
    }
    margins {
        top: widgetWindow.layoutPosition === "center" ? widgetWindow.centeredTop : widgetWindow.usableTop
        bottom: Design.spacingLg
        right: Design.spacingLg
        left: Design.spacingLg
    }
    implicitWidth: logicalWidth * effectiveScale
    implicitHeight: logicalHeight * effectiveScale
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None


    WidgetBoard {
        id: board
        shellScreen: widgetWindow.shellScreen
        controller: widgetWindow.controller
        theme: widgetWindow.theme
        scale: widgetWindow.effectiveScale
        transformOrigin: Item.TopLeft
        layer.enabled: true
        layer.smooth: true
        layer.textureSize: Qt.size(Math.ceil(width * scale * 2), Math.ceil(height * scale * 2))
    }
}
