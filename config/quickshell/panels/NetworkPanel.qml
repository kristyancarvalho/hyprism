import QtQuick
import QtQuick.Controls
import Quickshell.Io
import "../components"

Item {
    id: panel
    required property var controller
    required property var theme
    property var networks: []
    property string selectedSsid: ""
    property string password: ""
    function scan() { scanner.running = true }
    function command(args) { controller.run(args) }
    function connect(ssid) { command(["python3", controller.rootDir + "/scripts/system/network.py", "connect", ssid, password]); controller.showOsd("Wi-Fi", "Conectando a " + ssid); controller.close() }
    focus: true
    Keys.onPressed: event => { if (event.key === Qt.Key_Escape) { controller.close(); event.accepted = true } }
    Column { anchors.fill: parent; anchors.margins: 18; spacing: 10
        Row { width: parent.width
            spacing: 8
            Text { width: parent.width - toggle.width - scan.width - 16; anchors.verticalCenter: parent.verticalCenter; text: "Redes"; color: panel.theme.colors.foreground; font { pixelSize: 18; bold: true } }
            ShellButton { id: toggle; theme: panel.theme; compact: true; text: controller.system.network.kind === "wifi" ? "Desligar" : "Ligar"; iconName: "network-wireless"; onClicked: panel.command(["python3", controller.rootDir + "/scripts/system/network.py", "toggle", controller.system.network.kind === "wifi" ? "off" : "on"]) }
            ShellButton { id: scan; theme: panel.theme; compact: true; text: "Buscar"; iconName: "view-refresh"; onClicked: panel.scan() }
        }
        TextField { id: passwordField; width: parent.width; height: 42; visible: selectedSsid.length > 0; placeholderText: "Senha de " + selectedSsid + " (vazio para rede conhecida ou aberta)"; echoMode: TextInput.Password; onTextChanged: panel.password = text; color: panel.theme.colors.foreground; placeholderTextColor: panel.theme.colors.mutedForeground; background: Rectangle { radius: 13; color: panel.theme.colors.surfaceVariant; border.width: 1; border.color: panel.theme.colors.outline } }
        ListView { width: parent.width; height: Math.max(120, parent.height - 62 - (passwordField.visible ? passwordField.height + 10 : 0)); clip: true; model: panel.networks; spacing: 6
            delegate: Rectangle { required property var modelData; width: ListView.view.width; height: 54; radius: 14; color: panel.theme.colors.surfaceVariant; border.width: 1; border.color: panel.theme.colors.outline
                ShellIcon { anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter } name: "network-wireless"; iconSize: 22 }
                Text { anchors { left: parent.left; leftMargin: 46; verticalCenter: parent.verticalCenter } text: modelData.ssid; color: panel.theme.colors.foreground; width: parent.width - 190; elide: Text.ElideRight; font { pixelSize: 12; weight: Font.Medium } }
                Text { anchors { right: connectButton.left; rightMargin: 8; verticalCenter: parent.verticalCenter } text: modelData.signal + "%" + (modelData.secure ? "  ▣" : ""); color: panel.theme.colors.mutedForeground; font.pixelSize: 10 }
                ShellButton { id: connectButton; anchors { right: parent.right; rightMargin: 7; verticalCenter: parent.verticalCenter } theme: panel.theme; compact: true; text: selectedSsid === modelData.ssid ? "Conectar" : "Selecionar"; onClicked: { if (panel.selectedSsid === modelData.ssid) panel.connect(modelData.ssid); else panel.selectedSsid = modelData.ssid } }
            }
            Text { anchors.centerIn: parent; visible: parent.count === 0; text: "Nenhuma rede Wi-Fi disponível"; color: panel.theme.colors.mutedForeground }
        }
    }
    Process { id: scanner; command: ["python3", panel.controller.rootDir + "/scripts/system/network.py", "list"]; stdout: SplitParser { splitMarker: "\n"; onRead: data => { try { panel.networks = JSON.parse(data) } catch (error) {} } } }
    Component.onCompleted: scan()
}
