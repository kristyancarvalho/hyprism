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
    readonly property int availablePillCount: (volumeControl.available ? 1 : 0) + (microphoneControl.available ? 1 : 0) + (brightnessControl.available ? 1 : 0)

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
        interval: 240
        onTriggered: controller.run([panel.controller.rootDir + "/scripts/system/action", "brightness-set", String(panel.pendingBrightnessValue)])
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

                BatteryStatus {
                    Layout.preferredWidth: implicitWidth
                    theme: panel.theme
                    controller: panel.controller
                    showPercentage: true
                    filled: true
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

                SplitActionButton {
                    id: networkAction
                    width: (parent.width - 8) / 2
                    theme: panel.theme
                    label: controller.networkLabel()
                    iconName: controller.networkIconName()
                    active: controller.system.network.wifiEnabled
                    available: controller.system.network.available
                    toggleAvailable: controller.system.network.wifiAvailable
                    pending: controller.pendingWifi
                    onFocusEntered: panel.selectedAction = 0
                    onPrimaryClicked: controller.toggleWifi()
                    onDetailClicked: controller.openNetwork(controller.targetScreenName)
                }

                SplitActionButton {
                    id: bluetoothAction
                    width: (parent.width - 8) / 2
                    theme: panel.theme
                    label: !controller.system.bluetooth.available ? "Bluetooth indisponível" : controller.system.bluetooth.connected ? "Bluetooth conectado" : controller.system.bluetooth.powered ? "Bluetooth ligado" : "Bluetooth desligado"
                    iconName: controller.bluetoothIconName()
                    active: controller.system.bluetooth.powered
                    available: controller.system.bluetooth.available
                    pending: controller.pendingBluetooth
                    onFocusEntered: panel.selectedAction = 1
                    onPrimaryClicked: controller.toggleBluetooth()
                    onDetailClicked: controller.openBluetooth(controller.targetScreenName)
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

            Row {
                width: parent.width
                height: panel.availablePillCount > 0 ? 52 : 0
                visible: panel.availablePillCount > 0
                spacing: Design.spacingSm

                LevelPill {
                    id: volumeControl
                    width: (parent.width - Math.max(0, panel.availablePillCount - 1) * parent.spacing) / Math.max(1, panel.availablePillCount)
                    theme: panel.theme
                    label: "Volume"
                    iconName: controller.volumeIconName()
                    value: controller.system.audio.percent
                    available: controller.system.audio.available
                    muted: controller.system.audio.muted
                    muteable: true
                    onFocusEntered: panel.selectedAction = panel.controls().indexOf(volumeControl)
                    onChanged: value => panel.setVolume(value)
                    onMuteClicked: panel.command("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
                }

                LevelPill {
                    id: microphoneControl
                    width: (parent.width - Math.max(0, panel.availablePillCount - 1) * parent.spacing) / Math.max(1, panel.availablePillCount)
                    theme: panel.theme
                    label: "Microfone"
                    iconName: controller.microphoneIconName()
                    value: controller.system.microphone.percent
                    available: controller.system.microphone.available
                    muted: controller.system.microphone.muted
                    muteable: true
                    onFocusEntered: panel.selectedAction = panel.controls().indexOf(microphoneControl)
                    onChanged: value => panel.command("wpctl set-volume @DEFAULT_AUDIO_SOURCE@ " + value / 100)
                    onMuteClicked: panel.command("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")
                }

                LevelPill {
                    id: brightnessControl
                    width: (parent.width - Math.max(0, panel.availablePillCount - 1) * parent.spacing) / Math.max(1, panel.availablePillCount)
                    theme: panel.theme
                    label: "Brilho"
                    iconName: "brightness"
                    value: controller.system.brightness.percent
                    available: controller.system.brightness.available
                    onFocusEntered: panel.selectedAction = panel.controls().indexOf(brightnessControl)
                    onChanged: value => panel.setBrightness(value)
                }
            }

            Rectangle {
                width: parent.width
                height: controller.recording ? 54 : 0
                visible: controller.recording
                radius: Design.radiusSm
                color: panel.theme.colors.surfaceVariant

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Design.spacingSm
                    spacing: Design.spacingSm

                    Rectangle {
                        Layout.preferredWidth: 8
                        Layout.preferredHeight: 8
                        radius: 4
                        color: panel.theme.colors.warning
                    }

                    Text {
                        Layout.fillWidth: true
                        text: controller.recordingElapsedText()
                        color: panel.theme.colors.foreground
                        font.family: Design.fontFamily
                        font.pixelSize: Design.fontSizeSm
                        font.weight: Design.fontWeightSemibold
                    }

                    ShellButton {
                        id: stopRecordingButton
                        theme: panel.theme
                        text: "Parar"
                        iconName: "close"
                        compact: true
                        warning: true
                        onClicked: controller.stopRecording()
                    }
                }
            }

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
