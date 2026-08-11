import QtQuick
import Quickshell
import Quickshell.Wayland
import "../components"

PanelWindow {
    id: widgetWindow
    required property var shellScreen
    required property var controller
    required property var theme
    screen: shellScreen
    visible: shellScreen !== null
    anchors { right: true; top: true }
    margins { top: 96; right: 20 }
    implicitWidth: shellScreen ? Math.min(280, Math.max(244, shellScreen.width * .26)) : 260
    implicitHeight: stack.implicitHeight
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Column {
        id: stack
        width: parent.width
        spacing: 10

        Glass {
            theme: widgetWindow.theme
            surfaceOpacity: .82
            width: parent.width
            height: 92
            radius: 20
            visible: controller.config.shell.widgets.clock

            Column {
                anchors.centerIn: parent
                spacing: 3
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: controller.formattedDate("HH:mm"); color: theme.colors.foreground; font { pixelSize: 30; bold: true } }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: controller.formattedDate("dddd, dd MMM"); color: theme.colors.mutedForeground; font.pixelSize: 11 }
            }
        }

        Glass {
            theme: widgetWindow.theme
            surfaceOpacity: .82
            width: parent.width
            height: 86
            radius: 20
            visible: controller.config.shell.widgets.weather

            Row {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 14
                ShellIcon { anchors.verticalCenter: parent.verticalCenter; name: controller.weatherIconName(controller.weather.weatherCode); iconSize: 38; framed: true; frameColor: theme.colors.surfaceVariant }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 68
                    spacing: 2
                    Text { width: parent.width; text: controller.weather.temperature === null ? "Aguardando clima" : Math.round(controller.weather.temperature) + "°C"; color: theme.colors.foreground; font { pixelSize: 17; bold: true } elide: Text.ElideRight }
                    Text { width: parent.width; text: controller.weather.city; color: theme.colors.mutedForeground; font.pixelSize: 11; elide: Text.ElideRight }
                    Text { width: parent.width; visible: controller.weather.temperature !== null && controller.weather.minimum !== null && controller.weather.minimum !== undefined; text: "Mín. " + Math.round(controller.weather.minimum) + "°  ·  Máx. " + Math.round(controller.weather.maximum) + "°"; color: theme.colors.mutedForeground; font.pixelSize: 9 }
                }
            }
        }

        Glass {
            theme: widgetWindow.theme
            surfaceOpacity: .82
            width: parent.width
            height: controller.system.battery.available ? 128 : 104
            radius: 20
            visible: controller.config.shell.widgets.system

            Column {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 8

                Row {
                    width: parent.width
                    Text { width: parent.width - cpuValue.width; text: "Processador"; color: theme.colors.foreground; font { pixelSize: 11; weight: Font.Medium } }
                    Text { id: cpuValue; text: controller.system.cpu.percent + "%"; color: theme.colors.mutedForeground; font.pixelSize: 10 }
                }
                Rectangle {
                    width: parent.width; height: 5; radius: 3; color: theme.colors.surfaceVariant
                    Rectangle { width: parent.width * Math.max(0, Math.min(100, controller.system.cpu.percent)) / 100; height: parent.height; radius: 3; color: theme.colors.accent }
                }
                Row {
                    width: parent.width
                    Text { width: parent.width - memoryValue.width; text: "Memória"; color: theme.colors.foreground; font { pixelSize: 11; weight: Font.Medium } }
                    Text { id: memoryValue; text: controller.system.memory.percent + "%"; color: theme.colors.mutedForeground; font.pixelSize: 10 }
                }
                Rectangle {
                    width: parent.width; height: 5; radius: 3; color: theme.colors.surfaceVariant
                    Rectangle { width: parent.width * Math.max(0, Math.min(100, controller.system.memory.percent)) / 100; height: parent.height; radius: 3; color: theme.colors.secondary }
                }
                Row {
                    visible: controller.system.battery.available
                    width: parent.width
                    spacing: 7
                    ShellIcon { name: controller.batteryIconName(); iconSize: 16 }
                    Text { text: "Bateria"; color: theme.colors.foreground; font.pixelSize: 10 }
                    Item { width: Math.max(0, parent.width - batteryValue.width - 74); height: 1 }
                    Text { id: batteryValue; text: controller.system.battery.percent + "%"; color: theme.colors.mutedForeground; font.pixelSize: 10 }
                }
            }
        }

        Glass {
            theme: widgetWindow.theme
            surfaceOpacity: .82
            width: parent.width
            height: controller.system.media && controller.system.media.available ? 98 : 0
            radius: 20
            visible: height > 0 && controller.config.shell.widgets.media

            Row {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 11
                Rectangle {
                    width: 62; height: 62; radius: 14; color: theme.colors.surfaceVariant; clip: true
                    Image { id: mediaArt; anchors.fill: parent; source: controller.system.media.artUrl || ""; fillMode: Image.PreserveAspectCrop; visible: source.toString().length > 0 }
                    ShellIcon { anchors.centerIn: parent; visible: !mediaArt.visible; name: "audio-x-generic"; iconSize: 28 }
                }
                Column {
                    width: parent.width - 73
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Text { width: parent.width; text: controller.system.media.title; elide: Text.ElideRight; color: theme.colors.foreground; font { pixelSize: 11; bold: true } }
                    Text { width: parent.width; text: controller.system.media.artist; elide: Text.ElideRight; color: theme.colors.mutedForeground; font.pixelSize: 10 }
                    Row {
                        spacing: 6
                        ShellButton { theme: widgetWindow.theme; compact: true; iconName: "media-skip-backward"; onClicked: controller.run(["playerctl", "previous"]) }
                        ShellButton { theme: widgetWindow.theme; compact: true; iconName: controller.system.media.status === "Playing" ? "media-playback-pause" : "media-playback-start"; onClicked: controller.run(["playerctl", "play-pause"]) }
                        ShellButton { theme: widgetWindow.theme; compact: true; iconName: "media-skip-forward"; onClicked: controller.run(["playerctl", "next"]) }
                    }
                }
            }
        }
    }
}
