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
    readonly property string realName: userValue(258, username || "User")
    readonly property string userIcon: userValue(260, "")
    readonly property string sessionName: sessionValue(sessionIndex, 260, "Session")
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
        feedback = "Logging in"
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
            height: 108

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

            Item {
                anchors.centerIn: parent
                width: 104
                height: 104

                Rectangle {
                    anchors.centerIn: parent
                    width: 98
                    height: 98
                    radius: 29
                    color: Qt.rgba(root.surfaceColor.r, root.surfaceColor.g, root.surfaceColor.b, .92)
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: "#b0000000"
                        shadowBlur: .82
                        shadowVerticalOffset: 3
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 88
                    height: 88
                    radius: 24
                    color: root.surfaceContainerColor
                    clip: true
                    layer.enabled: true
                    layer.smooth: true

                    Image {
                        id: avatarImage
                        anchors.fill: parent
                        source: root.userIcon
                        fillMode: Image.PreserveAspectCrop
                        visible: false
                    }

                    Rectangle {
                        id: avatarMask
                        anchors.fill: avatarImage
                        radius: parent.radius
                        color: "white"
                        visible: false
                        layer.enabled: true
                    }

                    MultiEffect {
                        anchors.fill: avatarImage
                        source: avatarImage
                        maskEnabled: true
                        maskSource: avatarMask
                        visible: avatarImage.status === Image.Ready
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
            readonly property point origin: passwordSurface.mapToItem(wallpaper, 0, 0)
            sourceRect: Qt.rect(origin.x, origin.y, passwordSurface.width, passwordSurface.height)
            live: true
            recursive: true
            visible: false
        }

        Row {
            width: parent.width
            height: 50
            spacing: 8

            Rectangle {
                id: passwordSurface
                width: parent.width - loginButton.width - parent.spacing
                height: parent.height
                radius: 15
                color: "transparent"
                clip: true
                layer.enabled: true
                layer.smooth: true

                Rectangle {
                    id: passwordMask
                    anchors.fill: parent
                    radius: parent.radius
                    color: "white"
                    visible: false
                    layer.enabled: true
                }

                MultiEffect {
                    anchors.fill: parent
                    source: passwordBackdrop
                    blurEnabled: true
                    blur: .42
                    blurMax: 18
                    autoPaddingEnabled: false
                    maskEnabled: true
                    maskSource: passwordMask
                }

                Rectangle {
                    anchors.fill: parent
                    color: password.activeFocus ? Qt.rgba(root.surfaceContainerHighColor.r, root.surfaceContainerHighColor.g, root.surfaceContainerHighColor.b, .88) : Qt.rgba(root.surfaceColor.r, root.surfaceColor.g, root.surfaceColor.b, .74)
                    border.width: 0
                    radius: parent.radius
                    clip: true

                    Behavior on color { ColorAnimation { duration: 110 } }
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
                    placeholderText: "Password"
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
                    Controls.ToolTip.text: root.passwordVisible ? "Hide password" : "Show password"
                    Controls.ToolTip.delay: 450
                }
            }

            Controls.Button {
                id: loginButton
                width: 50
                height: parent.height
                enabled: !root.authenticating && root.username.length > 0
                text: root.authenticating ? "󰔟" : "󰁔"
                font.family: "Symbols Nerd Font Mono"
                font.pixelSize: 19
                onClicked: root.login()
                scale: pressed ? .94 : 1
                background: Rectangle {
                    radius: 15
                    color: parent.enabled ? root.primaryColor : root.surfaceContainerColor
                    opacity: parent.enabled ? parent.hovered || parent.activeFocus ? 1 : .9 : .58
                    border.width: 0
                    Behavior on color { ColorAnimation { duration: 110 } }
                }
                contentItem: Text { text: parent.text; color: root.onPrimaryColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
                Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                Controls.ToolTip.visible: hovered
                Controls.ToolTip.text: root.authenticating ? "Authenticating" : "Log in"
                Controls.ToolTip.delay: 450
            }
        }

        Text {
            width: parent.width
            height: 15
            text: root.feedback
            color: root.feedback === "Login failed" ? root.errorColor : root.mutedColor
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
        width: 42
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
            border.width: 0
        }
        contentItem: Item {
            anchors.centerIn: parent
            Text {
                anchors.centerIn: parent
                text: root.sessionProfile(root.sessionIndex).glyph
                color: root.primaryColor
                font.family: "Symbols Nerd Font Mono"
                font.pixelSize: 19
            }
        }
        Controls.ToolTip.visible: hovered
        Controls.ToolTip.text: root.sessionName
        Controls.ToolTip.delay: 450
    }

    Rectangle {
        id: sessionPicker
        anchors.left: parent.left
        anchors.bottom: sessionButton.top
        anchors.leftMargin: 24
        anchors.bottomMargin: 10
        width: Math.min(252, parent.width - 48)
        readonly property int entryHeight: 46
        readonly property int entrySpacing: 6
        readonly property real requestedHeight: sessionList.contentHeight + 16
        height: Math.min(Math.max(62, requestedHeight), Math.max(72, parent.height - sessionButton.height - 96))
        radius: 16
        color: Qt.rgba(root.surfaceColor.r, root.surfaceColor.g, root.surfaceColor.b, .9)
        opacity: root.sessionsVisible ? 1 : 0
        visible: opacity > 0
        enabled: root.sessionsVisible
        border.width: 0
        clip: true

        ListView {
            id: sessionList
            anchors.fill: parent
            anchors.margins: 8
            model: root.sessionCount
            spacing: sessionPicker.entrySpacing
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            delegate: Controls.Button {
                id: sessionItem
                readonly property string name: root.sessionValue(index, 260, "Session")
                readonly property var profile: root.sessionProfile(index)
                readonly property bool selected: root.sessionIndex === index
                width: sessionList.width
                height: sessionPicker.entryHeight
                enabled: !root.authenticating
                text: ""
                onClicked: root.selectSession(index)
                background: Rectangle {
                    radius: 12
                    color: sessionItem.selected ? Qt.rgba(root.primaryColor.r, root.primaryColor.g, root.primaryColor.b, .22) : sessionItem.hovered || sessionItem.activeFocus ? root.surfaceHoverColor : "transparent"
                    border.width: 0
                    Behavior on color { ColorAnimation { duration: 100 } }
                }
                contentItem: Item {
                    anchors.fill: parent
                    Text {
                        id: sessionIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 13
                        anchors.verticalCenter: parent.verticalCenter
                        text: sessionItem.profile.glyph
                        color: sessionItem.selected ? root.primaryColor : root.foregroundColor
                        font.family: "Symbols Nerd Font Mono"
                        font.pixelSize: 19
                    }
                    Text {
                        anchors.left: sessionIcon.right
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 13
                        anchors.verticalCenter: parent.verticalCenter
                        text: sessionItem.name
                        color: sessionItem.selected ? root.foregroundColor : root.mutedColor
                        elide: Text.ElideRight
                        font.family: "Google Sans Flex"
                        font.pixelSize: 12
                        font.weight: sessionItem.selected ? Font.Medium : Font.Normal
                    }
                }
                Controls.ToolTip.visible: false
            }

            Controls.ScrollBar.vertical: Controls.ScrollBar { policy: Controls.ScrollBar.AsNeeded }
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
                border.width: 0
            }
            contentItem: Text { text: parent.text; color: root.keyboardVisible ? root.primaryColor : root.foregroundColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
            Controls.ToolTip.visible: hovered
            Controls.ToolTip.text: "Virtual keyboard"
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
                border.width: 0
            }
            contentItem: Text { text: parent.text; color: root.foregroundColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
            Controls.ToolTip.visible: hovered
            Controls.ToolTip.text: "Power"
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
        border.width: 0

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
                Controls.ToolTip.text: "Suspend"
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
                Controls.ToolTip.text: "Restart"
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
                Controls.ToolTip.text: "Shut down"
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
            root.feedback = "Session started"
        }
        function onLoginFailed() {
            root.authenticating = false
            root.feedback = "Login failed"
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
