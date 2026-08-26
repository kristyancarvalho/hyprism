import QtQuick
import "../components"
import ".."

Glass {
    id: card
    required property var notification
    required property var controller
    signal dismissed()
    width: 360
    height: Math.min(136, Math.max(Design.notificationCardMinimumHeight, content.implicitHeight + Design.notificationPaddingY * 2))
    radius: Design.radiusMd
    surfaceOpacity: .96
    outlined: notification && notification.urgency === 2
    outlineColor: theme.colors.error
    visible: notification !== null

    function dismiss() {
        dismissed()
    }

    function actionModel() {
        const actions = notification && notification.actions ? notification.actions : []
        const visibleActions = []
        for (let index = 0; index < Math.min(2, actions.length); index++) visibleActions.push(actions[index])
        return visibleActions
    }

    Column {
        id: content
        anchors.left: parent.left
        anchors.leftMargin: 13
        anchors.right: closeButton.left
        anchors.rightMargin: Design.spacingSm
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        Item {
            width: parent.width
            height: Math.max(40, headingText.implicitHeight)

            Rectangle {
                id: appIconFrame
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 40
                height: 40
                radius: Design.radiusSm
                color: card.theme.colors.surfaceElevated

                ShellIcon {
                    anchors.centerIn: parent
                    name: Design.safeText(card.notification ? card.notification.appIcon : "", Design.safeText(card.notification ? card.notification.desktopEntry : "", "application-x-executable"))
                    fallback: "application-x-executable"
                    fallbackGlyph: "notification"
                    iconSize: 24
                }
            }

            Column {
                id: headingText
                anchors.left: appIconFrame.right
                anchors.leftMargin: Design.spacingMd
                anchors.right: parent.right
                anchors.verticalCenter: appIconFrame.verticalCenter
                spacing: 3

                Text {
                    width: parent.width
                    text: Design.safeText(card.notification ? card.notification.appName : "", I18n.tr("notifications.notification"))
                    color: card.theme.colors.mutedForeground
                    elide: Text.ElideRight
                    font.family: Design.fontFamily
                    font.pixelSize: 9
                    font.weight: Design.fontWeightMedium
                }

                Text {
                    width: parent.width
                    text: Design.safeText(card.notification ? card.notification.summary : "", I18n.tr("notifications.notification"))
                    color: card.theme.colors.foreground
                    elide: Text.ElideRight
                    font.family: Design.fontFamily
                    font.pixelSize: Design.fontSizeSm
                    font.weight: Design.fontWeightSemibold
                }
            }
        }

        Text {
            x: 52
            width: parent.width - x
            visible: text.length > 0
            text: Design.safeText(card.notification ? card.notification.body : "", "").replace(/<[^>]*>/g, "")
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            color: card.theme.colors.mutedForeground
            font.family: Design.fontFamily
            font.pixelSize: Design.fontSizeXs
        }

        Row {
            x: 52
            visible: card.notification && card.notification.actions && card.notification.actions.length > 0
            spacing: 4

            Repeater {
                model: card.actionModel()

                ShellButton {
                    required property var modelData
                    theme: card.theme
                    compact: true
                    text: Design.safeText(modelData.text, I18n.tr("common.open"))
                    onClicked: modelData.invoke()
                }
            }
        }
    }

    Item {
        id: closeButton
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: Design.spacingSm
        anchors.topMargin: Design.spacingSm
        width: 32
        height: 32

        Rectangle {
            anchors.centerIn: parent
            width: 21
            height: 21
            radius: Design.radiusDefault
            color: closePointer.containsMouse || closeButton.activeFocus ? card.theme.colors.surfaceHover : card.theme.colors.surfaceVariant
            border.width: 0

            Behavior on color { ColorAnimation { duration: Design.animationFast; easing.type: Design.easingMorph } }

            StatusIcon {
                anchors.centerIn: parent
                name: "close"
                iconSize: 12
                color: card.theme.colors.foreground
            }
        }

        activeFocusOnTab: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                card.dismiss()
                event.accepted = true
            }
        }

        MouseArea {
            id: closePointer
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: card.dismiss()
        }
    }
}
