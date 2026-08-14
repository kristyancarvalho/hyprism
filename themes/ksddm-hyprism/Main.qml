import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import SddmComponents

Item {
    id: root
    width: parent ? parent.width : 1920
    height: parent ? parent.height : 1080
    property int userIndex: userModel && userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int sessionIndex: sessionModel && sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property bool authenticating: false
    property string feedback: ""
    readonly property int userCount: userModel ? userModel.rowCount() : 0
    readonly property int sessionCount: sessionModel ? sessionModel.rowCount() : 0
    readonly property string username: userValue(257, "")
    readonly property string realName: userValue(258, username || "Usuário")
    readonly property string userIcon: userValue(260, "")
    readonly property string sessionName: sessionValue(260, "Sessão")
    readonly property color backgroundColor: config.stringValue("background-color") || "#091015"
    readonly property color surfaceColor: config.stringValue("surface-color") || "#131b21"
    readonly property color surfaceHoverColor: config.stringValue("surface-hover-color") || "#202b33"
    readonly property color foregroundColor: config.stringValue("foreground-color") || "#e0e8ee"
    readonly property color mutedColor: config.stringValue("muted-color") || "#9aa8b2"
    readonly property color accentColor: config.stringValue("accent-color") || "#82b1d3"
    readonly property color accentForegroundColor: config.stringValue("accent-foreground-color") || "#091015"
    readonly property color errorColor: config.stringValue("error-color") || "#e4777f"
    readonly property string backgroundSource: config.stringValue("background") || "file:///var/lib/hyprism/sddm/current-wallpaper.jpg"

    function userValue(role, fallback) {
        if (!userModel || userCount <= 0 || userIndex < 0 || userIndex >= userCount) return fallback
        const value = userModel.data(userModel.index(userIndex, 0), role)
        return value === undefined || value === null || String(value).length === 0 ? fallback : String(value)
    }

    function sessionValue(role, fallback) {
        if (!sessionModel || sessionCount <= 0 || sessionIndex < 0 || sessionIndex >= sessionCount) return fallback
        const value = sessionModel.data(sessionModel.index(sessionIndex, 0), role)
        return value === undefined || value === null || String(value).length === 0 ? fallback : String(value)
    }

    function cycleUser(step) {
        if (userCount <= 1 || authenticating) return
        userIndex = (userIndex + step + userCount) % userCount
        sddm.currentUser = username
        password.text = ""
        feedback = ""
        password.forceActiveFocus()
    }

    function cycleSession(step) {
        if (sessionCount <= 1 || authenticating) return
        sessionIndex = (sessionIndex + step + sessionCount) % sessionCount
    }

    function login() {
        if (authenticating || !username) return
        authenticating = true
        feedback = "Entrando..."
        sddm.login(username, password.text, sessionIndex)
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        source: root.backgroundSource
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        cache: false

        Rectangle {
            anchors.fill: parent
            color: root.backgroundColor
            opacity: wallpaper.status === Image.Ready ? .38 : 1
        }
    }

    Column {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Math.max(42, parent.height * .075)
        spacing: 1

        Text {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.foregroundColor
            font.family: "Google Sans Flex"
            font.pixelSize: 42
            font.weight: Font.DemiBold
            text: Qt.formatTime(new Date(), "HH:mm")
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.mutedColor
            font.family: "Google Sans Flex"
            font.pixelSize: 14
            text: Qt.locale("pt_BR").toString(new Date(), "dddd, dd 'de' MMMM")
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: clock.text = Qt.formatTime(new Date(), "HH:mm")
    }

    Rectangle {
        id: loginCard
        anchors.centerIn: parent
        width: Math.min(420, parent.width - 40)
        height: 430
        radius: 14
        color: root.surfaceColor
        opacity: .94
        border.width: 1
        border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, .22)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 28
            spacing: 14

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 86
                Layout.preferredHeight: 86
                radius: 12
                color: root.surfaceHoverColor
                clip: true

                Image {
                    id: avatarImage
                    anchors.fill: parent
                    anchors.margins: 3
                    source: root.userIcon
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: avatarImage.status !== Image.Ready
                    color: root.accentColor
                    font.family: "Google Sans Flex"
                    font.pixelSize: 30
                    font.weight: Font.DemiBold
                    text: root.realName.length ? root.realName.charAt(0).toUpperCase() : "U"
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Controls.Button {
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 38
                    text: "‹"
                    enabled: root.userCount > 1 && !root.authenticating
                    font.family: "Google Sans Flex"
                    font.pixelSize: 22
                    onClicked: root.cycleUser(-1)
                    background: Rectangle {
                        radius: 9
                        color: parent.hovered ? root.surfaceHoverColor : "transparent"
                    }
                    contentItem: Text {
                        text: parent.text
                        color: parent.enabled ? root.foregroundColor : root.mutedColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font: parent.font
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: root.realName
                        color: root.foregroundColor
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        font.family: "Google Sans Flex"
                        font.pixelSize: 17
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.username
                        color: root.mutedColor
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        font.family: "Google Sans Flex"
                        font.pixelSize: 12
                    }
                }

                Controls.Button {
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 38
                    text: "›"
                    enabled: root.userCount > 1 && !root.authenticating
                    font.family: "Google Sans Flex"
                    font.pixelSize: 22
                    onClicked: root.cycleUser(1)
                    background: Rectangle {
                        radius: 9
                        color: parent.hovered ? root.surfaceHoverColor : "transparent"
                    }
                    contentItem: Text {
                        text: parent.text
                        color: parent.enabled ? root.foregroundColor : root.mutedColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font: parent.font
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                radius: 9
                color: password.activeFocus ? root.surfaceHoverColor : Qt.rgba(root.surfaceHoverColor.r, root.surfaceHoverColor.g, root.surfaceHoverColor.b, .7)
                border.width: password.activeFocus ? 2 : 0
                border.color: root.accentColor

                TextInput {
                    id: password
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    color: root.foregroundColor
                    selectionColor: root.accentColor
                    selectedTextColor: root.accentForegroundColor
                    echoMode: TextInput.Password
                    passwordCharacter: "●"
                    font.family: "Google Sans Flex"
                    font.pixelSize: 14
                    verticalAlignment: TextInput.AlignVCenter
                    enabled: !root.authenticating
                    KeyNavigation.tab: loginButton
                    Keys.onReturnPressed: root.login()
                }

                Text {
                    anchors.fill: password
                    visible: password.text.length === 0 && !password.activeFocus
                    text: "Senha"
                    color: root.mutedColor
                    font.family: "Google Sans Flex"
                    font.pixelSize: 14
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Controls.Button {
                id: loginButton
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                text: root.authenticating ? "Entrando..." : "Entrar"
                enabled: !root.authenticating && root.username.length > 0
                font.family: "Google Sans Flex"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                KeyNavigation.tab: previousSession
                onClicked: root.login()
                background: Rectangle {
                    radius: 9
                    color: parent.enabled ? parent.hovered || parent.activeFocus ? root.accentColor : root.accentColor : root.surfaceHoverColor
                    opacity: parent.enabled ? parent.hovered || parent.activeFocus ? 1 : .88 : .5
                    border.width: parent.activeFocus ? 2 : 0
                    border.color: root.foregroundColor
                }
                contentItem: Text {
                    text: parent.text
                    color: root.accentForegroundColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font: parent.font
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Controls.Button {
                    id: previousSession
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 34
                    text: "‹"
                    enabled: root.sessionCount > 1 && !root.authenticating
                    font.family: "Google Sans Flex"
                    font.pixelSize: 20
                    onClicked: root.cycleSession(-1)
                    background: Rectangle { radius: 8; color: parent.hovered || parent.activeFocus ? root.surfaceHoverColor : "transparent" }
                    contentItem: Text { text: parent.text; color: root.foregroundColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.sessionName
                    color: root.mutedColor
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    font.family: "Google Sans Flex"
                    font.pixelSize: 12
                }

                Controls.Button {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 34
                    text: "›"
                    enabled: root.sessionCount > 1 && !root.authenticating
                    font.family: "Google Sans Flex"
                    font.pixelSize: 20
                    onClicked: root.cycleSession(1)
                    background: Rectangle { radius: 8; color: parent.hovered || parent.activeFocus ? root.surfaceHoverColor : "transparent" }
                    contentItem: Text { text: parent.text; color: root.foregroundColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.preferredHeight: 18
                text: root.feedback
                color: root.feedback === "Falha ao entrar" ? root.errorColor : root.mutedColor
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.family: "Google Sans Flex"
                font.pixelSize: 12
            }
        }
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 28
        spacing: 8

        Controls.Button {
            visible: sddm.canSuspend
            text: "Suspender"
            font.family: "Google Sans Flex"
            onClicked: sddm.suspend()
            background: Rectangle { radius: 9; color: parent.hovered || parent.activeFocus ? root.surfaceHoverColor : root.surfaceColor; opacity: .94 }
            contentItem: Text { text: parent.text; color: root.foregroundColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
        }

        Controls.Button {
            visible: sddm.canReboot
            text: "Reiniciar"
            font.family: "Google Sans Flex"
            onClicked: sddm.reboot()
            background: Rectangle { radius: 9; color: parent.hovered || parent.activeFocus ? root.surfaceHoverColor : root.surfaceColor; opacity: .94 }
            contentItem: Text { text: parent.text; color: root.foregroundColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
        }

        Controls.Button {
            visible: sddm.canPowerOff
            text: "Desligar"
            font.family: "Google Sans Flex"
            onClicked: sddm.powerOff()
            background: Rectangle { radius: 9; color: parent.hovered || parent.activeFocus ? root.errorColor : root.surfaceColor; opacity: .94 }
            contentItem: Text { text: parent.text; color: root.foregroundColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
        }
    }

    Connections {
        target: sddm
        function onLoginSucceeded() {
            root.feedback = "Sessão iniciada"
        }
        function onLoginFailed() {
            root.authenticating = false
            root.feedback = "Falha ao entrar"
            password.text = ""
            password.forceActiveFocus()
        }
        function onInformationMessage(message) {
            root.feedback = String(message)
        }
    }

    Component.onCompleted: {
        if (root.username) sddm.currentUser = root.username
        password.forceActiveFocus()
    }
}
