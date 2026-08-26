import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
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
    property string connectionError: ""
    property bool connecting: false
    property int selectedIndex: -1
    readonly property var selectedNetwork: networks.find(network => Design.safeText(network.ssid, "") === selectedSsid)
    readonly property bool passwordRequired: selectedNetwork ? selectedNetwork.secure && !selectedNetwork.known && !selectedNetwork.connected : false
    readonly property int promptHeight: (passwordField.visible ? passwordField.height + 10 : 0) + (errorLabel.visible ? errorLabel.height + 6 : 0)

    function scan() {
        scanner.running = true
    }

    function command(args) {
        controller.run(args)
    }

    function resultSelectable(index) {
        const entry = networks[index]
        return entry && Design.safeText(entry.ssid, "").length > 0 && entry.disabled !== true
    }

    function connect(network) {
        const ssid = Design.safeText(network ? network.ssid : "", "")
        if (!ssid || connecting || network.connected) return
        selectedSsid = ssid
        connectionError = ""
        const profile = network.known ? Design.safeText(network.profileUuid, "") : ""
        connectProcess.command = ["python3", controller.rootDir + "/scripts/system/network.py", "connect", ssid].concat(profile ? [profile] : [])
        connecting = true
        connectProcess.running = true
    }

    function chooseCurrent() {
        const network = networks[selectedIndex]
        if (!network) return
        const ssid = Design.safeText(network.ssid, "")
        if (network.connected) return
        if (network.known || !network.secure) {
            passwordField.text = ""
            connect(network)
        } else if (selectedSsid === ssid && password.length > 0) {
            connect(network)
        } else {
            passwordField.text = ""
            connectionError = ""
            selectedSsid = ssid
            Qt.callLater(() => passwordField.forceInputFocus(Qt.ShortcutFocusReason))
        }
    }

    function cancelPassword() {
        selectedSsid = ""
        passwordField.text = ""
        connectionError = ""
        focusNetworkList()
    }

    function focusNetworkList() {
        if (!networks.length) return
        networksList.forceActiveFocus(Qt.TabFocusReason)
        networksList.positionViewAtIndex(selectedIndex, ListView.Contain)
    }

    function takeInitialFocus() {
        resetSelection()
        forceActiveFocus(Qt.ShortcutFocusReason)
    }

    function resetSelection() {
        selectedIndex = navigation.reset(networks.length, resultSelectable)
        networksList.positionViewAtBeginning()
        Qt.callLater(() => {
            if (selectedIndex >= 0) networksList.positionViewAtIndex(selectedIndex, ListView.Beginning)
        })
    }

    function initialFocusReady() {
        return activeFocus || passwordField.inputActiveFocus || networksList.activeFocus
    }

    focus: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            if (passwordRequired || connectionError.length > 0) cancelPassword()
            else controller.close()
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            navigation.useKeyboard()
            selectedIndex = navigation.move(selectedIndex, -1, networks.length, resultSelectable)
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            navigation.useKeyboard()
            selectedIndex = navigation.move(selectedIndex, 1, networks.length, resultSelectable)
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            chooseCurrent()
            event.accepted = true
        }
    }

    Navigation { id: navigation }

    onNetworksChanged: {
        controller.networkResultCount = networks.length
        resetSelection()
    }
    onPromptHeightChanged: controller.networkPromptHeight = promptHeight

    Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 10

        RowLayout {
            width: parent.width
            spacing: Design.spacingSm

            Column {
                Layout.fillWidth: true

                Text {
                    text: controller.system.network.virtualized && !controller.system.network.wifiAvailable ? I18n.tr("network.title") : I18n.tr("network.networks")
                    color: panel.theme.colors.foreground
                    font.family: Design.fontFamily
                    font.pixelSize: Design.fontSizeLg
                    font.weight: Design.fontWeightSemibold
                }

                Text {
                    visible: controller.system.network.virtualized && controller.system.network.kind === "ethernet"
                    text: I18n.tr("network.virtualAdapter")
                    color: panel.theme.colors.mutedForeground
                    font.family: Design.fontFamily
                    font.pixelSize: Design.fontSizeXs
                }
            }

            ShellButton {
                id: toggle
                Layout.preferredWidth: implicitWidth
                visible: controller.system.network.wifiAvailable
                theme: panel.theme
                compact: true
                text: controller.system.network.wifiEnabled ? I18n.tr("common.turnOff") : I18n.tr("common.turnOn")
                iconName: controller.system.network.wifiEnabled ? controller.networkIconName() : "wifiDisconnected"
                active: controller.system.network.wifiEnabled
                pending: controller.pendingWifi
                onClicked: controller.toggleWifi()
            }

            ShellButton {
                id: scanButton
                Layout.preferredWidth: implicitWidth
                visible: controller.system.network.wifiAvailable
                theme: panel.theme
                compact: true
                text: I18n.tr("common.search")
                iconName: "refresh"
                onClicked: panel.scan()
            }
        }

        SearchField {
            id: passwordField
            width: parent.width
            height: 42
            visible: panel.passwordRequired
            theme: panel.theme
            placeholderText: I18n.tr("network.password", { ssid: selectedSsid })
            iconName: "lock"
            clearButtonEnabled: true
            echoMode: TextInput.Password
            onTextChanged: panel.password = text
            onClearRequested: text = ""
            onKeyPressed: event => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (panel.password.length > 0) panel.connect(panel.selectedNetwork)
                    event.accepted = true
                } else if (event.key === Qt.Key_Down) {
                    panel.focusNetworkList()
                    event.accepted = true
                } else if (event.key === Qt.Key_Escape) {
                    panel.cancelPassword()
                    event.accepted = true
                }
            }
        }

        Text {
            id: errorLabel
            width: parent.width
            height: visible ? implicitHeight : 0
            visible: panel.connectionError.length > 0
            text: panel.connectionError
            color: panel.theme.colors.error
            font.family: Design.fontFamily
            font.pixelSize: Design.fontSizeXs
            elide: Text.ElideRight
        }

        ListView {
            id: networksList
            width: parent.width
            height: Math.max(120, parent.height - 62 - panel.promptHeight)
            clip: true
            model: panel.networks
            currentIndex: panel.selectedIndex
            activeFocusOnTab: true
            spacing: 6
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

            SelectionHighlight {
                parent: networksList.contentItem
                theme: panel.theme
                target: networksList.currentItem
                active: navigation.keyboardNavigation && panel.networks.length > 0
            }

            delegate: Item {
                id: networkDelegate
                required property var modelData
                required property int index
                width: ListView.view.width
                height: 56
                z: 2

                DelegateSurface {
                    host: networksList.contentItem
                    target: networkDelegate
                    theme: panel.theme
                    hovered: pointer.containsMouse && !navigation.keyboardNavigation
                }

                StatusIcon {
                    anchors {
                        left: parent.left
                        leftMargin: 13
                        verticalCenter: parent.verticalCenter
                    }
                    name: controller.wifiIconForSignal(modelData.signal)
                    iconSize: Design.iconMd
                    color: panel.theme.colors.accent
                }

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 47
                        verticalCenter: parent.verticalCenter
                    }
                    text: Design.safeText(modelData.ssid, I18n.tr("network.unnamed"))
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
                        visible: modelData.known
                        name: "check"
                        iconSize: Design.iconXs
                        color: panel.theme.colors.mutedForeground

                        HoverHandler { id: savedHover }
                        ToolTip.visible: savedHover.hovered
                        ToolTip.text: I18n.tr("network.saved")
                        ToolTip.delay: 450
                    }
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
                    text: modelData.connected ? I18n.tr("network.connected") : modelData.known || !modelData.secure || selectedSsid === Design.safeText(modelData.ssid, "") ? I18n.tr("common.connect") : I18n.tr("common.select")
                    available: !modelData.connected && !panel.connecting
                    pending: panel.connecting && panel.selectedSsid === Design.safeText(modelData.ssid, "")
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
                    onEntered: {
                        navigation.usePointer()
                        panel.selectedIndex = index
                    }
                    onClicked: {
                        panel.selectedIndex = index
                        panel.chooseCurrent()
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: parent.count === 0
                text: controller.system.network.virtualized && controller.system.network.kind === "ethernet" ? I18n.tr("network.virtualInfo") : controller.system.network.wifiAvailable ? I18n.tr("network.empty") : I18n.tr("network.unavailable")
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
                } catch (error) {
                    panel.networks = []
                }
            }
        }
    }

    Process {
        id: connectProcess
        stdinEnabled: true
        onStarted: {
            write(panel.passwordRequired ? panel.password + "\n" : "\n")
            panel.password = ""
            passwordField.text = ""
        }
        onExited: (exitCode, exitStatus) => {
            panel.connecting = false
            if (exitCode === 0) {
                panel.controller.showOsd("Wi-Fi", I18n.tr("network.connecting", { ssid: panel.selectedSsid }))
                panel.controller.close()
            } else {
                panel.connectionError = I18n.tr("network.connectionFailed", { ssid: panel.selectedSsid })
                if (panel.passwordRequired) Qt.callLater(() => passwordField.forceInputFocus(Qt.ShortcutFocusReason))
            }
        }
    }

    Component.onCompleted: {
        controller.networkResultCount = networks.length
        controller.networkPromptHeight = promptHeight
        if (controller.system.network.wifiAvailable) scan()
        takeInitialFocus()
    }
    Component.onDestruction: controller.networkPromptHeight = 0
}
