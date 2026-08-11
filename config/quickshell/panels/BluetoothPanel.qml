import QtQuick
import QtQuick.Controls

Item {
    id: panel
    required property var controller
    required property var theme
    function command(args) { controller.run(args) }
    focus: true
    Keys.onPressed: event => { if (event.key === Qt.Key_Escape) { controller.close(); event.accepted = true } }
    Column { anchors.fill: parent; anchors.margins: 18; spacing: 10
        Text { text: !controller.system.bluetooth.available ? "Bluetooth unavailable" : "Bluetooth"; color: panel.theme.colors.foreground; font { pixelSize: 17; bold: true } }
        Button { visible: controller.system.bluetooth.available; text: controller.system.bluetooth.powered ? "Turn Bluetooth off" : "Turn Bluetooth on"; onClicked: panel.command(["python3", controller.rootDir + "/scripts/system/bluetooth.py", "power", controller.system.bluetooth.powered ? "off" : "on"]) }
        Repeater { model: controller.system.bluetooth.devices
            Rectangle { required property var modelData; width: panel.width - 36; height: 52; radius: 10; color: panel.theme.colors.surfaceVariant
                Text { anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 10 } width: parent.width - action.width - 20; text: modelData.name; color: panel.theme.colors.foreground; elide: Text.ElideRight }
                Button { id: action; anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 5 } text: modelData.connected ? "Disconnect" : "Connect"; onClicked: panel.command(["python3", controller.rootDir + "/scripts/system/bluetooth.py", modelData.connected ? "disconnect" : "connect", modelData.address]) }
            }
        }
        Text { visible: controller.system.bluetooth.available && controller.system.bluetooth.devices.length === 0; text: "No paired devices"; color: panel.theme.colors.mutedForeground }
    }
}
