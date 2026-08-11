import QtQuick
import QtQuick.Controls
import "../components"

Item {
    id: panel
    required property var controller
    required property var theme
    function command(args) { controller.run(args) }
    focus: true
    Keys.onPressed: event => { if (event.key === Qt.Key_Escape) { controller.close(); event.accepted = true } }
    Column { anchors.fill: parent; anchors.margins: 18; spacing: 10
        Row { width: parent.width
            Text { width: parent.width - power.width; anchors.verticalCenter: parent.verticalCenter; text: !controller.system.bluetooth.available ? "Bluetooth indisponível" : "Bluetooth"; color: panel.theme.colors.foreground; font { pixelSize: 18; bold: true } }
            ShellButton { id: power; visible: controller.system.bluetooth.available; theme: panel.theme; compact: true; text: controller.system.bluetooth.powered ? "Desligar" : "Ligar"; iconName: controller.bluetoothIconName(); onClicked: panel.command(["python3", controller.rootDir + "/scripts/system/bluetooth.py", "power", controller.system.bluetooth.powered ? "off" : "on"]) }
        }
        Repeater { model: controller.system.bluetooth.devices
            Rectangle { required property var modelData; width: panel.width - 36; height: 58; radius: 14; color: panel.theme.colors.surfaceVariant; border.width: 1; border.color: panel.theme.colors.outline
                ShellIcon { anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 12 } name: "bluetooth"; iconSize: 22 }
                Text { anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 48 } width: parent.width - action.width - 62; text: modelData.name; color: panel.theme.colors.foreground; elide: Text.ElideRight; font { pixelSize: 12; weight: Font.Medium } }
                ShellButton { id: action; anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 7 } theme: panel.theme; compact: true; text: modelData.connected ? "Desconectar" : "Conectar"; onClicked: panel.command(["python3", controller.rootDir + "/scripts/system/bluetooth.py", modelData.connected ? "disconnect" : "connect", modelData.address]) }
            }
        }
        Text { visible: controller.system.bluetooth.available && controller.system.bluetooth.devices.length === 0; text: "Nenhum dispositivo pareado"; color: panel.theme.colors.mutedForeground }
    }
}
