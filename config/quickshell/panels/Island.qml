import QtQuick
import QtQuick.Controls
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
    screen: shellScreen
    visible: shellScreen !== null
    anchors { top: true }
    margins.top: controller.config.shell.topMargin
    implicitWidth: desiredWidth
    implicitHeight: desiredHeight
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: !controller || controller.mode === "compact" || controller.mode === "hover" ? WlrKeyboardFocus.None : WlrKeyboardFocus.OnDemand

    property int availableWidth: shellScreen ? shellScreen.width : 1024
    property int availableHeight: shellScreen ? shellScreen.height : 768
    property int safeWidth: Math.max(320, availableWidth - 32)
    property int safeHeight: Math.max(48, availableHeight - controller.config.shell.topMargin - 16)
    property int desiredWidth: {
        if (!controller || controller.mode === "compact") return Math.min(safeWidth, Math.max(480, controller.config.shell.islandWidth))
        if (controller.mode === "hover") return Math.min(safeWidth, 820)
        if (controller.mode === "launcher") return Math.min(safeWidth, 720)
        if (controller.mode === "wallpaper") return Math.min(safeWidth, 880)
        if (controller.mode === "clipboard") return Math.min(safeWidth, 700)
        if (controller.mode === "control") return Math.min(safeWidth, 560)
        if (controller.mode === "network" || controller.mode === "bluetooth") return Math.min(safeWidth, 560)
        if (controller.mode === "power") return Math.min(safeWidth, 640)
        if (controller.mode === "emoji") return Math.min(safeWidth, 540)
        if (controller.mode === "switcher") return Math.min(safeWidth, 900)
        return Math.min(safeWidth, 520)
    }
    property int requestedHeight: {
        if (!controller || controller.mode === "compact") return Math.max(48, controller.config.shell.compactHeight)
        if (controller.mode === "hover") return 64
        if (controller.mode === "launcher") return 520
        if (controller.mode === "wallpaper") {
            const columns = desiredWidth >= 800 ? 4 : desiredWidth >= 560 ? 3 : 2
            const rows = Math.max(1, Math.ceil(controller.wallpaperEntries.length / columns))
            return Math.min(560, 104 + rows * 150)
        }
        if (controller.mode === "clipboard") return 500
        if (controller.mode === "control") return 720
        if (controller.mode === "network") return 420
        if (controller.mode === "bluetooth") return controller.system.bluetooth.available ? Math.min(440, 130 + controller.system.bluetooth.devices.length * 68) : 150
        if (controller.mode === "power") return 280
        if (controller.mode === "emoji") return 360
        if (controller.mode === "switcher") return 180
        return 48
    }
    property int desiredHeight: Math.min(safeHeight, requestedHeight)

    Glass {
        id: island
        anchors.fill: parent
        radius: !controller || controller.mode === "compact" || controller.mode === "hover" ? controller.config.shell.radiusMedium : controller.config.shell.radiusLarge
        theme: window.theme
        surfaceOpacity: controller ? controller.config.shell.surfaceOpacity : .9
        Behavior on width { NumberAnimation { duration: controller.config.shell.animationNormal; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: controller.config.shell.animationNormal; easing.type: Easing.OutCubic } }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
            onEntered: { if (controller.mode === "compact") controller.mode = "hover"; hoverClose.stop() }
            onExited: { if (controller.mode === "hover") hoverClose.restart() }
            onClicked: { if (controller.mode === "compact" || controller.mode === "hover") controller.toggle("control") }
        }

        Timer { id: hoverClose; interval: 650; onTriggered: { if (controller.mode === "hover") controller.close() } }

        Loader {
            anchors.fill: parent
            sourceComponent: !controller || !window.theme ? null : controller.mode === "launcher" ? launcher : controller.mode === "wallpaper" ? wallpaper : controller.mode === "clipboard" ? clipboardPanel : controller.mode === "control" ? control : controller.mode === "network" ? network : controller.mode === "bluetooth" ? bluetooth : controller.mode === "power" ? power : controller.mode === "emoji" ? emoji : controller.mode === "switcher" ? switcher : controller.mode === "hover" ? expanded : compact
        }

        Component {
            id: compact
            Row {
                anchors.centerIn: parent
                spacing: 10

                Rectangle {
                    width: 38; height: 30; radius: 15; color: theme.colors.accentDim
                    Text { anchors.centerIn: parent; text: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1; color: theme.colors.foreground; font { pixelSize: 12; bold: true } }
                }

                Text { anchors.verticalCenter: parent.verticalCenter; text: controller.formattedDate("HH:mm"); color: theme.colors.foreground; font { pixelSize: 14; bold: true } }
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 1; height: 20; color: theme.colors.outline }
                StatusChip { visible: controller.weather.temperature !== null; theme: window.theme; iconName: controller.weatherIconName(controller.weather.weatherCode); label: Math.round(controller.weather.temperature) + "°" }
                StatusChip { theme: window.theme; iconName: controller.networkIconName(); label: controller.networkLabel(); highlighted: controller.system.network.enabled }
                StatusChip { visible: controller.system.bluetooth.available; theme: window.theme; iconName: controller.bluetoothIconName(); label: controller.system.bluetooth.connected ? "Conectado" : "Bluetooth"; highlighted: controller.system.bluetooth.powered }
                StatusChip { visible: controller.system.battery.available; theme: window.theme; iconName: controller.batteryIconName(); label: controller.batteryText() }
            }
        }

        Component {
            id: expanded
            Item {
                anchors.fill: parent

                Row {
                    anchors { left: parent.left; leftMargin: 22; verticalCenter: parent.verticalCenter }
                    spacing: 7
                    Repeater {
                        model: [1,2,3,4,5,6,7,8,9,10]
                        Rectangle {
                            required property int modelData
                            property bool selected: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === modelData
                            width: selected ? 20 : 8
                            height: 8
                            radius: 4
                            color: selected ? theme.colors.accent : theme.colors.surfaceVariant
                            Behavior on width { NumberAnimation { duration: controller.config.shell.animationFast } }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + modelData + " })") }
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 1
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: controller.formattedDate("HH:mm"); color: theme.colors.foreground; font { pixelSize: 15; bold: true } }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: controller.formattedDate("ddd, dd MMM"); color: theme.colors.mutedForeground; font.pixelSize: 10 }
                }

                Row {
                    anchors { right: parent.right; rightMargin: 22; verticalCenter: parent.verticalCenter }
                    spacing: 9
                    StatusChip { visible: controller.weather.temperature !== null; theme: window.theme; iconName: controller.weatherIconName(controller.weather.weatherCode); label: Math.round(controller.weather.temperature) + "°" }
                    ShellIcon { anchors.verticalCenter: parent.verticalCenter; name: controller.networkIconName(); iconSize: 20 }
                    ShellIcon { visible: controller.system.bluetooth.available; anchors.verticalCenter: parent.verticalCenter; name: controller.bluetoothIconName(); iconSize: 20 }
                    StatusChip { visible: controller.system.battery.available; theme: window.theme; iconName: controller.batteryIconName(); label: controller.batteryText() }
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
}
