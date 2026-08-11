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
    readonly property bool interactive: controller.mode !== "compact" && controller.mode !== "hover"
    readonly property int availableWidth: shellScreen ? shellScreen.width : 1024
    readonly property int availableHeight: shellScreen ? shellScreen.height : 768
    readonly property int safeWidth: Math.max(320, availableWidth - 32)
    readonly property int safeHeight: Math.max(Design.compactBarHeight, availableHeight - Design.compactTopMargin(controller.config.shell) - 16)
    readonly property int compactWidth: Math.min(safeWidth, Math.max(520, controller.config.shell.islandWidth))
    readonly property int desiredWidth: {
        if (controller.mode === "hover") return Math.min(safeWidth, controller.mediaAvailable() ? 900 : 760)
        if (controller.mode === "launcher") return Math.min(safeWidth, 720)
        if (controller.mode === "wallpaper") return Math.min(safeWidth, 880)
        if (controller.mode === "clipboard") return Math.min(safeWidth, 700)
        if (controller.mode === "control") return Math.min(safeWidth, 600)
        if (controller.mode === "network" || controller.mode === "bluetooth") return Math.min(safeWidth, 560)
        if (controller.mode === "power") return Math.min(safeWidth, 640)
        if (controller.mode === "emoji") return Math.min(safeWidth, 540)
        if (controller.mode === "switcher") return Math.min(safeWidth, 920)
        return compactWidth
    }
    readonly property int requestedHeight: {
        if (controller.mode === "hover") return controller.mediaAvailable() ? 88 : 64
        if (controller.mode === "launcher") return Design.launcherHeight(controller.launcherResultCount)
        if (controller.mode === "wallpaper") {
            const columns = desiredWidth >= 800 ? 4 : desiredWidth >= 560 ? 3 : 2
            const rows = Math.max(1, Math.ceil(controller.wallpaperEntries.length / columns))
            return Math.min(560, 104 + rows * 150)
        }
        if (controller.mode === "clipboard") return 500
        if (controller.mode === "control") return 700
        if (controller.mode === "network") return 440
        if (controller.mode === "bluetooth") return controller.system.bluetooth.available ? Math.min(460, 130 + controller.system.bluetooth.devices.length * 68) : 170
        if (controller.mode === "power") return 300
        if (controller.mode === "emoji") return 360
        if (controller.mode === "switcher") return 220
        return Design.compactHeight(controller.config.shell)
    }
    readonly property int desiredHeight: Math.min(safeHeight, requestedHeight)

    function focusPanel() {
        if (!interactive || !content.item) return
        window.requestActivate()
        if (content.item.takeInitialFocus) content.item.takeInitialFocus()
        else content.item.forceActiveFocus()
    }

    screen: shellScreen
    visible: shellScreen !== null && controller.mode !== "compact"
    anchors.top: true
    margins.top: Design.compactTopMargin(controller.config.shell)
    implicitWidth: safeWidth
    implicitHeight: safeHeight
    color: "transparent"
    exclusiveZone: 0
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
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: window.desiredWidth
        height: window.desiredHeight
        radius: controller.mode === "hover" ? Design.compactRadius : Design.radiusLg
        theme: window.theme
        surfaceOpacity: controller.config.shell.surfaceOpacity
        clip: true
        Behavior on width { NumberAnimation { duration: controller.config.shell.animationNormal; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: controller.config.shell.animationNormal; easing.type: Easing.OutCubic } }
        Behavior on radius { NumberAnimation { duration: controller.config.shell.animationFast; easing.type: Easing.OutCubic } }

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
            sourceComponent: controller.mode === "launcher" ? launcher : controller.mode === "wallpaper" ? wallpaper : controller.mode === "clipboard" ? clipboardPanel : controller.mode === "control" ? control : controller.mode === "network" ? network : controller.mode === "bluetooth" ? bluetooth : controller.mode === "power" ? power : controller.mode === "emoji" ? emoji : controller.mode === "switcher" ? switcher : expanded
            onLoaded: focusTimer.restart()
        }
    }

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

    Connections {
        target: controller
        function onModeChanged() { focusTimer.restart() }
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
                        radius: 4
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
