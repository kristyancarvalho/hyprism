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

    anchors.top: parent.top
    anchors.topMargin: Design.compactTopMargin(shellConfig)
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.horizontalCenterOffset: shake
    width: restWidth + (barWidth - restWidth) * session.morphProgress
    height: Design.compactHeight(shellConfig)
    radius: Design.radiusIslandCompact
    surfaceOpacity: shellConfig.surfaceOpacity
    opacity: revealed ? 1 : 0
    visible: opacity > 0

    Behavior on opacity { NumberAnimation { duration: Design.animationMorph; easing.type: Design.easingMorph } }

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

        Row {
            anchors.left: parent.left
            anchors.leftMargin: Design.compactPillPadding
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5
            visible: !session.echo && session.secretLength > 0
            Repeater {
                model: Math.min(session.secretLength, 24)
                Rectangle {
                    width: 7
                    height: 7
                    radius: 3.5
                    color: panel.theme.colors.foreground
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
