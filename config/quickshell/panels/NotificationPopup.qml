import QtQuick
import Quickshell
import Quickshell.Wayland
import "../notifications"
import ".."

PanelWindow {
    id: popup
    required property var shellScreen
    required property var notifications
    required property var controller
    required property var theme
    property int overflowCount: 0
    property bool suppressed: false
    property bool removalPending: false
    readonly property int fadeDuration: Math.max(1, Math.round(Design.safeNumber(controller.config.shell.animationFast, Design.animationFast)))
    readonly property int motionDuration: Math.max(fadeDuration, Math.round(Design.safeNumber(controller.config.shell.animationNormal, Design.animationMorph)))
    signal dismissRequested(var notification)
    signal notificationClosed(var notification)

    screen: shellScreen
    visible: shellScreen !== null && !suppressed && (notifications.count > 0 || removalPending)
    anchors.top: true
    margins.top: Design.compactReservedHeight(controller.config.shell) + 6
    implicitWidth: 360
    implicitHeight: Math.min(stack.contentHeight + (overflow.visible ? overflow.height + Design.spacingSm : 0), Math.max(120, shellScreen ? shellScreen.height - margins.top - 16 : 600))
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Timer {
        id: removalTimer
        interval: popup.motionDuration
        onTriggered: popup.removalPending = false
    }

    ListView {
        id: stack
        width: parent.width
        height: parent.height - (overflow.visible ? overflow.height + Design.spacingSm : 0)
        spacing: Design.notificationSpacing
        clip: true
        interactive: false
        cacheBuffer: 1000
        model: popup.notifications

        delegate: Item {
            id: popupDelegate
            required property var payload
            width: stack.width
            height: card.height
            opacity: 0
            property real entranceOffset: -16
            property real exitOffset: 0
            property bool positionAnimationReady: false

            transform: Translate { x: popupDelegate.exitOffset; y: popupDelegate.entranceOffset }

            Behavior on y {
                enabled: popupDelegate.positionAnimationReady
                NumberAnimation { duration: popup.motionDuration; easing.type: Design.easingMove }
            }

            Component.onCompleted: entrance.start()
            ListView.onRemove: entrance.stop()

            ParallelAnimation {
                id: entrance
                onFinished: popupDelegate.positionAnimationReady = true

                NumberAnimation {
                    target: popupDelegate
                    property: "opacity"
                    to: 1
                    duration: popup.fadeDuration
                    easing.type: Design.easingEnter
                }

                NumberAnimation {
                    target: popupDelegate
                    property: "entranceOffset"
                    to: 0
                    duration: popup.motionDuration
                    easing.type: Design.easingEnter
                }
            }

            NotificationCard {
                id: card
                notification: popupDelegate.payload
                width: parent.width
                controller: popup.controller
                theme: popup.theme
                onDismissed: popup.dismissRequested(notification)
            }

            Connections {
                target: popupDelegate.payload
                function onClosed() { popup.notificationClosed(popupDelegate.payload) }
            }
        }

        remove: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; to: 0; duration: popup.fadeDuration; easing.type: Design.easingExit }
                NumberAnimation { property: "exitOffset"; to: 16; duration: popup.motionDuration; easing.type: Design.easingExit }
            }
        }
    }

    Rectangle {
        id: overflow
        visible: popup.overflowCount > 0
        anchors {
            top: stack.bottom
            topMargin: Design.spacingSm
            horizontalCenter: parent.horizontalCenter
        }
        implicitWidth: overflowText.implicitWidth + 20
        width: implicitWidth
        height: 26
        radius: Design.radiusSm
        color: popup.theme.colors.surfaceElevated

        Text {
            id: overflowText
            anchors.centerIn: parent
            text: I18n.tr("notifications.inHistory", { count: popup.overflowCount })
            color: popup.theme.colors.mutedForeground
            font.family: Design.fontFamily
            font.pixelSize: Design.fontSizeXs
            font.weight: Design.fontWeightMedium
        }
    }

    Connections {
        target: popup.notifications
        function onCountChanged() {
            if (popup.notifications.count === 0) {
                popup.removalPending = true
                removalTimer.restart()
            } else {
                popup.removalPending = false
                removalTimer.stop()
            }
        }
    }
}
