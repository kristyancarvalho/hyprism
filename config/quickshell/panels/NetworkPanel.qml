import QtQuick
import QtQuick.Controls
import Quickshell.Io

Item {
    id: panel
    required property var controller
    required property var theme
    property var networks: []
    property string selectedSsid: ""
    property string password: ""
    function scan() { scanner.running = true }
    function command(args) { controller.run(args) }
    function connect(ssid) { command(["python3", controller.rootDir + "/scripts/system/network.py", "connect", ssid, password]); controller.showOsd("Wi-Fi", "Connecting to " + ssid); controller.close() }
    focus: true
    Keys.onPressed: event => { if (event.key === Qt.Key_Escape) { controller.close(); event.accepted = true } }
    Column { anchors.fill: parent; anchors.margins: 18; spacing: 10
        Row { width: parent.width
            Text { width: parent.width - 155; text: "Wi-Fi · " + controller.system.network.name; color: panel.theme.colors.foreground; font { pixelSize: 17; bold: true } }
            Button { text: controller.system.network.kind === "wifi" ? "Turn off" : "Turn on"; onClicked: panel.command(["python3", controller.rootDir + "/scripts/system/network.py", "toggle", controller.system.network.kind === "wifi" ? "off" : "on"]) }
            Button { text: "Scan"; onClicked: panel.scan() }
        }
        TextField { width: parent.width; visible: selectedSsid.length > 0; placeholderText: "Password for " + selectedSsid + " (leave empty for known/open network)"; echoMode: TextInput.Password; onTextChanged: panel.password = text; color: panel.theme.colors.foreground; placeholderTextColor: panel.theme.colors.mutedForeground; background: Rectangle { radius: 10; color: panel.theme.colors.surfaceVariant } }
        ListView { width: parent.width; height: 280; clip: true; model: panel.networks; spacing: 5
            delegate: Rectangle { required property var modelData; width: ListView.view.width; height: 46; radius: 10; color: panel.theme.colors.surfaceVariant
                Text { anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter } text: modelData.ssid; color: panel.theme.colors.foreground; width: parent.width - 110; elide: Text.ElideRight }
                Text { anchors { right: connectButton.left; rightMargin: 8; verticalCenter: parent.verticalCenter } text: modelData.signal + "%" + (modelData.secure ? "  ▣" : ""); color: panel.theme.colors.mutedForeground; font.pixelSize: 10 }
                Button { id: connectButton; anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter } text: selectedSsid === modelData.ssid ? "Connect" : "Select"; onClicked: { if (panel.selectedSsid === modelData.ssid) panel.connect(modelData.ssid); else panel.selectedSsid = modelData.ssid } }
            }
            Text { anchors.centerIn: parent; visible: parent.count === 0; text: "No Wi-Fi networks available"; color: panel.theme.colors.mutedForeground }
        }
    }
    Process { id: scanner; command: ["python3", panel.controller.rootDir + "/scripts/system/network.py", "list"]; stdout: SplitParser { splitMarker: "\n"; onRead: data => { try { panel.networks = JSON.parse(data) } catch (error) {} } } }
    Component.onCompleted: scan()
}
