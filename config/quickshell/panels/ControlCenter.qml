import QtQuick
import QtQuick.Controls
import "../components"

Item {
    id: panel
    required property var controller
    required property var theme
    required property var notificationServer
    function command(text) { controller.run(["sh", "-lc", text]) }
    function setVolume(value) { command("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + value / 100); controller.showOsd("Volume", value + "%") }
    function setBrightness(value) { command("brightnessctl set " + value + "%"); controller.showOsd("Brilho", value + "%") }
    focus: true
    Keys.onPressed: event => { if (event.key === Qt.Key_Escape) { controller.close(); event.accepted = true } }
    Flickable {
        anchors.fill: parent; anchors.margins: 18; contentHeight: body.implicitHeight; clip: true
        Column {
            id: body; width: parent.width; spacing: 12
            Row { width: parent.width
                Text { width: parent.width - power.width; anchors.verticalCenter: parent.verticalCenter; text: controller.formattedDate("dddd · dd MMMM  HH:mm"); color: panel.theme.colors.foreground; font { pixelSize: 16; bold: true } }
                ShellButton { id: power; theme: panel.theme; text: "Energia"; iconName: "system-shutdown"; compact: true; onClicked: controller.open("power") }
            }
            Grid { width: parent.width; columns: 2; spacing: 8
                ActionButton { width: (parent.width - 8) / 2; theme: panel.theme; label: controller.networkLabel(); iconName: controller.networkIconName(); active: controller.system.network.enabled; onClicked: controller.open("network") }
                ActionButton { width: (parent.width - 8) / 2; theme: panel.theme; label: !controller.system.bluetooth.available ? "Bluetooth indisponível" : controller.system.bluetooth.connected ? "Bluetooth conectado" : controller.system.bluetooth.powered ? "Bluetooth ligado" : "Bluetooth desligado"; iconName: controller.bluetoothIconName(); active: controller.system.bluetooth.powered; onClicked: controller.open("bluetooth") }
                ActionButton { width: (parent.width - 8) / 2; theme: panel.theme; label: "Modo noturno"; iconName: "weather-clear-night"; active: controller.nightMode; onClicked: controller.toggleNightMode() }
                ActionButton { width: (parent.width - 8) / 2; theme: panel.theme; label: "Economia de energia"; iconName: "battery-good"; active: controller.powerSaver; onClicked: controller.togglePowerSaver() }
            }
            SliderRow { width: parent.width; theme: panel.theme; label: controller.system.audio.muted ? "Mudo" : "Volume"; iconName: controller.volumeIconName(); value: controller.system.audio.percent; available: controller.system.audio.available; onChanged: value => panel.setVolume(value) }
            SliderRow { width: parent.width; theme: panel.theme; label: "Microfone"; iconName: controller.microphoneIconName(); value: controller.system.microphone.percent; available: controller.system.microphone.available; onChanged: value => panel.command("wpctl set-volume @DEFAULT_AUDIO_SOURCE@ " + value / 100) }
            SliderRow { width: parent.width; theme: panel.theme; label: "Brilho"; iconName: "display-brightness"; value: controller.system.brightness.percent; available: controller.system.brightness.available; onChanged: value => panel.setBrightness(value) }
            Rectangle { width: parent.width; height: 1; color: panel.theme.colors.outline }
            Item { width: parent.width; height: controller.system.media && controller.system.media.available ? 74 : 0; visible: height > 0
                Column { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 145
                    Text { text: controller.system.media ? controller.system.media.title : ""; width: parent.width; elide: Text.ElideRight; color: panel.theme.colors.foreground; font { pixelSize: 13; bold: true } }
                    Text { text: controller.system.media ? controller.system.media.artist : ""; width: parent.width; elide: Text.ElideRight; color: panel.theme.colors.mutedForeground; font.pixelSize: 11 }
                }
                Row { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 4
                    ShellButton { theme: panel.theme; compact: true; iconName: "media-skip-backward"; onClicked: panel.command("playerctl previous") }
                    ShellButton { theme: panel.theme; compact: true; iconName: controller.system.media && controller.system.media.status === "Playing" ? "media-playback-pause" : "media-playback-start"; onClicked: panel.command("playerctl play-pause") }
                    ShellButton { theme: panel.theme; compact: true; iconName: "media-skip-forward"; onClicked: panel.command("playerctl next") }
                }
            }
            Text { text: "Notificações"; color: panel.theme.colors.foreground; font { pixelSize: 14; bold: true } }
            NotificationHistory { width: parent.width; controller: panel.controller; theme: panel.theme; server: panel.notificationServer }
        }
    }
}
