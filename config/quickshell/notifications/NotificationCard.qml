import QtQuick
import "../components"
import ".."

Glass {
    id: card
    required property var notification
    required property var controller
    signal dismissed()
    width: 330
    height: Math.max(82, content.implicitHeight + 28)
    radius: Design.radiusMd
    surfaceOpacity: .96
    border.color: notification && notification.urgency === 2 ? theme.colors.error : theme.colors.outline
    visible: notification !== null

    function dismiss() {
        if (notification) notification.tracked = false
        dismissed()
    }

    Row {
        anchors.fill: parent
        anchors.margins: 13
        spacing: 11

        Rectangle {
            width: 40
            height: 40
            radius: 12
            color: card.theme.colors.surfaceElevated

            ShellIcon {
                anchors.centerIn: parent
                name: Design.safeText(card.notification ? card.notification.appIcon : "", Design.safeText(card.notification ? card.notification.desktopEntry : "", "application-x-executable"))
                fallback: "application-x-executable"
                iconSize: 25
            }
        }

        Column {
            id: content
            width: parent.width - 84
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Text {
                width: parent.width
                text: Design.safeText(card.notification ? card.notification.appName : "", "Notificação")
                color: card.theme.colors.mutedForeground
                elide: Text.ElideRight
                font.family: Design.fontFamily
                font.pixelSize: 9
                font.weight: Design.fontWeightMedium
            }

            Text {
                width: parent.width
                text: Design.safeText(card.notification ? card.notification.summary : "", "Notificação")
                color: card.theme.colors.foreground
                elide: Text.ElideRight
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeSm
                font.weight: Design.fontWeightSemibold
            }

            Text {
                width: parent.width
                visible: text.length > 0
                text: Design.safeText(card.notification ? card.notification.body : "", "").replace(/<[^>]*>/g, "")
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
                color: card.theme.colors.mutedForeground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeXs
            }

            Row {
                visible: card.notification && card.notification.actions.length > 0
                spacing: 4

                Repeater {
                    model: card.notification ? card.notification.actions : []

                    ShellButton {
                        required property var modelData
                        theme: card.theme
                        compact: true
                        text: Design.safeText(modelData.text, "Abrir")
                        onClicked: modelData.invoke()
                    }
                }
            }
        }

        ShellButton {
            anchors.top: parent.top
            theme: card.theme
            compact: true
            iconName: "close"
            onClicked: card.dismiss()
        }
    }
}
