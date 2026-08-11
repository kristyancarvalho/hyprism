import QtQuick
import QtQuick.Controls
import "../components"
import ".."

Item {
    id: panel
    required property var controller
    required property var theme
    required property var notificationServer
    property int selectedAction: 0

    function command(text) {
        controller.run(["sh", "-lc", text])
    }

    function setVolume(value) {
        command("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + value / 100)
        controller.showOsd("Volume", value + "%")
    }

    function setBrightness(value) {
        command("brightnessctl set " + value + "%")
        controller.showOsd("Brilho", value + "%")
    }

    function focusAction(index) {
        selectedAction = navigation.clamp(index, 4)
        const actions = [networkAction, bluetoothAction, nightAction, saverAction]
        actions[selectedAction].forceActiveFocus()
    }

    focus: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            controller.close()
            event.accepted = true
        } else if (event.key === Qt.Key_Left) {
            focusAction(navigation.grid(selectedAction, -1, 0, 2, 4))
            event.accepted = true
        } else if (event.key === Qt.Key_Right) {
            focusAction(navigation.grid(selectedAction, 1, 0, 2, 4))
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            focusAction(navigation.grid(selectedAction, 0, -1, 2, 4))
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            focusAction(navigation.grid(selectedAction, 0, 1, 2, 4))
            event.accepted = true
        }
    }

    Navigation { id: navigation }

    Flickable {
        anchors.fill: parent
        anchors.margins: 18
        contentHeight: body.implicitHeight
        clip: true

        Column {
            id: body
            width: parent.width
            spacing: 12

            Row {
                width: parent.width

                Text {
                    width: parent.width - power.width
                    anchors.verticalCenter: parent.verticalCenter
                    text: controller.formattedDate("dddd · dd MMMM  HH:mm")
                    color: panel.theme.colors.foreground
                    font.family: Design.fontFamily
                    font.pixelSize: Design.fontSizeLg
                    font.weight: Design.fontWeightSemibold
                }

                ShellButton {
                    id: power
                    theme: panel.theme
                    text: "Energia"
                    iconName: "power"
                    compact: true
                    onClicked: controller.open("power")
                }
            }

            Grid {
                width: parent.width
                columns: 2
                spacing: 8

                ActionButton {
                    id: networkAction
                    width: (parent.width - 8) / 2
                    theme: panel.theme
                    label: controller.networkLabel()
                    iconName: controller.networkIconName()
                    active: controller.system.network.enabled
                    onActiveFocusChanged: if (activeFocus) panel.selectedAction = 0
                    onClicked: controller.open("network")
                }

                ActionButton {
                    id: bluetoothAction
                    width: (parent.width - 8) / 2
                    theme: panel.theme
                    label: !controller.system.bluetooth.available ? "Bluetooth indisponível" : controller.system.bluetooth.connected ? "Bluetooth conectado" : controller.system.bluetooth.powered ? "Bluetooth ligado" : "Bluetooth desligado"
                    iconName: controller.bluetoothIconName()
                    active: controller.system.bluetooth.powered
                    onActiveFocusChanged: if (activeFocus) panel.selectedAction = 1
                    onClicked: controller.open("bluetooth")
                }

                ActionButton {
                    id: nightAction
                    width: (parent.width - 8) / 2
                    theme: panel.theme
                    label: "Modo noturno"
                    iconName: "night"
                    active: controller.nightMode
                    onActiveFocusChanged: if (activeFocus) panel.selectedAction = 2
                    onClicked: controller.toggleNightMode()
                }

                ActionButton {
                    id: saverAction
                    width: (parent.width - 8) / 2
                    theme: panel.theme
                    label: "Economia de energia"
                    iconName: "powerSaver"
                    active: controller.powerSaver
                    onActiveFocusChanged: if (activeFocus) panel.selectedAction = 3
                    onClicked: controller.togglePowerSaver()
                }
            }

            SliderRow {
                width: parent.width
                theme: panel.theme
                label: controller.system.audio.muted ? "Mudo" : "Volume"
                iconName: controller.volumeIconName()
                value: controller.system.audio.percent
                available: controller.system.audio.available
                onChanged: value => panel.setVolume(value)
            }

            SliderRow {
                width: parent.width
                theme: panel.theme
                label: "Microfone"
                iconName: controller.microphoneIconName()
                value: controller.system.microphone.percent
                available: controller.system.microphone.available
                onChanged: value => panel.command("wpctl set-volume @DEFAULT_AUDIO_SOURCE@ " + value / 100)
            }

            SliderRow {
                width: parent.width
                theme: panel.theme
                label: "Brilho"
                iconName: "brightness"
                value: controller.system.brightness.percent
                available: controller.system.brightness.available
                onChanged: value => panel.setBrightness(value)
            }

            Rectangle { width: parent.width; height: 1; color: panel.theme.colors.outline }

            MediaStrip {
                width: parent.width
                height: controller.mediaAvailable() ? 64 : 0
                visible: height > 0
                controller: panel.controller
                theme: panel.theme
            }

            Row {
                width: parent.width

                StatusIcon { name: "notification"; iconSize: Design.iconSm; color: panel.theme.colors.accent }
                Text {
                    text: "Notificações"
                    color: panel.theme.colors.foreground
                    font.family: Design.fontFamily
                    font.pixelSize: Design.fontSizeMd
                    font.weight: Design.fontWeightSemibold
                }
            }

            NotificationHistory {
                width: parent.width
                controller: panel.controller
                theme: panel.theme
                server: panel.notificationServer
            }
        }
    }
}
