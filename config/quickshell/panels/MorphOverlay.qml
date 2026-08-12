import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../components"
import ".."

PanelWindow {
    id: window
    required property var shellScreen
    required property var controller
    required property var theme
    required property var apps
    required property var clipboard
    required property var notifications
    property string displayedMode: "hover"
    readonly property bool interactive: controller.mode !== "compact" && controller.mode !== "hover"
    readonly property string contentMode: controller.mode === "compact" ? displayedMode : controller.mode
    readonly property int availableWidth: shellScreen ? shellScreen.width : 1024
    readonly property int availableHeight: shellScreen ? shellScreen.height : 768
    readonly property int safeWidth: Math.max(320, availableWidth - 32)
    readonly property int safeHeight: Math.max(Design.compactBarHeight, availableHeight - Design.compactTopMargin(controller.config.shell) - 16)
    readonly property int compactWidth: Design.compactWidth(controller.config.shell, availableWidth)
    readonly property int morphDuration: Math.max(1, Math.round(Design.safeNumber(controller.config.shell.animationNormal, Design.animationMorph)))
    readonly property var targetGeometry: geometryForMode()
    property real morphWidth: targetGeometry.width
    property real morphHeight: targetGeometry.height
    property real morphRadius: targetGeometry.radius

    function geometryForMode() {
        const mode = controller.mode
        let width = compactWidth
        let height = Design.compactHeight(controller.config.shell)
        let radius = Design.compactRadiusFor(controller.config.shell)
        if (mode === "hover") {
            width = Math.min(safeWidth, controller.mediaAvailable() ? 900 : 760)
            height = controller.mediaAvailable() ? 88 : 64
        } else if (mode === "launcher") {
            width = Math.min(safeWidth, 720)
            height = Design.launcherHeight(controller.launcherResultCount)
            radius = Design.radiusIslandExpanded
        } else if (mode === "wallpaper") {
            width = Math.min(safeWidth, 880)
            const columns = width >= 800 ? 4 : width >= 560 ? 3 : 2
            const rows = Math.max(1, Math.ceil(controller.wallpaperEntries.length / columns))
            height = Math.min(560, 104 + rows * 150)
            radius = Design.radiusIslandExpanded
        } else if (mode === "clipboard") {
            width = Math.min(safeWidth, 700)
            height = 500
            radius = Design.radiusIslandExpanded
        } else if (mode === "control") {
            width = Math.min(safeWidth, 600)
            height = 700
            radius = Design.radiusIslandExpanded
        } else if (mode === "network") {
            width = Math.min(safeWidth, 560)
            height = 440
            radius = Design.radiusIslandExpanded
        } else if (mode === "bluetooth") {
            width = Math.min(safeWidth, 560)
            height = controller.system.bluetooth.available ? Math.min(460, 130 + controller.system.bluetooth.devices.length * 68) : 170
            radius = Design.radiusIslandExpanded
        } else if (mode === "power") {
            width = Math.min(safeWidth, 640)
            height = 300
            radius = Design.radiusIslandExpanded
        } else if (mode === "emoji") {
            width = Math.min(safeWidth, 540)
            height = 360
            radius = Design.radiusIslandExpanded
        } else if (mode === "switcher") {
            width = Math.min(safeWidth, 920)
            height = 220
            radius = Design.radiusIslandExpanded
        }
        return {
            width: Math.round(Design.clamp(width, 320, safeWidth)),
            height: Math.round(Design.clamp(height, Design.compactBarHeight, safeHeight)),
            radius: Math.round(Design.clamp(radius, Design.radiusSm, Design.compactRadiusFor(controller.config.shell)))
        }
    }

    function focusPanel() {
        if (!interactive || !content.item) return
        window.requestActivate()
        if (content.item.takeInitialFocus) content.item.takeInitialFocus()
        else content.item.forceActiveFocus()
    }

    screen: shellScreen
    visible: shellScreen !== null && (controller.mode !== "compact" || controller.morphClosing)
    anchors.top: true
    margins.top: Design.compactTopMargin(controller.config.shell)
    implicitWidth: Math.round(morphWidth)
    implicitHeight: Math.round(morphHeight)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: morphSurface }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: interactive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    HyprlandFocusGrab {
        windows: [window]
        active: window.visible && window.interactive
        onCleared: if (window.interactive) controller.close()
    }

    Glass {
        id: morphSurface
        anchors.fill: parent
        radius: window.morphRadius
        theme: window.theme
        surfaceOpacity: controller.config.shell.surfaceOpacity
        clip: true

        HoverHandler {
            onHoveredChanged: {
                if (hovered) hoverClose.stop()
                else if (controller.mode === "hover") hoverClose.restart()
            }
        }

        TapHandler {
            enabled: controller.mode === "hover"
            onTapped: controller.openOnScreen("control", window.shellScreen.name)
        }

        Loader {
            id: content
            anchors.fill: parent
            opacity: 1
            sourceComponent: window.contentMode === "launcher" ? launcher : window.contentMode === "wallpaper" ? wallpaper : window.contentMode === "clipboard" ? clipboardPanel : window.contentMode === "control" ? control : window.contentMode === "network" ? network : window.contentMode === "bluetooth" ? bluetooth : window.contentMode === "power" ? power : window.contentMode === "emoji" ? emoji : window.contentMode === "switcher" ? switcher : expanded
            onLoaded: {
                opacity = 0
                contentReveal.restart()
                focusTimer.restart()
            }
            Behavior on opacity { NumberAnimation { duration: Design.animationFast; easing.type: Easing.OutCubic } }
        }
    }

    Behavior on morphWidth { NumberAnimation { duration: window.morphDuration; easing.type: Easing.OutCubic } }
    Behavior on morphHeight { NumberAnimation { duration: window.morphDuration; easing.type: Easing.OutCubic } }
    Behavior on morphRadius { NumberAnimation { duration: window.morphDuration; easing.type: Easing.OutCubic } }

    Timer {
        id: hoverClose
        interval: 650
        onTriggered: if (controller.mode === "hover") controller.close()
    }

    Timer {
        id: focusTimer
        interval: 0
        onTriggered: window.focusPanel()
    }

    Timer {
        id: contentReveal
        interval: Math.max(1, Math.round(window.morphDuration * .28))
        onTriggered: content.opacity = 1
    }

    Timer {
        id: closeFinalize
        interval: window.morphDuration
        onTriggered: controller.morphClosing = false
    }

    Connections {
        target: controller
        function onModeChanged() {
            if (controller.mode === "compact") {
                content.opacity = 0
                if (controller.morphClosing) closeFinalize.restart()
            } else {
                window.displayedMode = controller.mode
                closeFinalize.stop()
                contentReveal.restart()
                focusTimer.restart()
            }
        }
    }

    Component {
        id: expanded

        Item {
            anchors.fill: parent

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Repeater {
                    model: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

                    Rectangle {
                        required property int modelData
                        property bool selected: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === modelData
                        width: selected ? 24 : 8
                        height: 8
                        radius: height / 2
                        color: selected ? theme.colors.accent : theme.colors.surfaceElevated
                        border.width: selected ? 0 : 1
                        border.color: theme.colors.outline
                        Behavior on width { NumberAnimation { duration: controller.config.shell.animationFast } }

                        TapHandler { onTapped: Hyprland.dispatch("workspace " + modelData) }
                    }
                }
            }

            MediaStrip {
                visible: controller.mediaAvailable()
                anchors.centerIn: parent
                width: Math.min(410, parent.width * .48)
                controller: window.controller
                theme: window.theme
            }

            Column {
                visible: !controller.mediaAvailable()
                anchors.centerIn: parent

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: controller.formattedDate("HH:mm")
                    color: theme.colors.foreground
                    font.family: Design.fontFamily
                    font.pixelSize: Design.fontSizeLg
                    font.weight: Design.fontWeightSemibold
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: controller.formattedDate("ddd, dd MMM")
                    color: theme.colors.mutedForeground
                    font.family: Design.fontFamily
                    font.pixelSize: Design.fontSizeXs
                }
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                spacing: Design.compactItemSpacing

                CompactBarPill {
                    visible: controller.weather.temperature !== null
                    theme: window.theme
                    iconName: controller.weatherIconName(controller.weather.weatherCode)
                    label: Math.round(Design.safeNumber(controller.weather.temperature, 0)) + "°"
                }

                CompactBarPill {
                    theme: window.theme
                    iconName: controller.networkIconName()
                    iconOnly: true
                    active: controller.system.network.enabled
                }

                CompactBarPill {
                    visible: controller.system.bluetooth.available
                    theme: window.theme
                    iconName: controller.bluetoothIconName()
                    iconOnly: true
                    active: controller.system.bluetooth.powered
                }

                CompactBarPill {
                    visible: controller.system.battery.available
                    theme: window.theme
                    iconName: controller.batteryIconName()
                    label: controller.batteryText()
                }
            }
        }
    }

    Component { id: launcher; Launcher { controller: window.controller; theme: window.theme } }
    Component { id: wallpaper; WallpaperPicker { controller: window.controller; theme: window.theme; appService: window.apps } }
    Component { id: clipboardPanel; Clipboard { controller: window.controller; theme: window.theme; clipboard: window.clipboard } }
    Component { id: control; ControlCenter { controller: window.controller; theme: window.theme; notificationServer: window.notifications } }
    Component { id: network; NetworkPanel { controller: window.controller; theme: window.theme } }
    Component { id: bluetooth; BluetoothPanel { controller: window.controller; theme: window.theme } }
    Component { id: power; PowerMenu { controller: window.controller; theme: window.theme } }
    Component { id: emoji; EmojiPicker { controller: window.controller; theme: window.theme } }
    Component { id: switcher; WindowSwitcher { controller: window.controller; theme: window.theme } }
}
