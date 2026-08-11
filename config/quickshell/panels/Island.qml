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

    function roman(number) { let values = [[10,"X"],[9,"IX"],[5,"V"],[4,"IV"],[1,"I"]], result=""; for (let pair of values) while(number >= pair[0]) { result += pair[1]; number -= pair[0] } return result }
    property int availableWidth: shellScreen ? shellScreen.width : 800
    property int desiredWidth: !controller ? 470 : controller.mode === "launcher" ? Math.min(620, availableWidth - 32) : controller.mode === "wallpaper" ? Math.min(680, availableWidth - 32) : controller.mode === "clipboard" ? Math.min(610, availableWidth - 32) : controller.mode === "control" ? Math.min(490, availableWidth - 32) : controller.mode === "network" || controller.mode === "bluetooth" ? Math.min(460, availableWidth - 32) : controller.mode === "power" ? Math.min(480, availableWidth - 32) : controller.mode === "emoji" ? Math.min(440, availableWidth - 32) : controller.mode === "switcher" ? Math.min(availableWidth - 40, 680) : controller.mode === "hover" ? Math.min(availableWidth - 32, 760) : Math.min(470, availableWidth - 32)
    property int desiredHeight: !controller ? 42 : controller.mode === "launcher" ? 410 : controller.mode === "wallpaper" ? 430 : controller.mode === "clipboard" ? 390 : controller.mode === "control" ? 660 : controller.mode === "network" ? 400 : controller.mode === "bluetooth" ? 300 : controller.mode === "power" ? 270 : controller.mode === "emoji" ? 300 : controller.mode === "switcher" ? 145 : controller.mode === "hover" ? 54 : controller.config.shell.compactHeight
    Glass {
        id: island
        anchors.fill: parent
        radius: !controller ? 22 : controller.mode === "compact" || controller.mode === "hover" ? controller.config.shell.radiusMedium : controller.config.shell.radiusLarge
        theme: window.theme; surfaceOpacity: controller ? controller.config.shell.surfaceOpacity : .88
        Behavior on width { NumberAnimation { duration: controller.config.shell.animationNormal; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: controller.config.shell.animationNormal; easing.type: Easing.OutCubic } }
        MouseArea { anchors.fill: parent; hoverEnabled: true; propagateComposedEvents: true
            onEntered: { if (controller.mode === "compact") controller.mode = "hover"; hoverClose.stop() }
            onExited: { if (controller.mode === "hover") hoverClose.restart() }
            onClicked: { if (controller.mode === "compact" || controller.mode === "hover") controller.toggle("control") }
        }
        Timer { id: hoverClose; interval: 500; onTriggered: { if (controller.mode === "hover") controller.close() } }
        Loader {
            anchors.fill: parent
            sourceComponent: !controller || !window.theme ? null : controller.mode === "launcher" ? launcher : controller.mode === "wallpaper" ? wallpaper : controller.mode === "clipboard" ? clipboardPanel : controller.mode === "control" ? control : controller.mode === "network" ? network : controller.mode === "bluetooth" ? bluetooth : controller.mode === "power" ? power : controller.mode === "emoji" ? emoji : controller.mode === "switcher" ? switcher : controller.mode === "hover" ? expanded : compact
        }
        Component { id: compact
            Row { anchors.centerIn: parent; spacing: 14
                Text { text: window.roman(Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1); color: theme.colors.accent; font { pixelSize: 13; bold: true } }
                Text { text: Qt.formatDateTime(controller.currentTime, "HH:mm"); color: theme.colors.foreground; font { pixelSize: 14; bold: true } }
                Text { text: controller.weatherIcon(controller.weather.weatherCode) + " " + (controller.weather.temperature === null ? "--°" : Math.round(controller.weather.temperature) + "°"); color: theme.colors.mutedForeground; font.pixelSize: 12 }
                Text { text: controller.networkIcon() + " " + controller.system.network.name; color: theme.colors.mutedForeground; font.pixelSize: 12; elide: Text.ElideRight; width: 95 }
                Text { visible: controller.system.battery.available; text: controller.batteryText(); color: theme.colors.mutedForeground; font.pixelSize: 12 }
            }
        }
        Component { id: expanded
            Row { anchors.centerIn: parent; spacing: 12
                Repeater { model: [1,2,3,4,5,6,7,8,9,10]
                    Rectangle { required property int modelData; width: 12; height: 12; radius: 6; color: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === modelData ? theme.colors.accent : theme.colors.surfaceVariant
                        MouseArea { anchors.fill: parent; onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + modelData + " })") }
                    }
                }
                Text { text: "Workspace " + window.roman(Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1); color: theme.colors.accent; font.pixelSize: 12 }
                Text { text: Qt.formatDateTime(controller.currentTime, "ddd, dd MMM · HH:mm"); color: theme.colors.foreground; font.pixelSize: 12 }
                Text { text: controller.weather.city + " · " + (controller.weather.temperature === null ? "--°C" : Math.round(controller.weather.temperature) + "°C"); color: theme.colors.mutedForeground; font.pixelSize: 12 }
                Text { text: controller.system.network.name; color: theme.colors.mutedForeground; font.pixelSize: 12; width: 110; elide: Text.ElideRight }
                Text { text: "BT " + controller.bluetoothIcon(); color: theme.colors.mutedForeground; font.pixelSize: 12 }
                Text { visible: controller.system.battery.available; text: controller.system.battery.percent + "% · " + controller.system.battery.status; color: theme.colors.mutedForeground; font.pixelSize: 12 }
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
