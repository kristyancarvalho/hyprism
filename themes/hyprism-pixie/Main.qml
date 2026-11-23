import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.VirtualKeyboard
import QtQuick.VirtualKeyboard.Settings
import "components"
import "imports/HyprismPixie"

FocusScope {
    id: root
    width: parent ? parent.width : 1920
    height: parent ? parent.height : 1080
    focus: true

    readonly property var translations: ({
        "en": {
            pressAnyKey: "Press any key to sign in",
            password: "Enter password",
            showPassword: "Show password",
            hidePassword: "Hide password",
            keyboard: "Virtual keyboard",
            signIn: "Sign in",
            signingIn: "Signing in…",
            failed: "Sign-in failed. Check your password and try again.",
            previousUser: "Previous user",
            nextUser: "Next user",
            chooseUser: "Choose user",
            chooseSession: "Choose session",
            keyboardLayout: "Keyboard layout",
            suspend: "Suspend",
            restart: "Restart",
            shutdown: "Shut down",
            user: "User",
            session: "Session",
            dateFormat: "dddd, MMMM d"
        },
        "pt-BR": {
            pressAnyKey: "Pressione qualquer tecla para entrar",
            password: "Digite a senha",
            showPassword: "Mostrar senha",
            hidePassword: "Ocultar senha",
            keyboard: "Teclado virtual",
            signIn: "Entrar",
            signingIn: "Entrando…",
            failed: "Falha ao entrar. Verifique a senha e tente novamente.",
            previousUser: "Usuário anterior",
            nextUser: "Próximo usuário",
            chooseUser: "Escolher usuário",
            chooseSession: "Escolher sessão",
            keyboardLayout: "Layout do teclado",
            suspend: "Suspender",
            restart: "Reiniciar",
            shutdown: "Desligar",
            user: "Usuário",
            session: "Sessão",
            dateFormat: "dddd, d 'de' MMMM"
        }
    })
    readonly property string language: config.language === "pt-BR" ? "pt-BR" : "en"
    readonly property var locale: Qt.locale(language === "pt-BR" ? "pt_BR" : "en_US")
    property date now: new Date()

    property bool loginVisible: false
    property bool introduced: false
    property bool authenticating: false
    property bool passwordVisible: false
    readonly property bool keyboardVisible: loginVisible && virtualKeyboard.active
    property int userIndex: userModel && userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int sessionIndex: sessionModel && sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    readonly property int userCount: userModel ? userModel.count : 0
    readonly property int sessionCount: sessionModel ? sessionModel.count : 0
    readonly property string username: userValue(Qt.EditRole, userValue(Qt.UserRole + 1, sddm.lastUser || ""))
    readonly property string realName: userValue(Qt.UserRole + 2, userValue(Qt.DisplayRole, username || tr("user")))
    readonly property string userIcon: userValue(Qt.UserRole + 3, "")
    readonly property string sessionName: sessionValue(sessionIndex)
    readonly property color accent: config.accentColor || "#d79921"
    readonly property color backgroundColor: config.backgroundColor || "#282828"
    readonly property color surfaceColor: config.surfaceColor || "#3c3836"
    readonly property color surfaceVariantColor: config.surfaceVariantColor || "#504945"
    readonly property color textColor: config.textColor || "#ebdbb2"
    readonly property color mutedColor: config.mutedColor || "#bdae93"
    readonly property color errorColor: config.errorColor || "#fb4934"
    readonly property color accentForeground: config.accentForegroundColor || backgroundColor
    readonly property string wallpaperSource: config.background || "file:///var/lib/hyprism/sddm/current-wallpaper.jpg"
    readonly property real contentWidth: Math.min(430, width - 70)
    readonly property real cardPadding: 17
    readonly property real cardVerticalPadding: 25
    readonly property real keyboardMargin: 24
    readonly property real keyboardGap: 24
    readonly property var availableFonts: Qt.fontFamilies()
    readonly property string fontFamily: config.fontFamily && availableFonts.indexOf(config.fontFamily) >= 0 ? config.fontFamily : flexRegular.name
    readonly property string clockFontFamily: googleSansRegular.status === FontLoader.Ready ? googleSansRegular.name : "Google Sans Flex"

    FontLoader { id: flexRegular; source: "assets/fonts/FlexRounded-R.ttf" }
    FontLoader { id: flexMedium; source: "assets/fonts/FlexRounded-M.ttf" }
    FontLoader { id: flexBold; source: "assets/fonts/FlexRounded-B.ttf" }
    FontLoader { id: googleSansRegular; source: "assets/fonts/GoogleSansFlex-Regular.ttf" }
    FontLoader { id: googleSansMedium; source: "assets/fonts/GoogleSansFlex-Medium.ttf" }
    FontLoader { id: googleSansSemiBold; source: "assets/fonts/GoogleSansFlex-SemiBold.ttf" }
    FontLoader { id: iconFont; source: "assets/fonts/MaterialDesignIcons.ttf" }

    Binding { target: KeyboardPalette; property: "background"; value: root.backgroundColor }
    Binding { target: KeyboardPalette; property: "surface"; value: root.surfaceColor }
    Binding { target: KeyboardPalette; property: "surfaceVariant"; value: root.surfaceVariantColor }
    Binding { target: KeyboardPalette; property: "accent"; value: root.accent }
    Binding { target: KeyboardPalette; property: "accentForeground"; value: root.accentForeground }
    Binding { target: KeyboardPalette; property: "text"; value: root.textColor }
    Binding { target: KeyboardPalette; property: "muted"; value: root.mutedColor }
    Binding { target: KeyboardPalette; property: "error"; value: root.errorColor }
    Binding { target: KeyboardPalette; property: "fontFamily"; value: root.fontFamily }
    Binding { target: KeyboardPalette; property: "iconFamily"; value: iconFont.name }

    function tr(key) {
        const table = translations[language] || translations["en"]
        return table[key] !== undefined ? table[key] : translations["en"][key]
    }

    function glyph(codePoint) {
        return String.fromCodePoint(codePoint)
    }

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
        return sessionValueAt(index, Qt.UserRole + 4) || sessionValueAt(index, Qt.UserRole + 2) || sessionValueAt(index, Qt.DisplayRole) || tr("session")
    }

    function sessionDisplayName(index) {
        return sessionValueAt(index, Qt.DisplayRole) || sessionValueAt(index, Qt.UserRole + 4) || sessionValueAt(index, Qt.UserRole + 2) || tr("session")
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
        passwordField.text = ""
        feedback.text = ""
        Qt.inputMethod.hide()
        forceActiveFocus()
    }

    function toggleKeyboard() {
        if (!loginVisible || authenticating) return
        passwordField.forceActiveFocus()
        if (virtualKeyboard.active) Qt.inputMethod.hide()
        else Qt.inputMethod.show()
    }

    function login() {
        if (authenticating || !username || sessionIndex < 0 || sessionIndex >= sessionCount) return
        authenticating = true
        Qt.inputMethod.hide()
        feedback.text = tr("signingIn")
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

    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.authenticating = false
            feedback.text = root.tr("failed")
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

    Item {
        id: backdrop
        anchors.fill: parent
        layer.enabled: true

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
    }

    MultiEffect {
        id: blurredBackdrop
        anchors.fill: backdrop
        source: backdrop
        blurEnabled: true
        blur: 1
        blurMax: 36
        autoPaddingEnabled: false
        visible: false
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
        power: sddm
        opacity: root.introduced ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        textColor: root.textColor
        accentColor: root.accent
        surfaceColor: root.surfaceColor
        fontFamily: root.fontFamily
        iconFamily: iconFont.name
        suspendText: root.tr("suspend")
        restartText: root.tr("restart")
        shutdownText: root.tr("shutdown")
        layoutText: root.tr("keyboardLayout")
    }

    Text {
        id: dateText
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 48
        anchors.leftMargin: 56
        text: root.locale.toString(root.now, root.tr("dateFormat"))
        opacity: root.introduced ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        color: root.textColor
        font.family: root.fontFamily
        font.pixelSize: 20
    }

    Clock {
        id: clock
        anchors.centerIn: parent
        width: Math.min(parent.width - 40, 520)
        height: 310
        fontFamily: root.clockFontFamily
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
        text: root.tr("pressAnyKey")
        color: root.textColor
        opacity: root.loginVisible ? 0 : .82
        font.family: root.fontFamily
        font.pixelSize: 15
        Behavior on opacity { NumberAnimation { duration: 250 } }
    }

    Item {
        id: card
        width: root.contentWidth + root.cardPadding * 2
        height: loginCard.height + root.cardVerticalPadding * 2
        x: (root.width - width) / 2
        readonly property real keyboardReserve: root.keyboardVisible ? virtualKeyboard.height + root.keyboardMargin + root.keyboardGap : 0
        readonly property real restingY: Math.max(24, (root.height - keyboardReserve - height) / 2 - (root.keyboardVisible ? 0 : 20))
        y: root.loginVisible ? restingY : root.height
        opacity: root.loginVisible ? 1 : 0
        visible: opacity > 0
        enabled: root.loginVisible
        transform: Translate { id: cardShake; x: 0 }
        Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 260 } }

        Item {
            id: cardSurface
            anchors.fill: parent

            Item {
                id: blurClip
                anchors.fill: parent
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: cardMask
                }
                ShaderEffectSource {
                    anchors.fill: parent
                    sourceItem: blurredBackdrop
                    sourceRect: Qt.rect(card.x + cardShake.x, card.y, card.width, card.height)
                    live: card.visible
                }
            }

            Rectangle {
                id: cardMask
                anchors.fill: parent
                radius: 30
                layer.enabled: true
                visible: false
            }

            Rectangle {
                anchors.fill: parent
                radius: 30
                color: Qt.rgba(root.backgroundColor.r, root.backgroundColor.g, root.backgroundColor.b, .46)
                border.width: 1
                border.color: Qt.rgba(root.surfaceVariantColor.r, root.surfaceVariantColor.g, root.surfaceVariantColor.b, .8)
            }
        }

        Column {
            id: loginCard
            x: root.cardPadding
            y: root.cardVerticalPadding
            width: root.contentWidth
            spacing: 14

            Item {
                width: parent.width
                height: 112
                Button {
                    id: previousUserButton
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 42
                    height: 42
                    visible: root.userCount > 1
                    focusPolicy: Qt.NoFocus
                    onClicked: root.cycleUser(-1)
                    ToolTip.visible: hovered
                    ToolTip.text: root.tr("previousUser")
                    Accessible.name: root.tr("previousUser")
                    background: Rectangle { radius: 21; color: parent.hovered ? root.surfaceColor : "transparent" }
                    contentItem: Text { text: root.glyph(0xF0141); color: root.textColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.family: iconFont.name; font.pixelSize: 28 }
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
                        text: root.glyph(0xF0004)
                        color: root.accent
                        font.family: iconFont.name
                        font.pixelSize: 58
                    }
                }
                Button {
                    id: nextUserButton
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 42
                    height: 42
                    visible: root.userCount > 1
                    focusPolicy: Qt.NoFocus
                    onClicked: root.cycleUser(1)
                    ToolTip.visible: hovered
                    ToolTip.text: root.tr("nextUser")
                    Accessible.name: root.tr("nextUser")
                    background: Rectangle { radius: 21; color: parent.hovered ? root.surfaceColor : "transparent" }
                    contentItem: Text { text: root.glyph(0xF0142); color: root.textColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.family: iconFont.name; font.pixelSize: 28 }
                }
            }

            Text {
                width: parent.width
                text: root.realName
                color: root.textColor
                font.family: root.fontFamily
                font.pixelSize: 23
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            Button {
                id: sessionButton
                anchors.horizontalCenter: parent.horizontalCenter
                width: 290
                height: 40
                visible: root.sessionCount > 0
                focusPolicy: Qt.NoFocus
                onClicked: sessionMenu.open()
                Accessible.name: root.tr("chooseSession")
                background: Rectangle {
                    radius: 20
                    color: sessionButton.hovered || sessionMenu.opened ? root.surfaceVariantColor : root.surfaceColor
                    border.width: sessionMenu.opened ? 1 : 0
                    border.color: root.accent
                }
                contentItem: Item {
                    TextMetrics { id: sessionMetrics; font.family: root.fontFamily; font.pixelSize: 14; text: root.sessionDisplayName(root.sessionIndex) }
                    Row {
                        anchors.centerIn: parent
                        spacing: 10
                        SessionLogo { width: 20; height: 20; anchors.verticalCenter: parent.verticalCenter; source: root.sessionLogo(root.sessionName) }
                        Text { id: sessionLabel; anchors.verticalCenter: parent.verticalCenter; text: root.sessionDisplayName(root.sessionIndex); color: root.textColor; font.family: root.fontFamily; font.pixelSize: 14; elide: Text.ElideRight; width: Math.min(sessionMetrics.width, 210) }
                        Text { visible: root.sessionCount > 1; anchors.verticalCenter: parent.verticalCenter; text: root.glyph(0xF0140); color: root.mutedColor; font.family: iconFont.name; font.pixelSize: 18 }
                    }
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
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 4
                        TextField {
                            id: passwordField
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            focus: root.loginVisible
                            enabled: !root.authenticating
                            echoMode: root.passwordVisible ? TextInput.Normal : TextInput.Password
                            inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase | Qt.ImhPreferLowercase
                            placeholderText: root.tr("password")
                            color: root.textColor
                            placeholderTextColor: root.mutedColor
                            font.family: root.fontFamily
                            font.pixelSize: 16
                            leftPadding: 8
                            background: Item {}
                            selectByMouse: true
                            onAccepted: root.login()
                        }
                        ToolButton {
                            id: visibilityButton
                            Layout.preferredWidth: 38
                            Layout.preferredHeight: 38
                            Layout.alignment: Qt.AlignVCenter
                            focusPolicy: Qt.NoFocus
                            onClicked: root.passwordVisible = !root.passwordVisible
                            ToolTip.visible: hovered
                            ToolTip.text: root.passwordVisible ? root.tr("hidePassword") : root.tr("showPassword")
                            Accessible.name: ToolTip.text
                            contentItem: Text {
                                text: root.glyph(root.passwordVisible ? 0xF0209 : 0xF0208)
                                color: visibilityButton.down ? root.accent : (visibilityButton.hovered ? root.textColor : root.mutedColor)
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.family: iconFont.name
                                font.pixelSize: 22
                            }
                            background: Rectangle {
                                radius: 12
                                color: visibilityButton.down ? root.surfaceVariantColor : (visibilityButton.hovered ? Qt.rgba(root.surfaceVariantColor.r, root.surfaceVariantColor.g, root.surfaceVariantColor.b, .6) : "transparent")
                            }
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
                    ToolTip.visible: hovered
                    ToolTip.text: root.tr("signIn")
                    Accessible.name: root.tr("signIn")
                    background: Rectangle {
                        radius: 16
                        color: root.authenticating ? root.surfaceVariantColor : (submitButton.down ? Qt.darker(root.accent, 1.12) : root.accent)
                        Behavior on color { ColorAnimation { duration: 110 } }
                    }
                    contentItem: Text {
                        text: root.authenticating ? "…" : root.glyph(0xF0054)
                        color: root.accentForeground
                        font.family: iconFont.name
                        font.pixelSize: 26
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
                Button {
                    id: keyboardButton
                    width: 38
                    height: 34
                    focusPolicy: Qt.NoFocus
                    onClicked: root.toggleKeyboard()
                    ToolTip.visible: hovered
                    ToolTip.text: root.tr("keyboard")
                    Accessible.name: root.tr("keyboard")
                    background: Rectangle { radius: 12; color: root.keyboardVisible || keyboardButton.hovered ? root.surfaceVariantColor : "transparent" }
                    contentItem: Text { text: root.glyph(0xF030C); color: root.keyboardVisible ? root.accent : root.textColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.family: iconFont.name; font.pixelSize: 22 }
                }
                Button {
                    id: userMenuButton
                    width: 38
                    height: 34
                    visible: root.userCount > 1
                    focusPolicy: Qt.NoFocus
                    onClicked: userMenu.open()
                    ToolTip.visible: hovered
                    ToolTip.text: root.tr("chooseUser")
                    Accessible.name: root.tr("chooseUser")
                    background: Rectangle { radius: 12; color: userMenuButton.hovered ? root.surfaceVariantColor : "transparent" }
                    contentItem: Text { text: root.glyph(0xF0140); color: root.textColor; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.family: iconFont.name; font.pixelSize: 22 }
                }
            }

            Text {
                id: feedback
                width: parent.width
                color: root.authenticating ? root.mutedColor : root.errorColor
                text: ""
                visible: text.length > 0 || opacity > 0
                opacity: text.length > 0 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                font.family: root.fontFamily
                font.pixelSize: 13
            }
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
        y: Math.max(12, card.y + 175)
        enter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale"; from: .94; to: 1; duration: 220; easing.type: Easing.OutCubic }
            }
        }
        exit: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; to: 0; duration: 130; easing.type: Easing.InCubic }
                NumberAnimation { property: "scale"; to: .96; duration: 130; easing.type: Easing.InCubic }
            }
        }
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
                    Text { Layout.fillWidth: true; text: root.sessionDisplayName(index); color: parent.parent.selected ? root.textColor : root.mutedColor; font.family: root.fontFamily; font.pixelSize: 14; elide: Text.ElideRight }
                    Text { text: parent.parent.selected ? root.glyph(0xF012C) : ""; color: root.accent; font.family: iconFont.name; font.pixelSize: 18 }
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
        y: Math.max(12, card.y + 145)
        enter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale"; from: .94; to: 1; duration: 220; easing.type: Easing.OutCubic }
            }
        }
        exit: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; to: 0; duration: 130; easing.type: Easing.InCubic }
                NumberAnimation { property: "scale"; to: .96; duration: 130; easing.type: Easing.InCubic }
            }
        }
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
                    font.family: root.fontFamily
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
        width: Math.min(root.width - 32, Math.max(640, root.height * 1.056))
        x: (root.width - width) / 2
        y: active && root.loginVisible ? root.height - height - root.keyboardMargin : root.height
        visible: y < root.height
        opacity: active && root.loginVisible ? 1 : 0
        z: 20
        Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    Component.onCompleted: {
        VirtualKeyboardSettings.styleName = "hyprism"
        introduced = true
    }
}
