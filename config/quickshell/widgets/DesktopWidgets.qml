import QtQuick
import QtQuick.Controls
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
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: controller.formattedDate("HH:mm"); color: theme.colors.foreground; font { pixelSize: 31; bold: true } }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: controller.formattedDate("ddd, dd MMM"); color: theme.colors.mutedForeground; font.pixelSize: 11 }
            }
        }
        Glass { theme: widgetWindow.theme; surfaceOpacity: .74; width: parent.width; height: 70; radius: 17; visible: controller.config.shell.widgets.weather
            Row { anchors.fill: parent; anchors.margins: 14; spacing: 12
                Text { anchors.verticalCenter: parent.verticalCenter; text: controller.weatherIcon(controller.weather.weatherCode); color: theme.colors.accent; font.pixelSize: 25 }
                Column { anchors.verticalCenter: parent.verticalCenter
                    Text { text: controller.weather.temperature === null ? "Tempo indisponível" : Math.round(controller.weather.temperature) + "°C"; color: theme.colors.foreground; font { pixelSize: 17; bold: true } }
                    Text { text: controller.weather.city; color: theme.colors.mutedForeground; font.pixelSize: 10; width: 150; elide: Text.ElideRight }
                }
            }
        }
        Glass { theme: widgetWindow.theme; surfaceOpacity: .74; width: parent.width; height: 84; radius: 17; visible: controller.config.shell.widgets.system
            Column { anchors.fill: parent; anchors.margins: 13; spacing: 6
                Text { text: "CPU  " + controller.system.cpu.percent + "%   ·   Memória  " + controller.system.memory.percent + "%"; color: theme.colors.foreground; font.pixelSize: 11 }
                Rectangle { width: parent.width; height: 5; radius: 3; color: theme.colors.surfaceVariant; Rectangle { width: parent.width * controller.system.memory.percent / 100; height: parent.height; radius: 3; color: theme.colors.accent } }
                Text { visible: controller.system.gpu && controller.system.gpu.available; text: "GPU  " + controller.system.gpu.percent + "%"; color: theme.colors.mutedForeground; font.pixelSize: 10 }
                Text { visible: controller.system.battery.available; text: "Bateria  " + controller.system.battery.percent + "%"; color: theme.colors.mutedForeground; font.pixelSize: 10 }
            }
        }
        Glass { theme: widgetWindow.theme; surfaceOpacity: .74; width: parent.width; height: controller.system.media && controller.system.media.available ? 92 : 0; radius: 17; visible: height > 0 && controller.config.shell.widgets.media
            Row { anchors.fill: parent; anchors.margins: 10; spacing: 9
                Rectangle { width: 56; height: 56; radius: 10; color: theme.colors.surfaceVariant; clip: true
                    Image { id: mediaArt; anchors.fill: parent; source: controller.system.media.artUrl || ""; fillMode: Image.PreserveAspectCrop; visible: source.toString().length > 0 }
                    Text { anchors.centerIn: parent; visible: !mediaArt.visible; text: "♪"; color: theme.colors.accent; font.pixelSize: 24 }
                }
                Column { width: parent.width - 65; spacing: 3
                    Text { text: controller.system.media.title; width: parent.width; elide: Text.ElideRight; color: theme.colors.foreground; font { pixelSize: 11; bold: true } }
                    Text { text: controller.system.media.artist; width: parent.width; elide: Text.ElideRight; color: theme.colors.mutedForeground; font.pixelSize: 10 }
                    Row { spacing: 2
                        Button { text: "‹"; width: 30; height: 27; onClicked: controller.run(["playerctl", "previous"]) }
                        Button { text: controller.system.media.status === "Playing" ? "Ⅱ" : "▶"; width: 34; height: 27; onClicked: controller.run(["playerctl", "play-pause"]) }
                        Button { text: "›"; width: 30; height: 27; onClicked: controller.run(["playerctl", "next"]) }
                    }
                }
            }
        }
    }
}
