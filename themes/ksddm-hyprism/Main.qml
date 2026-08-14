import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.VirtualKeyboard
import SddmComponents

FocusScope {
    id: root
    width: parent ? parent.width : 1920
    height: parent ? parent.height : 1080
    focus: true
    property bool loginVisible: false
    property bool keyboardVisible: false
    property bool powerVisible: false
    property bool authenticating: false
    property string feedback: ""
    property int userIndex: userModel && userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int sessionIndex: sessionModel && sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
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

    function revealLogin() {
        if (loginVisible) return
        loginVisible = true
        powerVisible = false
        feedback = ""
        focusPassword.restart()
    }

    function hideLogin() {
        if (authenticating) return
        keyboardVisible = false
        powerVisible = false
        password.text = ""
        feedback = ""
        Qt.inputMethod.hide()
        loginVisible = false
        forceActiveFocus()
    }

    function toggleKeyboard() {
        if (!loginVisible || authenticating) return
        keyboardVisible = !keyboardVisible
        password.forceActiveFocus()
        if (keyboardVisible) Qt.inputMethod.show()
        else Qt.inputMethod.hide()
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
        password.forceActiveFocus()
    }

    function login() {
        if (authenticating || !username) return
        authenticating = true
        keyboardVisible = false
        powerVisible = false
        feedback = "Entrando..."
        Qt.inputMethod.hide()
        sddm.login(username, password.text, sessionIndex)
    }

    Keys.priority: Keys.BeforeItem
    Keys.onPressed: event => {
        if (!loginVisible) {
            if (event.key !== Qt.Key_Shift && event.key !== Qt.Key_Control && event.key !== Qt.Key_Alt && event.key !== Qt.Key_Meta) {
                revealLogin()
                event.accepted = true
            }
            return
        }
        if (event.key === Qt.Key_Escape) {
            if (powerVisible) powerVisible = false
            else hideLogin()
            event.accepted = true
        }
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
            color: wallpaper.status === Image.Ready ? "#000000" : root.backgroundColor
            opacity: wallpaper.status === Image.Ready ? .22 : 1
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: !root.loginVisible
        onClicked: root.revealLogin()
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.max(72, parent.height * .1)
        text: "Aperte qualquer tecla"
        color: root.foregroundColor
        opacity: root.loginVisible ? 0 : .9
        visible: opacity > 0
        font.family: "Google Sans Flex"
        font.pixelSize: 16
        font.weight: Font.Medium

        Behavior on opacity { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
    }

    ShaderEffectSource {
        id: loginBackdrop
        width: loginCard.width
        height: loginCard.height
        sourceItem: wallpaper
        sourceRect: Qt.rect(loginCard.x, loginCard.y, loginCard.width, loginCard.height)
        live: true
        recursive: true
        hideSource: false
        visible: false
    }

    Rectangle {
        id: loginCard
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.keyboardVisible ? Math.max(24, (root.height - virtualKeyboard.height - height) / 2) : (root.height - height) / 2
        width: Math.min(360, parent.width - 40)
        height: 326
        radius: 14
        color: "transparent"
        clip: true
        opacity: root.loginVisible ? 1 : 0
        visible: opacity > 0
        enabled: root.loginVisible
        scale: root.loginVisible ? 1 : .97

        MultiEffect {
            anchors.fill: parent
            source: loginBackdrop
            blurEnabled: true
            blur: .55
            blurMax: 24
            autoPaddingEnabled: false
        }

        Rectangle {
            anchors.fill: parent
            color: root.surfaceColor
            opacity: .76
            border.width: 1
            border.color: Qt.rgba(root.foregroundColor.r, root.foregroundColor.g, root.foregroundColor.b, .1)
            radius: parent.radius
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 12

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 72
                Layout.preferredHeight: 72
                radius: 12
                color: Qt.rgba(root.foregroundColor.r, root.foregroundColor.g, root.foregroundColor.b, .09)
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
                    text: root.realName.length ? root.realName.charAt(0).toUpperCase() : "U"
                    color: root.accentColor
                    font.family: "Google Sans Flex"
                    font.pixelSize: 27
                    font.weight: Font.DemiBold
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Controls.Button {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    visible: root.userCount > 1
                    enabled: !root.authenticating
                    text: "‹"
                    font.family: "Google Sans Flex"
                    font.pixelSize: 20
                    activeFocusOnTab: true
                    onClicked: root.cycleUser(-1)
                    background: Rectangle { radius: 8; color: parent.hovered || parent.activeFocus ? root.surfaceHoverColor : "transparent" }
                    contentItem: Text { text: parent.text; color: root.foregroundColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.realName
                    color: root.foregroundColor
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    font.family: "Google Sans Flex"
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                }

                Controls.Button {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    visible: root.userCount > 1
                    enabled: !root.authenticating
                    text: "›"
                    font.family: "Google Sans Flex"
                    font.pixelSize: 20
                    activeFocusOnTab: true
                    onClicked: root.cycleUser(1)
                    background: Rectangle { radius: 8; color: parent.hovered || parent.activeFocus ? root.surfaceHoverColor : "transparent" }
                    contentItem: Text { text: parent.text; color: root.foregroundColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
                }
            }

            Controls.TextField {
                id: password
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                enabled: !root.authenticating
                placeholderText: "Senha"
                echoMode: TextInput.Password
                passwordCharacter: "●"
                color: root.foregroundColor
                placeholderTextColor: root.mutedColor
                selectionColor: root.accentColor
                selectedTextColor: root.accentForegroundColor
                font.family: "Google Sans Flex"
                font.pixelSize: 14
                leftPadding: 14
                rightPadding: 14
                activeFocusOnTab: true
                KeyNavigation.tab: loginButton
                Keys.onReturnPressed: event => {
                    root.login()
                    event.accepted = true
                }
                background: Rectangle {
                    radius: 9
                    color: Qt.rgba(root.surfaceHoverColor.r, root.surfaceHoverColor.g, root.surfaceHoverColor.b, .82)
                    border.width: password.activeFocus ? 2 : 1
                    border.color: password.activeFocus ? root.accentColor : Qt.rgba(root.foregroundColor.r, root.foregroundColor.g, root.foregroundColor.b, .08)
                }
            }

            Controls.Button {
                id: loginButton
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                enabled: !root.authenticating && root.username.length > 0
                text: root.authenticating ? "Entrando..." : "Entrar"
                font.family: "Google Sans Flex"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                activeFocusOnTab: true
                KeyNavigation.tab: keyboardButton
                onClicked: root.login()
                background: Rectangle {
                    radius: 9
                    color: parent.enabled ? root.accentColor : root.surfaceHoverColor
                    opacity: parent.enabled ? parent.hovered || parent.activeFocus ? 1 : .86 : .5
                    border.width: parent.activeFocus ? 2 : 0
                    border.color: root.foregroundColor
                }
                contentItem: Text { text: parent.text; color: root.accentForegroundColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
            }

            Text {
                Layout.fillWidth: true
                Layout.preferredHeight: 16
                text: root.feedback
                color: root.feedback === "Falha ao entrar" ? root.errorColor : root.mutedColor
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.family: "Google Sans Flex"
                font.pixelSize: 11
            }
        }

        Behavior on opacity { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }

    Row {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 24
        spacing: 4
        opacity: root.loginVisible ? 1 : 0
        visible: opacity > 0 && root.sessionCount > 0

        Controls.Button {
            width: 32
            height: 32
            visible: root.sessionCount > 1
            enabled: !root.authenticating
            text: "‹"
            font.family: "Google Sans Flex"
            font.pixelSize: 19
            activeFocusOnTab: true
            onClicked: root.cycleSession(-1)
            background: Rectangle { radius: 8; color: parent.hovered || parent.activeFocus ? root.surfaceHoverColor : "transparent" }
            contentItem: Text { text: parent.text; color: root.foregroundColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(180, implicitWidth)
            text: root.sessionName
            color: root.mutedColor
            elide: Text.ElideRight
            font.family: "Google Sans Flex"
            font.pixelSize: 12
        }

        Controls.Button {
            width: 32
            height: 32
            visible: root.sessionCount > 1
            enabled: !root.authenticating
            text: "›"
            font.family: "Google Sans Flex"
            font.pixelSize: 19
            activeFocusOnTab: true
            onClicked: root.cycleSession(1)
            background: Rectangle { radius: 8; color: parent.hovered || parent.activeFocus ? root.surfaceHoverColor : "transparent" }
            contentItem: Text { text: parent.text; color: root.foregroundColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
        }

        Behavior on opacity { NumberAnimation { duration: 130 } }
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        spacing: 6
        opacity: root.loginVisible ? 1 : 0
        visible: opacity > 0

        Controls.Button {
            id: keyboardButton
            width: 38
            height: 38
            enabled: !root.authenticating
            text: "󰌌"
            font.family: "Symbols Nerd Font Mono"
            font.pixelSize: 18
            activeFocusOnTab: true
            onClicked: root.toggleKeyboard()
            background: Rectangle {
                radius: 9
                color: parent.hovered || parent.activeFocus || root.keyboardVisible ? root.surfaceHoverColor : Qt.rgba(root.surfaceColor.r, root.surfaceColor.g, root.surfaceColor.b, .7)
                border.width: root.keyboardVisible ? 1 : 0
                border.color: root.accentColor
            }
            contentItem: Text { text: parent.text; color: root.keyboardVisible ? root.accentColor : root.foregroundColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
        }

        Controls.Button {
            id: powerButton
            width: 38
            height: 38
            enabled: !root.authenticating
            text: "󰐥"
            font.family: "Symbols Nerd Font Mono"
            font.pixelSize: 18
            activeFocusOnTab: true
            onClicked: root.powerVisible = !root.powerVisible
            background: Rectangle {
                radius: 9
                color: parent.hovered || parent.activeFocus || root.powerVisible ? root.surfaceHoverColor : Qt.rgba(root.surfaceColor.r, root.surfaceColor.g, root.surfaceColor.b, .7)
                border.width: root.powerVisible ? 1 : 0
                border.color: root.accentColor
            }
            contentItem: Text { text: parent.text; color: root.foregroundColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
        }

        Behavior on opacity { NumberAnimation { duration: 130 } }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 24
        anchors.bottomMargin: 70
        width: 286
        height: 54
        radius: 10
        color: root.surfaceColor
        opacity: root.powerVisible ? .94 : 0
        visible: opacity > 0
        enabled: root.powerVisible
        border.width: 1
        border.color: Qt.rgba(root.foregroundColor.r, root.foregroundColor.g, root.foregroundColor.b, .1)

        RowLayout {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 4

            Controls.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: sddm.canSuspend
                text: "Suspender"
                font.family: "Google Sans Flex"
                font.pixelSize: 11
                activeFocusOnTab: true
                onClicked: sddm.suspend()
                background: Rectangle { radius: 7; color: parent.hovered || parent.activeFocus ? root.surfaceHoverColor : "transparent" }
                contentItem: Text { text: parent.text; color: root.foregroundColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
            }

            Controls.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: sddm.canReboot
                text: "Reiniciar"
                font.family: "Google Sans Flex"
                font.pixelSize: 11
                activeFocusOnTab: true
                onClicked: sddm.reboot()
                background: Rectangle { radius: 7; color: parent.hovered || parent.activeFocus ? root.surfaceHoverColor : "transparent" }
                contentItem: Text { text: parent.text; color: root.foregroundColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
            }

            Controls.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: sddm.canPowerOff
                text: "Desligar"
                font.family: "Google Sans Flex"
                font.pixelSize: 11
                activeFocusOnTab: true
                onClicked: sddm.powerOff()
                background: Rectangle { radius: 7; color: parent.hovered || parent.activeFocus ? root.errorColor : "transparent"; opacity: parent.hovered || parent.activeFocus ? .82 : 1 }
                contentItem: Text { text: parent.text; color: root.foregroundColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
            }
        }

        Behavior on opacity { NumberAnimation { duration: 110 } }
    }

    InputPanel {
        id: virtualKeyboard
        z: 10
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width, 760)
        active: root.keyboardVisible
        visible: root.keyboardVisible
        opacity: visible ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    Timer {
        id: focusPassword
        interval: 0
        onTriggered: if (root.loginVisible) password.forceActiveFocus()
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
            root.loginVisible = true
            focusPassword.restart()
        }
        function onInformationMessage(message) {
            root.feedback = String(message)
        }
    }

    Component.onCompleted: {
        if (root.username) sddm.currentUser = root.username
        root.forceActiveFocus()
    }
}
