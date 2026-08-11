import QtQuick
import QtQuick.Controls
import Quickshell.Io
import "../components"
import ".."

Item {
    id: panel
    required property var controller
    required property var theme
    property var networks: []
    property string selectedSsid: ""
    property string password: ""
    property int selectedIndex: 0

    function scan() {
        scanner.running = true
    }

    function command(args) {
        controller.run(args)
    }

    function connect(ssid) {
        if (!Design.safeText(ssid, "")) return
        command(["python3", controller.rootDir + "/scripts/system/network.py", "connect", ssid, password])
        controller.showOsd("Wi-Fi", "Conectando a " + ssid)
        controller.close()
    }

    function chooseCurrent() {
        const network = networks[selectedIndex]
        if (!network) return
        const ssid = Design.safeText(network.ssid, "")
        if (selectedSsid === ssid) connect(ssid)
        else {
            selectedSsid = ssid
            passwordField.forceActiveFocus()
        }
    }

    focus: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            controller.close()
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            selectedIndex = navigation.wrap(selectedIndex, -1, networks.length)
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            selectedIndex = navigation.wrap(selectedIndex, 1, networks.length)
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            chooseCurrent()
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
            spacing: 8

            Text {
                width: parent.width - toggle.width - scanButton.width - 16
                anchors.verticalCenter: parent.verticalCenter
                text: "Redes"
                color: panel.theme.colors.foreground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeLg
                font.weight: Design.fontWeightSemibold
            }

            ShellButton {
                id: toggle
                theme: panel.theme
                compact: true
                text: controller.system.network.kind === "wifi" ? "Desligar" : "Ligar"
                iconName: "wifi"
                onClicked: panel.command(["python3", controller.rootDir + "/scripts/system/network.py", "toggle", controller.system.network.kind === "wifi" ? "off" : "on"])
            }

            ShellButton {
                id: scanButton
                theme: panel.theme
                compact: true
                text: "Buscar"
                iconName: "refresh"
                onClicked: panel.scan()
            }
        }

        TextField {
            id: passwordField
            width: parent.width
            height: 42
            visible: selectedSsid.length > 0
            placeholderText: "Senha de " + selectedSsid + " (vazio para rede conhecida ou aberta)"
            echoMode: TextInput.Password
            onTextChanged: panel.password = text
            color: panel.theme.colors.foreground
            placeholderTextColor: panel.theme.colors.mutedForeground
            font.family: Design.fontFamily
            font.pixelSize: Design.fontSizeSm
            background: Rectangle {
                radius: Design.radiusSm
                color: panel.theme.colors.surfaceVariant
                border.width: passwordField.activeFocus ? 2 : 1
                border.color: passwordField.activeFocus ? panel.theme.colors.accent : panel.theme.colors.outline
            }
        }

        ListView {
            width: parent.width
            height: Math.max(120, parent.height - 62 - (passwordField.visible ? passwordField.height + 10 : 0))
            clip: true
            model: panel.networks
            currentIndex: panel.selectedIndex
            spacing: 6
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

            delegate: Rectangle {
                required property var modelData
                required property int index
                width: ListView.view.width
                height: 56
                radius: Design.radiusSm
                color: panel.selectedIndex === index ? panel.theme.colors.surfaceActive : pointer.containsMouse ? panel.theme.colors.surfaceHover : panel.theme.colors.surfaceVariant
                border.width: panel.selectedIndex === index ? 2 : 1
                border.color: panel.selectedIndex === index ? panel.theme.colors.accent : panel.theme.colors.outline

                StatusIcon {
                    anchors {
                        left: parent.left
                        leftMargin: 13
                        verticalCenter: parent.verticalCenter
                    }
                    name: "wifi"
                    iconSize: Design.iconMd
                    color: panel.theme.colors.accent
                }

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 47
                        verticalCenter: parent.verticalCenter
                    }
                    text: Design.safeText(modelData.ssid, "Rede sem nome")
                    color: panel.theme.colors.foreground
                    width: parent.width - 200
                    elide: Text.ElideRight
                    font.family: Design.fontFamily
                    font.pixelSize: Design.fontSizeSm
                    font.weight: Design.fontWeightMedium
                }

                Row {
                    anchors {
                        right: connectButton.left
                        rightMargin: 8
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 4

                    StatusIcon {
                        visible: modelData.secure
                        name: "secure"
                        iconSize: Design.iconXs
                        color: panel.theme.colors.mutedForeground
                    }
                    Text {
                        text: Math.round(Design.clamp(modelData.signal, 0, 100)) + "%"
                        color: panel.theme.colors.mutedForeground
                        font.family: Design.fontFamily
                        font.pixelSize: Design.fontSizeXs
                    }
                }

                ShellButton {
                    id: connectButton
                    anchors {
                        right: parent.right
                        rightMargin: 7
                        verticalCenter: parent.verticalCenter
                    }
                    theme: panel.theme
                    compact: true
                    text: selectedSsid === Design.safeText(modelData.ssid, "") ? "Conectar" : "Selecionar"
                    onClicked: {
                        panel.selectedIndex = index
                        panel.chooseCurrent()
                    }
                }

                MouseArea {
                    id: pointer
                    anchors {
                        left: parent.left
                        right: connectButton.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    hoverEnabled: true
                    onEntered: panel.selectedIndex = index
                    onClicked: panel.chooseCurrent()
                }
            }

            Text {
                anchors.centerIn: parent
                visible: parent.count === 0
                text: "Nenhuma rede Wi-Fi disponível"
                color: panel.theme.colors.mutedForeground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeSm
            }
        }
    }

    Process {
        id: scanner
        command: ["python3", panel.controller.rootDir + "/scripts/system/network.py", "list"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                try {
                    panel.networks = JSON.parse(data)
                    panel.selectedIndex = navigation.clamp(panel.selectedIndex, panel.networks.length)
                } catch (error) {
                    panel.networks = []
                }
            }
        }
    }

    Component.onCompleted: {
        scan()
        forceActiveFocus()
    }
}
