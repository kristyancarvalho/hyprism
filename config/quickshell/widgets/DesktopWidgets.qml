import QtQuick
import Quickshell
import Quickshell.Wayland
import "../components"

PanelWindow {
    id: widgetWindow
    required property var controller
    required property var theme
    anchors { right: true; top: true }
    margins { top: 104; right: 24 }
    implicitWidth: 222
    implicitHeight: stack.implicitHeight
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    Column {
        id: stack; width: parent.width; spacing: 9
        Glass { theme: widgetWindow.theme; surfaceOpacity: .74; width: parent.width; height: 84; radius: 17; visible: controller.config.shell.widgets.clock
            Column { anchors.centerIn: parent; spacing: 2
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDateTime(new Date(), "HH:mm"); color: theme.colors.foreground; font { pixelSize: 31; bold: true } }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDateTime(new Date(), "ddd, dd MMM"); color: theme.colors.mutedForeground; font.pixelSize: 11 }
            }
        }
        Glass { theme: widgetWindow.theme; surfaceOpacity: .74; width: parent.width; height: 70; radius: 17; visible: controller.config.shell.widgets.weather
            Row { anchors.fill: parent; anchors.margins: 14; spacing: 12
                Text { anchors.verticalCenter: parent.verticalCenter; text: controller.weatherIcon(controller.weather.weatherCode); color: theme.colors.accent; font.pixelSize: 25 }
                Column { anchors.verticalCenter: parent.verticalCenter
                    Text { text: controller.weather.temperature === null ? "Weather unavailable" : Math.round(controller.weather.temperature) + "°C"; color: theme.colors.foreground; font { pixelSize: 17; bold: true } }
                    Text { text: controller.weather.city; color: theme.colors.mutedForeground; font.pixelSize: 10; width: 150; elide: Text.ElideRight }
                }
            }
        }
        Glass { theme: widgetWindow.theme; surfaceOpacity: .74; width: parent.width; height: 84; radius: 17; visible: controller.config.shell.widgets.system
            Column { anchors.fill: parent; anchors.margins: 13; spacing: 6
                Text { text: "CPU  " + controller.system.cpu.percent + "%   ·   Memory  " + controller.system.memory.percent + "%"; color: theme.colors.foreground; font.pixelSize: 11 }
                Rectangle { width: parent.width; height: 5; radius: 3; color: theme.colors.surfaceVariant; Rectangle { width: parent.width * controller.system.memory.percent / 100; height: parent.height; radius: 3; color: theme.colors.accent } }
                Text { visible: controller.system.gpu && controller.system.gpu.available; text: "GPU  " + controller.system.gpu.percent + "%"; color: theme.colors.mutedForeground; font.pixelSize: 10 }
                Text { visible: controller.system.battery.available; text: "Battery  " + controller.system.battery.percent + "%"; color: theme.colors.mutedForeground; font.pixelSize: 10 }
            }
        }
        Glass { theme: widgetWindow.theme; surfaceOpacity: .74; width: parent.width; height: controller.system.media && controller.system.media.available ? 70 : 0; radius: 17; visible: height > 0 && controller.config.shell.widgets.media
            Column { anchors.fill: parent; anchors.margins: 13; spacing: 4
                Text { text: controller.system.media ? controller.system.media.title : ""; width: parent.width; elide: Text.ElideRight; color: theme.colors.foreground; font { pixelSize: 11; bold: true } }
                Text { text: controller.system.media ? controller.system.media.artist : ""; width: parent.width; elide: Text.ElideRight; color: theme.colors.mutedForeground; font.pixelSize: 10 }
            }
        }
    }
}
