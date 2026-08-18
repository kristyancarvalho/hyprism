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
    opacity: loaded ? 1 : 0
    property bool revealed: false
    property bool keyboardVisible: false
    property bool powerVisible: false
    property bool sessionsVisible: false
    property bool authenticating: false
    property bool passwordVisible: false
    property bool loaded: false
    property string feedback: ""
    property real errorOffset: 0
    property int userIndex: userModel && userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int sessionIndex: sessionModel && sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    readonly property int userCount: userModel ? userModel.rowCount() : 0
    readonly property int sessionCount: sessionModel ? sessionModel.rowCount() : 0
    readonly property string username: userValue(257, "")
    readonly property string realName: userValue(258, username || "Usuário")
    readonly property string userIcon: userValue(260, "")
    readonly property string sessionName: sessionValue(sessionIndex, 260, "Sessão")
    readonly property color backgroundColor: config.stringValue("background-color") || "#091015"
    readonly property color surfaceColor: config.stringValue("surface-color") || "#131b21"
    readonly property color surfaceContainerColor: config.stringValue("surface-container-color") || "#202b33"
    readonly property color surfaceContainerHighColor: config.stringValue("surface-container-high-color") || "#26333c"
    readonly property color surfaceHoverColor: config.stringValue("surface-hover-color") || "#2e3d47"
    readonly property color foregroundColor: config.stringValue("foreground-color") || "#e0e8ee"
    readonly property color mutedColor: config.stringValue("muted-color") || "#9aa8b2"
    readonly property color primaryColor: config.stringValue("primary-color") || config.stringValue("accent-color") || "#82b1d3"
    readonly property color onPrimaryColor: config.stringValue("on-primary-color") || config.stringValue("accent-foreground-color") || "#091015"
    readonly property color secondaryColor: config.stringValue("secondary-color") || "#a7c5dc"
    readonly property color tertiaryColor: config.stringValue("tertiary-color") || "#82b1d3"
    readonly property color errorColor: config.stringValue("error-color") || "#e4777f"
    readonly property string backgroundSource: config.stringValue("background") || "file:///var/lib/hyprism/sddm/current-wallpaper.jpg"

    SessionIdentity { id: sessionIdentity }

    function userValue(role, fallback) {
        if (!userModel || userCount <= 0 || userIndex < 0 || userIndex >= userCount) return fallback
        const value = userModel.data(userModel.index(userIndex, 0), role)
        return value === undefined || value === null || String(value).length === 0 ? fallback : String(value)
    }

    function sessionValue(index, role, fallback) {
        if (!sessionModel || sessionCount <= 0 || index < 0 || index >= sessionCount) return fallback
        const value = sessionModel.data(sessionModel.index(index, 0), role)
        return value === undefined || value === null || String(value).length === 0 ? fallback : String(value)
    }

    function sessionProfile(index) {
        return sessionIdentity.profile(sessionValue(index, 260, ""))
    }

    function revealLogin() {
        if (revealed) return
        revealed = true
        powerVisible = false
        sessionsVisible = false
        feedback = ""
        focusPassword.restart()
    }

    function hideLogin() {
        if (authenticating) return
        keyboardVisible = false
        powerVisible = false
        sessionsVisible = false
        password.text = ""
        feedback = ""
        Qt.inputMethod.hide()
        revealed = false
        forceActiveFocus()
    }

    function toggleKeyboard() {
        if (!revealed || authenticating) return
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

    function selectSession(index) {
        if (index < 0 || index >= sessionCount || authenticating) return
        sessionIndex = index
        sessionsVisible = false
        password.forceActiveFocus()
    }

    function login() {
        if (authenticating || !username) return
        authenticating = true
        keyboardVisible = false
        powerVisible = false
        sessionsVisible = false
        feedback = "Entrando"
        Qt.inputMethod.hide()
        sddm.login(username, password.text, sessionIndex)
    }

    Keys.priority: Keys.BeforeItem
    Keys.onPressed: event => {
        if (!revealed) {
            if (event.key !== Qt.Key_Shift && event.key !== Qt.Key_Control && event.key !== Qt.Key_Alt && event.key !== Qt.Key_Meta) {
                revealLogin()
                event.accepted = true
            }
            return
        }
        if (event.key === Qt.Key_Escape) {
            if (powerVisible) powerVisible = false
            else if (sessionsVisible) sessionsVisible = false
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
            opacity: wallpaper.status === Image.Ready ? .2 : 1
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: !root.revealed
        onClicked: root.revealLogin()
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.max(56, parent.height * .08)
        text: "Aperte qualquer tecla"
        color: root.foregroundColor
        opacity: root.revealed ? 0 : .84
        visible: opacity > 0
        font.family: "Google Sans Flex"
        font.pixelSize: 14
        font.weight: Font.Medium

        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    }

    Column {
        id: identity
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.keyboardVisible ? Math.max(28, (root.height - virtualKeyboard.height - height) / 2) : (root.height - height) / 2
        width: Math.min(368, parent.width - 40)
        spacing: 13
        opacity: root.revealed ? 1 : 0
        visible: opacity > 0
        enabled: root.revealed
        scale: root.revealed ? 1 : .98
        transform: Translate { x: root.errorOffset }

        Item {
            width: parent.width
            height: 96

            Controls.Button {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                width: 34
                height: 34
                visible: root.userCount > 1
                enabled: !root.authenticating
                text: "󰅁"
                font.family: "Symbols Nerd Font Mono"
                font.pixelSize: 17
                onClicked: root.cycleUser(-1)
                background: Rectangle { radius: 10; color: parent.hovered || parent.activeFocus ? root.surfaceHoverColor : "transparent" }
                contentItem: Text { text: parent.text; color: root.foregroundColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 88
                height: 88
                radius: 24
                color: Qt.rgba(root.surfaceColor.r, root.surfaceColor.g, root.surfaceColor.b, .72)
                border.width: 1
                border.color: Qt.rgba(root.foregroundColor.r, root.foregroundColor.g, root.foregroundColor.b, .12)
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
                    color: root.primaryColor
                    font.family: "Google Sans Flex"
                    font.pixelSize: 31
                    font.weight: Font.DemiBold
                }
            }

            Controls.Button {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                width: 34
                height: 34
                visible: root.userCount > 1
                enabled: !root.authenticating
                text: "󰅂"
                font.family: "Symbols Nerd Font Mono"
                font.pixelSize: 17
                onClicked: root.cycleUser(1)
                background: Rectangle { radius: 10; color: parent.hovered || parent.activeFocus ? root.surfaceHoverColor : "transparent" }
                contentItem: Text { text: parent.text; color: root.foregroundColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
            }
        }

        Text {
            width: parent.width
            text: root.realName
            color: root.foregroundColor
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font.family: "Google Sans Flex"
            font.pixelSize: 17
            font.weight: Font.DemiBold
        }

        ShaderEffectSource {
            id: passwordBackdrop
            width: passwordSurface.width
            height: passwordSurface.height
            sourceItem: wallpaper
            sourceRect: Qt.rect(passwordSurface.x, passwordSurface.y, passwordSurface.width, passwordSurface.height)
            live: true
            recursive: true
            visible: false
        }

        Rectangle {
            id: passwordSurface
            width: parent.width
            height: 50
            radius: 15
            color: "transparent"
            clip: true

            MultiEffect {
                anchors.fill: parent
                source: passwordBackdrop
                blurEnabled: true
                blur: .42
                blurMax: 18
                autoPaddingEnabled: false
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(root.surfaceColor.r, root.surfaceColor.g, root.surfaceColor.b, .74)
                border.width: password.activeFocus ? 2 : 1
                border.color: password.activeFocus ? root.primaryColor : Qt.rgba(root.foregroundColor.r, root.foregroundColor.g, root.foregroundColor.b, .12)
                radius: parent.radius

                Behavior on border.color { ColorAnimation { duration: 110 } }
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: "󰌾"
                color: password.activeFocus ? root.primaryColor : root.mutedColor
                font.family: "Symbols Nerd Font Mono"
                font.pixelSize: 16
            }

            Controls.TextField {
                id: password
                anchors.left: parent.left
                anchors.leftMargin: 48
                anchors.right: visibilityButton.left
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                enabled: !root.authenticating
                placeholderText: "Senha"
                echoMode: root.passwordVisible ? TextInput.Normal : TextInput.Password
                passwordCharacter: "●"
                color: root.foregroundColor
                placeholderTextColor: root.mutedColor
                selectionColor: root.primaryColor
                selectedTextColor: root.onPrimaryColor
                font.family: "Google Sans Flex"
                font.pixelSize: 14
                background: Item {}
                activeFocusOnTab: true
                Keys.onReturnPressed: event => {
                    root.login()
                    event.accepted = true
                }
            }

            Controls.Button {
                id: visibilityButton
                anchors.right: parent.right
                anchors.rightMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                width: 40
                height: 40
                enabled: !root.authenticating
                text: root.passwordVisible ? "󰈈" : "󰈉"
                font.family: "Symbols Nerd Font Mono"
                font.pixelSize: 16
                onClicked: root.passwordVisible = !root.passwordVisible
                background: Rectangle { radius: 11; color: parent.hovered || parent.activeFocus ? root.surfaceHoverColor : "transparent" }
                contentItem: Text { text: parent.text; color: root.mutedColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: root.passwordVisible ? "Ocultar senha" : "Mostrar senha"
                Controls.ToolTip.delay: 450
            }
        }

        Controls.Button {
            id: loginButton
            anchors.horizontalCenter: parent.horizontalCenter
            width: 48
            height: 48
            enabled: !root.authenticating && root.username.length > 0
            text: root.authenticating ? "󰔟" : "󰜎"
            font.family: "Symbols Nerd Font Mono"
            font.pixelSize: 19
            onClicked: root.login()
            background: Rectangle {
                radius: 14
                color: parent.enabled ? root.primaryColor : root.surfaceContainerColor
                opacity: parent.enabled ? parent.hovered || parent.activeFocus ? 1 : .9 : .58
                border.width: parent.activeFocus ? 2 : 0
                border.color: root.foregroundColor
                Behavior on color { ColorAnimation { duration: 110 } }
            }
            contentItem: Text { text: parent.text; color: root.onPrimaryColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
            Controls.ToolTip.visible: hovered
            Controls.ToolTip.text: root.authenticating ? "Autenticando" : "Entrar"
            Controls.ToolTip.delay: 450
        }

        Text {
            width: parent.width
            height: 15
            text: root.feedback
            color: root.feedback === "Falha ao entrar" ? root.errorColor : root.mutedColor
            horizontalAlignment: Text.AlignHCenter
            opacity: text.length ? 1 : 0
            elide: Text.ElideRight
            font.family: "Google Sans Flex"
            font.pixelSize: 11
            Behavior on opacity { NumberAnimation { duration: 110 } }
        }

        Behavior on opacity { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }

    Controls.Button {
        id: sessionButton
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 24
        anchors.bottomMargin: 24
        width: Math.min(212, contentItem.implicitWidth + 28)
        height: 42
        visible: root.revealed && root.sessionCount > 0
        enabled: !root.authenticating
        text: ""
        onClicked: {
            root.sessionsVisible = !root.sessionsVisible
            root.powerVisible = false
        }
        background: Rectangle {
            radius: 13
            color: parent.hovered || parent.activeFocus || root.sessionsVisible ? root.surfaceContainerHighColor : Qt.rgba(root.surfaceColor.r, root.surfaceColor.g, root.surfaceColor.b, .72)
            border.width: root.sessionsVisible ? 1 : 0
            border.color: root.primaryColor
        }
        contentItem: Row {
            anchors.centerIn: parent
            spacing: 9
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.sessionProfile(root.sessionIndex).glyph
                color: root.primaryColor
                font.family: "Symbols Nerd Font Mono"
                font.pixelSize: 19
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.sessionName
                color: root.foregroundColor
                elide: Text.ElideRight
                font.family: "Google Sans Flex"
                font.pixelSize: 12
                font.weight: Font.Medium
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰅂"
                color: root.mutedColor
                font.family: "Symbols Nerd Font Mono"
                font.pixelSize: 14
            }
        }
        Controls.ToolTip.visible: hovered
        Controls.ToolTip.text: "Selecionar sessão"
        Controls.ToolTip.delay: 450
    }

    Rectangle {
        id: sessionPicker
        anchors.left: parent.left
        anchors.bottom: sessionButton.top
        anchors.leftMargin: 24
        anchors.bottomMargin: 10
        width: Math.min(parent.width - 48, Math.max(184, sessionRow.implicitWidth + 16))
        height: 64
        radius: 16
        color: Qt.rgba(root.surfaceColor.r, root.surfaceColor.g, root.surfaceColor.b, .9)
        opacity: root.sessionsVisible ? 1 : 0
        visible: opacity > 0
        enabled: root.sessionsVisible
        border.width: 1
        border.color: Qt.rgba(root.foregroundColor.r, root.foregroundColor.g, root.foregroundColor.b, .12)
        clip: true

        Flickable {
            anchors.fill: parent
            anchors.margins: 8
            contentWidth: sessionRow.implicitWidth
            contentHeight: height
            interactive: contentWidth > width
            clip: true

            Row {
                id: sessionRow
                height: parent.height
                spacing: 6

                Repeater {
                    model: root.sessionCount

                    delegate: Controls.Button {
                        id: sessionItem
                        readonly property string name: root.sessionValue(index, 260, "Sessão")
                        readonly property var profile: root.sessionProfile(index)
                        readonly property bool selected: root.sessionIndex === index
                        width: selected || hovered || activeFocus ? Math.min(164, label.implicitWidth + 54) : 44
                        height: 48
                        enabled: !root.authenticating
                        text: ""
                        onClicked: root.selectSession(index)
                        background: Rectangle {
                            radius: 12
                            color: sessionItem.selected ? Qt.rgba(root.primaryColor.r, root.primaryColor.g, root.primaryColor.b, .22) : sessionItem.hovered || sessionItem.activeFocus ? root.surfaceHoverColor : "transparent"
                            border.width: sessionItem.selected ? 1 : 0
                            border.color: root.primaryColor
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }
                        contentItem: Row {
                            anchors.centerIn: parent
                            spacing: 7
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: sessionItem.profile.glyph
                                color: sessionItem.selected ? root.primaryColor : root.foregroundColor
                                font.family: "Symbols Nerd Font Mono"
                                font.pixelSize: sessionItem.selected ? 20 : 18
                                Behavior on font.pixelSize { NumberAnimation { duration: 100 } }
                            }
                            Text {
                                id: label
                                anchors.verticalCenter: parent.verticalCenter
                                width: visible ? Math.min(108, implicitWidth) : 0
                                text: sessionItem.name
                                color: sessionItem.selected ? root.foregroundColor : root.mutedColor
                                elide: Text.ElideRight
                                visible: sessionItem.selected || sessionItem.hovered || sessionItem.activeFocus
                                font.family: "Google Sans Flex"
                                font.pixelSize: 11
                                font.weight: sessionItem.selected ? Font.Medium : Font.Normal
                            }
                        }
                        Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        Controls.ToolTip.visible: hovered && !selected
                        Controls.ToolTip.text: name
                        Controls.ToolTip.delay: 450
                    }
                }
            }
        }

        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        spacing: 6
        opacity: root.revealed ? 1 : 0
        visible: opacity > 0

        Controls.Button {
            id: keyboardButton
            width: 42
            height: 42
            enabled: !root.authenticating
            text: "󰌌"
            font.family: "Symbols Nerd Font Mono"
            font.pixelSize: 18
            onClicked: root.toggleKeyboard()
            background: Rectangle {
                radius: 13
                color: parent.hovered || parent.activeFocus || root.keyboardVisible ? root.surfaceContainerHighColor : Qt.rgba(root.surfaceColor.r, root.surfaceColor.g, root.surfaceColor.b, .72)
                border.width: root.keyboardVisible ? 1 : 0
                border.color: root.primaryColor
            }
            contentItem: Text { text: parent.text; color: root.keyboardVisible ? root.primaryColor : root.foregroundColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
            Controls.ToolTip.visible: hovered
            Controls.ToolTip.text: "Teclado virtual"
            Controls.ToolTip.delay: 450
        }

        Controls.Button {
            id: powerButton
            width: 42
            height: 42
            enabled: !root.authenticating
            text: "󰐥"
            font.family: "Symbols Nerd Font Mono"
            font.pixelSize: 18
            onClicked: {
                root.powerVisible = !root.powerVisible
                root.sessionsVisible = false
            }
            background: Rectangle {
                radius: 13
                color: parent.hovered || parent.activeFocus || root.powerVisible ? root.surfaceContainerHighColor : Qt.rgba(root.surfaceColor.r, root.surfaceColor.g, root.surfaceColor.b, .72)
                border.width: root.powerVisible ? 1 : 0
                border.color: root.primaryColor
            }
            contentItem: Text { text: parent.text; color: root.foregroundColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
            Controls.ToolTip.visible: hovered
            Controls.ToolTip.text: "Energia"
            Controls.ToolTip.delay: 450
        }

        Behavior on opacity { NumberAnimation { duration: 130 } }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.bottom: powerButton.top
        anchors.rightMargin: 24
        anchors.bottomMargin: 10
        width: 160
        height: 54
        radius: 16
        color: Qt.rgba(root.surfaceColor.r, root.surfaceColor.g, root.surfaceColor.b, .92)
        opacity: root.powerVisible ? 1 : 0
        visible: opacity > 0
        enabled: root.powerVisible
        border.width: 1
        border.color: Qt.rgba(root.foregroundColor.r, root.foregroundColor.g, root.foregroundColor.b, .12)

        RowLayout {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 4

            Controls.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: sddm.canSuspend
                text: "󰤄"
                font.family: "Symbols Nerd Font Mono"
                font.pixelSize: 17
                onClicked: sddm.suspend()
                background: Rectangle { radius: 11; color: parent.hovered || parent.activeFocus ? root.surfaceHoverColor : "transparent" }
                contentItem: Text { text: parent.text; color: root.foregroundColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: "Suspender"
                Controls.ToolTip.delay: 450
            }

            Controls.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: sddm.canReboot
                text: "󰜉"
                font.family: "Symbols Nerd Font Mono"
                font.pixelSize: 17
                onClicked: sddm.reboot()
                background: Rectangle { radius: 11; color: parent.hovered || parent.activeFocus ? root.surfaceHoverColor : "transparent" }
                contentItem: Text { text: parent.text; color: root.foregroundColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: "Reiniciar"
                Controls.ToolTip.delay: 450
            }

            Controls.Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: sddm.canPowerOff
                text: "󰐥"
                font.family: "Symbols Nerd Font Mono"
                font.pixelSize: 17
                onClicked: sddm.powerOff()
                background: Rectangle { radius: 11; color: parent.hovered || parent.activeFocus ? Qt.rgba(root.errorColor.r, root.errorColor.g, root.errorColor.b, .76) : "transparent" }
                contentItem: Text { text: parent.text; color: root.foregroundColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: "Desligar"
                Controls.ToolTip.delay: 450
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
        onTriggered: if (root.revealed) password.forceActiveFocus()
    }

    SequentialAnimation {
        id: errorShake
        NumberAnimation { target: root; property: "errorOffset"; to: -10; duration: 45 }
        NumberAnimation { target: root; property: "errorOffset"; to: 10; duration: 75 }
        NumberAnimation { target: root; property: "errorOffset"; to: -6; duration: 65 }
        NumberAnimation { target: root; property: "errorOffset"; to: 0; duration: 55 }
    }

    Connections {
        target: sddm
        function onLoginSucceeded() {
            root.feedback = "Sessão iniciada"
        }
        function onLoginFailed() {
            root.authenticating = false
            root.feedback = "Falha ao entrar"
            root.password.text = ""
            root.revealed = true
            errorShake.restart()
            focusPassword.restart()
        }
        function onInformationMessage(message) {
            root.feedback = String(message)
        }
    }

    Timer {
        interval: 0
        running: true
        repeat: false
        onTriggered: root.loaded = true
    }

    Component.onCompleted: {
        if (root.username) sddm.currentUser = root.username
        root.forceActiveFocus()
    }

    Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
}
