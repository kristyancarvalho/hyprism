import QtQuick
import "../components"
import ".."

Item {
    id: panel
    required property var controller
    required property var theme
    property int selectedIndex: 0
    readonly property var devices: controller.system.bluetooth.devices || []

    function command(args) {
        controller.run(args)
    }

    function activateSelected() {
        const device = devices[selectedIndex]
        if (!device) return
        command(["python3", controller.rootDir + "/scripts/system/bluetooth.py", device.connected ? "disconnect" : "connect", device.address])
    }

    focus: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            controller.close()
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            selectedIndex = navigation.wrap(selectedIndex, -1, devices.length)
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            selectedIndex = navigation.wrap(selectedIndex, 1, devices.length)
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            activateSelected()
            event.accepted = true
        }
    }

    Navigation { id: navigation }

    Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 10

        Row {
            width: parent.width

            Text {
                width: parent.width - power.width
                anchors.verticalCenter: parent.verticalCenter
                text: !controller.system.bluetooth.available ? "Bluetooth indisponível" : "Bluetooth"
                color: panel.theme.colors.foreground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeLg
                font.weight: Design.fontWeightSemibold
            }

            ShellButton {
                id: power
                visible: controller.system.bluetooth.available
                theme: panel.theme
                compact: true
                text: controller.system.bluetooth.powered ? "Desligar" : "Ligar"
                iconName: controller.bluetoothIconName()
                active: controller.system.bluetooth.powered
                pending: controller.pendingBluetooth
                onClicked: controller.toggleBluetooth()
            }
        }

        Repeater {
            model: panel.devices

            Rectangle {
                required property var modelData
                required property int index
                width: panel.width - 36
                height: 58
                radius: Design.radiusSm
                color: panel.selectedIndex === index ? panel.theme.colors.surfaceActive : pointer.containsMouse ? panel.theme.colors.surfaceHover : panel.theme.colors.surfaceVariant
                border.width: panel.selectedIndex === index ? 2 : 1
                border.color: panel.selectedIndex === index ? panel.theme.colors.accent : panel.theme.colors.outline

                StatusIcon {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 13
                    }
                    name: modelData.connected ? "bluetoothConnected" : "bluetooth"
                    iconSize: Design.iconMd
                    color: modelData.connected ? panel.theme.colors.accent : panel.theme.colors.foreground
                }

                Text {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 48
                    }
                    width: parent.width - action.width - 62
                    text: Design.safeText(modelData.name, "Dispositivo sem nome")
                    color: panel.theme.colors.foreground
                    elide: Text.ElideRight
                    font.family: Design.fontFamily
                    font.pixelSize: Design.fontSizeSm
                    font.weight: Design.fontWeightMedium
                }

                ShellButton {
                    id: action
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        rightMargin: 7
                    }
                    theme: panel.theme
                    compact: true
                    text: modelData.connected ? "Desconectar" : "Conectar"
                    onClicked: {
                        panel.selectedIndex = index
                        panel.activateSelected()
                    }
                }

                MouseArea {
                    id: pointer
                    anchors {
                        left: parent.left
                        right: action.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    hoverEnabled: true
                    onEntered: panel.selectedIndex = index
                    onClicked: panel.activateSelected()
                }
            }
        }

        Text {
            visible: controller.system.bluetooth.available && panel.devices.length === 0
            text: "Nenhum dispositivo pareado"
            color: panel.theme.colors.mutedForeground
            font.family: Design.fontFamily
            font.pixelSize: Design.fontSizeSm
        }
    }

    Component.onCompleted: forceActiveFocus()
}
