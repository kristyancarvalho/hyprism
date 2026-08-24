import QtQuick
import QtQuick.Layouts
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
            navigation.useKeyboard()
            selectedIndex = navigation.wrap(selectedIndex, -1, devices.length)
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            navigation.useKeyboard()
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

        RowLayout {
            width: parent.width
            spacing: Design.spacingSm

            Text {
                Layout.fillWidth: true
                text: !controller.system.bluetooth.available ? "Bluetooth indisponível" : "Bluetooth"
                color: panel.theme.colors.foreground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeLg
                font.weight: Design.fontWeightSemibold
                elide: Text.ElideRight
            }

            ShellButton {
                id: power
                Layout.preferredWidth: implicitWidth
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

        ListView {
            id: deviceList
            width: parent.width
            height: Math.max(58, parent.height - y)
            clip: true
            model: panel.devices
            currentIndex: panel.selectedIndex
            spacing: 6
            onCurrentIndexChanged: if (currentIndex >= 0) positionViewAtIndex(currentIndex, ListView.Contain)

            SelectionHighlight {
                parent: deviceList.contentItem
                theme: panel.theme
                target: deviceList.currentItem
                active: navigation.keyboardNavigation && panel.devices.length > 0
            }

            delegate: Item {
                id: bluetoothDelegate
                required property var modelData
                required property int index
                width: ListView.view.width
                height: 58
                z: 2

                DelegateSurface {
                    host: deviceList.contentItem
                    target: bluetoothDelegate
                    theme: panel.theme
                    hovered: pointer.containsMouse && !navigation.keyboardNavigation
                }

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
                    onEntered: {
                        navigation.usePointer()
                        panel.selectedIndex = index
                    }
                    onClicked: {
                        panel.selectedIndex = index
                        panel.activateSelected()
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: controller.system.bluetooth.available && parent.count === 0
                text: "Nenhum dispositivo pareado"
                color: panel.theme.colors.mutedForeground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeSm
            }
        }
    }

    Component.onCompleted: forceActiveFocus()
}
