import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.VirtualKeyboard
import "components"

FocusScope {
    id: root
    width: parent ? parent.width : 1920
    height: parent ? parent.height : 1080
    focus: true

    property bool loginVisible: false
    property bool keyboardVisible: false
    property bool authenticating: false
    property bool passwordVisible: false
    property int userIndex: userModel && userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int sessionIndex: sessionModel && sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    readonly property int userCount: userModel ? userModel.count : 0
    readonly property int sessionCount: sessionModel ? sessionModel.count : 0
    readonly property string username: userValue(Qt.EditRole, userValue(Qt.UserRole + 1, sddm.lastUser || ""))
    readonly property string realName: userValue(Qt.UserRole + 2, userValue(Qt.DisplayRole, username || "User"))
    readonly property string userIcon: userValue(Qt.UserRole + 3, "")
    readonly property string sessionName: sessionValue(sessionIndex)
    readonly property color accent: config.accentColor || "#d79921"
    readonly property color backgroundColor: config.backgroundColor || "#282828"
    readonly property color surfaceColor: config.surfaceColor || "#3c3836"
    readonly property color surfaceVariantColor: config.surfaceVariantColor || "#504945"
    readonly property color textColor: config.textColor || "#ebdbb2"
    readonly property color mutedColor: config.mutedColor || "#bdae93"
    readonly property color errorColor: config.errorColor || "#fb4934"
    readonly property string wallpaperSource: config.background || "file:///var/lib/hyprism/sddm/current-wallpaper.jpg"
    readonly property real contentWidth: Math.min(430, width - 36)
    readonly property var availableFonts: Qt.fontFamilies()
    readonly property string activeFontFamily: config.fontFamily && availableFonts.indexOf(config.fontFamily) >= 0 ? config.fontFamily : fontRegular.name

    FontLoader { id: fontRegular; source: "assets/fonts/FlexRounded-R.ttf" }
    FontLoader { id: fontMedium; source: "assets/fonts/FlexRounded-M.ttf" }
    FontLoader { id: fontBold; source: "assets/fonts/FlexRounded-B.ttf" }

    function userValue(role, fallback) {
        if (!userModel || userCount < 1 || userIndex < 0 || userIndex >= userCount) return fallback
        const value = userModel.data(userModel.index(userIndex, 0), role)
        return value === undefined || value === null || String(value).length === 0 ? fallback : String(value)
    }

    function sessionValueAt(index, role) {
        if (!sessionModel || index < 0 || index >= sessionCount) return ""
        const value = sessionModel.data(sessionModel.index(index, 0), role)
        return value === undefined || value === null ? "" : String(value)
    }

    function sessionValue(index) {
        return sessionValueAt(index, Qt.UserRole + 4) || sessionValueAt(index, Qt.UserRole + 2) || sessionValueAt(index, Qt.DisplayRole) || "Session"
    }

    function sessionDisplayName(index) {
        return sessionValueAt(index, Qt.DisplayRole) || sessionValueAt(index, Qt.UserRole + 4) || sessionValueAt(index, Qt.UserRole + 2) || "Session"
    }

    function sessionLogo(name) {
        const value = String(name || "").toLowerCase().split(".desktop")[0].split("/").pop().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "")
        const identities = [
            ["hyprland", /(^|-)hyprland($|-)/], ["dwm", /(^|-)dwm($|-)/],
            ["kdeplasma", /(^|-)plasma($|-)/], ["kdeplasma", /(^|-)kde($|-)/], ["gnome", /(^|-)gnome($|-)/],
            ["xfce", /(^|-)xfce($|-)/], ["sway", /(^|-)sway($|-)/],
            ["i3", /(^|-)i3($|-)/], ["qtile", /(^|-)qtile($|-)/],
            ["awesomewm", /(^|-)awesome(wm)?($|-)/], ["bspwm", /(^|-)bspwm($|-)/],
            ["cinnamon", /(^|-)cinnamon($|-)/], ["mate", /(^|-)mate($|-)/],
            ["lxde", /(^|-)lxde($|-)/], ["lxqt", /(^|-)lxqt($|-)/],
            ["dwl", /(^|-)dwl($|-)/]
        ]
        for (let i = 0; i < identities.length; i++) {
            if (!identities[i][1].test(value)) continue
            if (identities[i][0] === "dwl") return Qt.resolvedUrl("assets/logos/desktop.svg")
            return Qt.resolvedUrl("assets/logos/" + identities[i][0] + (identities[i][0] === "qtile" ? ".png" : ".svg"))
        }
        return Qt.resolvedUrl("assets/logos/desktop.svg")
    }

    function revealLogin() {
        loginVisible = true
        Qt.callLater(() => passwordField.forceActiveFocus())
    }

    function hideLogin() {
        if (authenticating) return
        loginVisible = false
        keyboardVisible = false
        passwordField.text = ""
        feedback.text = ""
        Qt.inputMethod.hide()
        forceActiveFocus()
    }

    function toggleKeyboard() {
        if (!loginVisible || authenticating) return
        keyboardVisible = !keyboardVisible
        passwordField.forceActiveFocus()
        if (keyboardVisible) Qt.inputMethod.show()
        else Qt.inputMethod.hide()
    }

    function login() {
        if (authenticating || !username || sessionIndex < 0 || sessionIndex >= sessionCount) return
        authenticating = true
        keyboardVisible = false
        Qt.inputMethod.hide()
        feedback.text = "Signing in…"
        sddm.login(username.trim(), passwordField.text, sessionIndex)
    }

    function cycleUser(step) {
        if (userCount < 2 || authenticating) return
        userIndex = (userIndex + step + userCount) % userCount
        sddm.currentUser = username
        passwordField.text = ""
        feedback.text = ""
        passwordField.forceActiveFocus()
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.authenticating = false
            root.feedback = "Sign-in failed. Check your password and try again."
            passwordField.text = ""
            passwordField.forceActiveFocus()
            shake.restart()
        }
        function onLoginSucceeded() { root.authenticating = false }
    }

    Keys.priority: Keys.BeforeItem
    Keys.onPressed: event => {
        if (!root.loginVisible && event.key !== Qt.Key_Shift && event.key !== Qt.Key_Control && event.key !== Qt.Key_Alt && event.key !== Qt.Key_Meta) {
            root.revealLogin()
            event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
            if (sessionMenu.opened) sessionMenu.close()
            else if (userMenu.opened) userMenu.close()
            else root.hideLogin()
            event.accepted = true
        }
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        source: root.wallpaperSource
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        cache: false
    }

    Rectangle {
        anchors.fill: parent
        color: root.backgroundColor
        opacity: wallpaper.status === Image.Ready ? (root.loginVisible ? 0.52 : 0.28) : 1
        Behavior on opacity { NumberAnimation { duration: 400 } }
    }

    MouseArea {
        anchors.fill: parent
        enabled: !root.loginVisible
        onClicked: root.revealLogin()
    }

    PowerBar {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 30
        anchors.rightMargin: 36
        textColor: root.textColor
        accentColor: root.accent
        surfaceColor: root.surfaceColor
    }

    Text {
        id: dateText
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 48
        anchors.leftMargin: 56
        text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
        color: root.textColor
        font.family: clock.fontFamily
        font.pixelSize: 20
        opacity: 1
    }

    Clock {
        id: clock
        anchors.centerIn: parent
        width: Math.min(parent.width - 40, 520)
        height: 310
        fontFamily: root.activeFontFamily
        baseAccent: root.accent
        defaultHoursColor: root.accent
        defaultMinutesColor: root.textColor
        opacity: root.loginVisible ? 0 : 1
        scale: root.loginVisible ? .94 : 1
        Behavior on opacity { NumberAnimation { duration: 350 } }
        Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 70
        text: "Press any key to sign in"
        color: root.textColor
        opacity: root.loginVisible ? 0 : .82
        font.family: clock.fontFamily
        font.pixelSize: 15
        Behavior on opacity { NumberAnimation { duration: 250 } }
    }

    Rectangle {
        id: loginCardSurface
        width: root.contentWidth + 34
        height: loginCard.height + 50
        x: (root.width - width) / 2
        y: loginCard.y - 25
        radius: 30
        color: root.backgroundColor
        opacity: root.loginVisible ? .78 : 0
        visible: opacity > 0
        border.width: 1
        border.color: root.surfaceVariantColor
        Behavior on opacity { NumberAnimation { duration: 260 } }
        Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
    }

    Column {
        id: loginCard
        width: root.contentWidth
        spacing: 14
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.loginVisible ? Math.max(22, (parent.height - height - (root.keyboardVisible ? virtualKeyboard.height : 0)) / 2 - 20) : parent.height + height
        opacity: root.loginVisible ? 1 : 0
        enabled: root.loginVisible
        transform: Translate { id: cardShake; x: 0 }
        Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 250 } }

        Item {
            width: parent.width
            height: 112
            Button {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 42
                height: 42
                visible: root.userCount > 1
                focusPolicy: Qt.NoFocus
                text: "‹"
                font.pixelSize: 32
                onClicked: root.cycleUser(-1)
                background: Rectangle { radius: 21; color: parent.hovered ? root.surfaceColor : "transparent" }
                contentItem: Text { text: parent.text; color: root.textColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
            }
            Rectangle {
                anchors.centerIn: parent
                width: 96
                height: 96
                radius: 30
                color: root.surfaceColor
                clip: true
                Image {
                    id: avatarImage
                    anchors.fill: parent
                    source: root.userIcon
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }
                Text {
                    anchors.centerIn: parent
                    visible: avatarImage.status !== Image.Ready
                    text: root.realName.length ? root.realName.charAt(0).toUpperCase() : "U"
                    color: root.accent
                    font.family: clock.fontFamily
                    font.pixelSize: 38
                    font.weight: Font.Medium
                }
            }
            Button {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 42
                height: 42
                visible: root.userCount > 1
                focusPolicy: Qt.NoFocus
                text: "›"
                font.pixelSize: 32
                onClicked: root.cycleUser(1)
                background: Rectangle { radius: 21; color: parent.hovered ? root.surfaceColor : "transparent" }
                contentItem: Text { text: parent.text; color: root.textColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
            }
        }

        Text {
            width: parent.width
            text: root.realName
            color: root.textColor
            font.family: clock.fontFamily
            font.pixelSize: 23
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        Button {
            id: sessionButton
            anchors.horizontalCenter: parent.horizontalCenter
            width: 214
            height: 40
            visible: root.sessionCount > 0
            focusPolicy: Qt.NoFocus
            onClicked: sessionMenu.open()
            background: Rectangle {
                radius: 20
                color: sessionButton.hovered || sessionMenu.opened ? root.surfaceVariantColor : root.surfaceColor
                border.width: sessionMenu.opened ? 1 : 0
                border.color: root.accent
            }
            contentItem: Row {
                spacing: 9
                SessionLogo { width: 20; height: 20; anchors.verticalCenter: parent.verticalCenter; source: root.sessionLogo(root.sessionName) }
                Text { anchors.verticalCenter: parent.verticalCenter; text: root.sessionDisplayName(root.sessionIndex) + (root.sessionCount > 1 ? "  ▾" : ""); color: root.textColor; font.family: clock.fontFamily; font.pixelSize: 14; elide: Text.ElideRight; width: 170 }
            }
        }

        Row {
            width: parent.width
            height: 56
            spacing: 9

            Rectangle {
                id: passwordSurface
                width: parent.width - submitButton.width - parent.spacing
                height: parent.height
                radius: 16
                color: root.surfaceColor
                border.width: passwordField.activeFocus ? 1 : 0
                border.color: root.accent
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 8
                    spacing: 7
                    Text { text: "●"; color: passwordField.activeFocus ? root.accent : root.mutedColor; font.pixelSize: 12 }
                    TextField {
                        id: passwordField
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        focus: root.loginVisible
                        enabled: !root.authenticating
                        echoMode: root.passwordVisible ? TextInput.Normal : TextInput.Password
                        placeholderText: "Enter password"
                        color: root.textColor
                        placeholderTextColor: root.mutedColor
                        font.family: clock.fontFamily
                        font.pixelSize: 16
                        background: Item {}
                        selectByMouse: true
                        onAccepted: root.login()
                    }
                    ToolButton {
                        Layout.preferredWidth: 34
                        Layout.fillHeight: true
                        focusPolicy: Qt.NoFocus
                        text: root.passwordVisible ? "◉" : "◎"
                        onClicked: root.passwordVisible = !root.passwordVisible
                        contentItem: Text { text: parent.text; color: root.mutedColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 17 }
                        background: Item {}
                    }
                }
            }

            Button {
                id: submitButton
                width: 56
                height: parent.height
                enabled: !root.authenticating
                focusPolicy: Qt.NoFocus
                onClicked: root.login()
                background: Rectangle {
                    radius: 16
                    color: root.authenticating ? root.surfaceVariantColor : (submitButton.down ? Qt.darker(root.accent, 1.12) : root.accent)
                    Behavior on color { ColorAnimation { duration: 110 } }
                }
                contentItem: Text {
                    text: root.authenticating ? "…" : "→"
                    color: config.accentForegroundColor || root.backgroundColor
                    font.pixelSize: 27
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            Button {
                width: 38
                height: 34
                focusPolicy: Qt.NoFocus
                text: "⌨"
                onClicked: root.toggleKeyboard()
                background: Rectangle { radius: 12; color: root.keyboardVisible || parent.hovered ? root.surfaceVariantColor : "transparent" }
                contentItem: Text { text: parent.text; color: root.keyboardVisible ? root.accent : root.textColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 19 }
            }
            Button {
                width: 38
                height: 34
                visible: root.userCount > 1
                focusPolicy: Qt.NoFocus
                text: "⌄"
                onClicked: userMenu.open()
                background: Rectangle { radius: 12; color: parent.hovered ? root.surfaceVariantColor : "transparent" }
                contentItem: Text { text: parent.text; color: root.textColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 20 }
            }
        }

        Text {
            id: feedback
            width: parent.width
            color: root.authenticating ? root.mutedColor : root.errorColor
            text: ""
            visible: text.length > 0
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.family: clock.fontFamily
            font.pixelSize: 13
        }
    }

    SequentialAnimation {
        id: shake
        loops: 2
        NumberAnimation { target: cardShake; property: "x"; to: -8; duration: 45 }
        NumberAnimation { target: cardShake; property: "x"; to: 8; duration: 90 }
        NumberAnimation { target: cardShake; property: "x"; to: 0; duration: 45 }
    }

    Popup {
        id: sessionMenu
        width: Math.min(320, root.width - 32)
        height: Math.min(300, root.sessionCount * 48 + 20)
        x: (root.width - width) / 2
        y: Math.max(12, loginCard.y + 150)
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onOpened: sessionList.forceActiveFocus()
        background: Rectangle { color: root.backgroundColor; radius: 22; border.width: 1; border.color: root.surfaceVariantColor }
        ListView {
            id: sessionList
            anchors.fill: parent
            anchors.margins: 9
            model: sessionModel
            currentIndex: root.sessionIndex
            clip: true
            delegate: ItemDelegate {
                width: ListView.view.width
                height: 44
                property bool selected: index === sessionList.currentIndex
                background: Rectangle { color: parent.selected ? root.surfaceVariantColor : (parent.hovered ? root.surfaceColor : "transparent"); radius: 13 }
                contentItem: RowLayout {
                    spacing: 10
                    SessionLogo { Layout.preferredWidth: 22; Layout.preferredHeight: 22; source: root.sessionLogo(root.sessionValue(index)) }
                    Text { Layout.fillWidth: true; text: root.sessionDisplayName(index); color: parent.parent.selected ? root.textColor : root.mutedColor; font.family: clock.fontFamily; font.pixelSize: 14; elide: Text.ElideRight }
                    Text { text: parent.parent.selected ? "✓" : ""; color: root.accent; font.pixelSize: 16 }
                }
                onClicked: { root.sessionIndex = index; sessionMenu.close(); passwordField.forceActiveFocus() }
            }
            Keys.onDownPressed: incrementCurrentIndex()
            Keys.onUpPressed: decrementCurrentIndex()
            Keys.onReturnPressed: { root.sessionIndex = currentIndex; sessionMenu.close(); passwordField.forceActiveFocus() }
            Keys.onEnterPressed: { root.sessionIndex = currentIndex; sessionMenu.close(); passwordField.forceActiveFocus() }
        }
    }

    Popup {
        id: userMenu
        width: Math.min(300, root.width - 32)
        height: Math.min(280, root.userCount * 48 + 20)
        x: (root.width - width) / 2
        y: Math.max(12, loginCard.y + 120)
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onOpened: userList.forceActiveFocus()
        background: Rectangle { color: root.backgroundColor; radius: 22; border.width: 1; border.color: root.surfaceVariantColor }
        ListView {
            id: userList
            anchors.fill: parent
            anchors.margins: 9
            model: userModel
            currentIndex: root.userIndex
            clip: true
            delegate: ItemDelegate {
                width: ListView.view.width
                height: 44
                property bool selected: index === userList.currentIndex
                background: Rectangle { color: parent.selected ? root.surfaceVariantColor : (parent.hovered ? root.surfaceColor : "transparent"); radius: 13 }
                contentItem: Text {
                    text: userModel.data(userModel.index(index, 0), Qt.UserRole + 2) || userModel.data(userModel.index(index, 0), Qt.DisplayRole) || userModel.data(userModel.index(index, 0), Qt.EditRole)
                    color: parent.parent.selected ? root.textColor : root.mutedColor
                    font.family: clock.fontFamily
                    font.pixelSize: 14
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 12
                }
                onClicked: { root.userIndex = index; sddm.currentUser = root.username; passwordField.text = ""; feedback.text = ""; userMenu.close(); passwordField.forceActiveFocus() }
            }
            Keys.onDownPressed: incrementCurrentIndex()
            Keys.onUpPressed: decrementCurrentIndex()
            Keys.onReturnPressed: { root.userIndex = currentIndex; userMenu.close(); passwordField.forceActiveFocus() }
            Keys.onEnterPressed: { root.userIndex = currentIndex; userMenu.close(); passwordField.forceActiveFocus() }
        }
    }

    InputPanel {
        id: virtualKeyboard
        x: 0
        y: root.keyboardVisible ? root.height - height : root.height
        width: root.width
        visible: root.keyboardVisible
        z: 20
        Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    }

}
