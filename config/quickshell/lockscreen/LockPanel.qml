import QtQuick
import "../components"
import ".."

Glass {
    id: panel
    required property var session
    required property var controller
    required property real screenWidth
    readonly property var shellConfig: controller.config.shell
    readonly property bool revealed: session.promptVisible && session.secure
    readonly property bool failed: session.authState === "failed" || session.authState === "maxTries" || session.authState === "error"
    readonly property string statusText: {
        if (session.authState === "authenticating") return I18n.tr("lockscreen.authenticating")
        if (session.authState === "failed") return I18n.tr("lockscreen.failed")
        if (session.authState === "maxTries") return I18n.tr("lockscreen.tooMany")
        if (session.authState === "error") return I18n.tr("lockscreen.error")
        return session.pamMessage
    }
    readonly property int horizontalPadding: Design.compactHorizontalPadding
    readonly property real barWidth: Design.compactWidth(shellConfig, screenWidth)
    readonly property real restWidth: Math.max(Math.min(barWidth, 280), Math.round(barWidth * .62))
    property real shake: 0
    property real lift: revealed ? 0 : -8
    property int nextDot: 0

    anchors.top: parent.top
    anchors.topMargin: Design.compactTopMargin(shellConfig) + lift
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.horizontalCenterOffset: shake
    width: restWidth + (barWidth - restWidth) * session.morphProgress
    height: Design.compactHeight(shellConfig)
    radius: Design.radiusIslandCompact
    surfaceOpacity: shellConfig.surfaceOpacity
    opacity: revealed ? 1 : 0
    visible: opacity > 0

    Behavior on opacity { NumberAnimation { duration: panel.revealed ? 220 : 170; easing.type: panel.revealed ? Easing.OutCubic : Easing.InCubic } }
    Behavior on lift { NumberAnimation { duration: panel.revealed ? 240 : 170; easing.type: panel.revealed ? Easing.OutCubic : Easing.InCubic } }

    ListModel { id: dotModel }

    function syncDots(): void {
        const target = session.secretLength
        if (target === 0) {
            dotModel.clear()
            return
        }
        let live = 0
        for (let index = 0; index < dotModel.count; index++) if (!dotModel.get(index).leaving) live++
        while (live < target) {
            dotModel.append({ uid: nextDot++, slot: live, leaving: false })
            live++
        }
        for (let index = dotModel.count - 1; index >= 0 && live > target; index--) {
            if (dotModel.get(index).leaving) continue
            dotModel.setProperty(index, "leaving", true)
            live--
        }
    }

    function removeDot(uid: int): void {
        for (let index = 0; index < dotModel.count; index++) {
            if (dotModel.get(index).uid === uid) {
                dotModel.remove(index)
                return
            }
        }
    }

    SequentialAnimation {
        id: shakeAnimation
        NumberAnimation { target: panel; property: "shake"; to: -8; duration: 45 }
        NumberAnimation { target: panel; property: "shake"; to: 8; duration: 70 }
        NumberAnimation { target: panel; property: "shake"; to: -5; duration: 60 }
        NumberAnimation { target: panel; property: "shake"; to: 0; duration: 45 }
    }

    Connections {
        target: panel.session
        function onFailureShown(): void { shakeAnimation.restart() }
        function onSecretLengthChanged(): void { panel.syncDots() }
    }

    CompactBarIcon {
        id: lockIcon
        anchors.left: parent.left
        anchors.leftMargin: panel.horizontalPadding
        anchors.verticalCenter: parent.verticalCenter
        name: "lock"
        color: panel.failed ? panel.theme.colors.error : panel.theme.colors.foreground
        opacity: 1 - session.morphProgress
    }

    Rectangle {
        id: field
        anchors.left: lockIcon.right
        anchors.right: parent.right
        anchors.leftMargin: Design.compactItemSpacing
        anchors.rightMargin: panel.horizontalPadding
        anchors.verticalCenter: parent.verticalCenter
        height: Design.compactItemHeight
        radius: Design.radiusDefault
        color: panel.theme.colors.surfaceElevated
        opacity: 1 - session.morphProgress
        clip: true

        Item {
            id: dots
            readonly property real dotSize: 7
            readonly property real step: session.secretLength > 1 ? Math.min(15, (width - dotSize) / (session.secretLength - 1)) : 15
            anchors.left: parent.left
            anchors.leftMargin: Design.compactPillPadding
            anchors.right: parent.right
            anchors.rightMargin: Design.compactPillPadding
            anchors.verticalCenter: parent.verticalCenter
            height: dotSize
            visible: !session.echo

            Repeater {
                model: dotModel

                Rectangle {
                    id: dot
                    required property int uid
                    required property int slot
                    required property bool leaving
                    x: slot * dots.step
                    width: dots.dotSize
                    height: dots.dotSize
                    radius: width / 2
                    color: panel.theme.colors.foreground
                    opacity: 0
                    scale: .4

                    Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on x { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

                    Component.onCompleted: {
                        opacity = 1
                        scale = 1
                    }

                    onLeavingChanged: {
                        if (!leaving) return
                        opacity = 0
                        scale = .4
                    }

                    onOpacityChanged: {
                        if (leaving && opacity <= 0.01) Qt.callLater(() => panel.removeDot(dot.uid))
                    }
                }
            }
        }

        CompactBarLabel {
            anchors.left: parent.left
            anchors.leftMargin: Design.compactPillPadding
            anchors.right: parent.right
            anchors.rightMargin: Design.compactPillPadding
            anchors.verticalCenter: parent.verticalCenter
            visible: session.echo && session.secretLength > 0
            text: session.echo ? session.secret : ""
            elide: Text.ElideLeft
            color: panel.theme.colors.foreground
        }

        CompactBarLabel {
            anchors.left: parent.left
            anchors.leftMargin: Design.compactPillPadding
            anchors.right: parent.right
            anchors.rightMargin: Design.compactPillPadding
            anchors.verticalCenter: parent.verticalCenter
            visible: session.secretLength === 0
            text: panel.statusText
            elide: Text.ElideRight
            color: panel.failed ? panel.theme.colors.error : session.authenticating ? panel.theme.colors.accent : panel.theme.colors.mutedForeground
        }
    }
}
