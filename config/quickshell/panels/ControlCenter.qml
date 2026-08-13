import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"
import ".."

Item {
    id: panel
    required property var controller
    required property var theme
    required property var notificationServer
    property int selectedAction: 0
    property int pendingBrightnessValue: 0

    function command(text) {
        controller.run(["sh", "-lc", text])
    }

    function setVolume(value) {
        command("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + value / 100)
        controller.showOsd("Volume", value + "%")
    }

    function setBrightness(value) {
        pendingBrightnessValue = Math.round(Design.clamp(value, 0, 100))
        brightnessDebounce.restart()
    }

    function controls() {
        const items = [networkAction, bluetoothAction, nightAction, saverAction]
        if (volumeControl.available) items.push(volumeControl)
        if (microphoneControl.available) items.push(microphoneControl)
        if (brightnessControl.available) items.push(brightnessControl)
        return items
    }

    function focusAction(index) {
        const items = controls()
        selectedAction = navigation.clamp(index, items.length)
        const target = items[selectedAction]
        if (!target) return
        if (target.takeFocus) target.takeFocus()
        else target.forceActiveFocus()
    }

    function takeInitialFocus() {
        const items = controls()
        for (let i = 0; i < items.length; i++) {
            if (items[i].available !== false) {
                focusAction(i)
                return
            }
        }
        forceActiveFocus()
    }

    function initialFocusReady() {
        const items = controls()
        for (let index = 0; index < items.length; index++) {
            if (items[index].activeFocus || items[index].controlFocused) return true
        }
        return activeFocus
    }

    focus: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            controller.close()
            event.accepted = true
        } else if (event.key === Qt.Key_Left && selectedAction < 4) {
            focusAction(navigation.grid(selectedAction, -1, 0, 2, 4))
            event.accepted = true
        } else if (event.key === Qt.Key_Right && selectedAction < 4) {
            focusAction(navigation.grid(selectedAction, 1, 0, 2, 4))
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            focusAction(selectedAction < 4 ? navigation.grid(selectedAction, 0, -1, 2, 4) : selectedAction - 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            focusAction(selectedAction < 2 ? selectedAction + 2 : selectedAction < 4 ? 4 : selectedAction + 1)
            event.accepted = true
        }
    }

    Navigation { id: navigation }

    Timer {
        id: brightnessDebounce
        interval: 75
        onTriggered: controller.run(["brightnessctl", "set", panel.pendingBrightnessValue + "%"])
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: 18
        contentHeight: body.implicitHeight
        clip: true

        Column {
            id: body
            width: parent.width
            spacing: 12

            RowLayout {
                width: parent.width
                spacing: Design.spacingMd

                Text {
                    Layout.fillWidth: true
                    text: controller.formattedDate("dddd · dd MMMM  HH:mm")
                    color: panel.theme.colors.foreground
                    font.family: Design.fontFamily
                    font.pixelSize: Design.fontSizeLg
                    font.weight: Design.fontWeightSemibold
                    elide: Text.ElideRight
                }

                ShellButton {
                    id: power
                    Layout.preferredWidth: implicitWidth
                    theme: panel.theme
                    text: "Energia"
                    iconName: "power"
                    compact: true
                    onClicked: controller.openPowerMenu(controller.targetScreenName)
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
                    available: controller.system.network.available
                    onActiveFocusChanged: if (activeFocus) panel.selectedAction = 0
                    onClicked: controller.openNetwork(controller.targetScreenName)
                }

                ActionButton {
                    id: bluetoothAction
                    width: (parent.width - 8) / 2
                    theme: panel.theme
                    label: !controller.system.bluetooth.available ? "Bluetooth indisponível" : controller.system.bluetooth.connected ? "Bluetooth conectado" : controller.system.bluetooth.powered ? "Bluetooth ligado" : "Bluetooth desligado"
                    iconName: controller.bluetoothIconName()
                    active: controller.system.bluetooth.powered
                    available: controller.system.bluetooth.available
                    pending: controller.pendingBluetooth
                    onActiveFocusChanged: if (activeFocus) panel.selectedAction = 1
                    onClicked: controller.openBluetooth(controller.targetScreenName)
                }

                ActionButton {
                    id: nightAction
                    width: (parent.width - 8) / 2
                    theme: panel.theme
                    label: controller.system.nightMode.available ? "Modo noturno" : "Modo noturno indisponível"
                    iconName: "night"
                    active: controller.nightMode
                    available: controller.system.nightMode.available
                    pending: controller.pendingNightMode
                    onActiveFocusChanged: if (activeFocus) panel.selectedAction = 2
                    onClicked: controller.toggleNightMode()
                }

                ActionButton {
                    id: saverAction
                    width: (parent.width - 8) / 2
                    theme: panel.theme
                    label: controller.system.powerProfile.available ? "Economia de energia" : "Energia indisponível"
                    iconName: "powerSaver"
                    active: controller.powerSaver
                    available: controller.system.powerProfile.available
                    pending: controller.pendingPowerSaver
                    onActiveFocusChanged: if (activeFocus) panel.selectedAction = 3
                    onClicked: controller.togglePowerSaver()
                }
            }

            SliderRow {
                id: volumeControl
                width: parent.width
                theme: panel.theme
                label: controller.system.audio.muted ? "Mudo" : "Volume"
                iconName: controller.volumeIconName()
                value: controller.system.audio.percent
                available: controller.system.audio.available
                onFocusEntered: panel.selectedAction = 4
                onChanged: value => panel.setVolume(value)
            }

            SliderRow {
                id: microphoneControl
                width: parent.width
                theme: panel.theme
                label: "Microfone"
                iconName: controller.microphoneIconName()
                value: controller.system.microphone.percent
                available: controller.system.microphone.available
                onFocusEntered: panel.selectedAction = panel.controls().indexOf(microphoneControl)
                onChanged: value => panel.command("wpctl set-volume @DEFAULT_AUDIO_SOURCE@ " + value / 100)
            }

            SliderRow {
                id: brightnessControl
                width: parent.width
                theme: panel.theme
                label: "Brilho"
                iconName: "brightness"
                value: controller.system.brightness.percent
                available: controller.system.brightness.available
                onFocusEntered: panel.selectedAction = panel.controls().indexOf(brightnessControl)
                onChanged: value => panel.setBrightness(value)
            }

            Rectangle { width: parent.width; height: 1; color: panel.theme.colors.borderSubtle; opacity: .55 }

            MediaStrip {
                width: parent.width
                height: controller.mediaAvailable() ? 64 : 0
                visible: height > 0
                controller: panel.controller
                theme: panel.theme
            }

            Row {
                width: parent.width
                spacing: Design.spacingXs

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

    Component.onCompleted: takeInitialFocus()
}
