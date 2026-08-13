import QtQuick
import "../components"
import ".."

Column {
    id: history
    required property var controller
    required property var theme
    required property var server
    property var notifications: server && Array.isArray(server.historyNotifications) ? server.historyNotifications : []
    property int selectedIndex: 0
    spacing: 8
    activeFocusOnTab: true

    function dismiss(notification) {
        if (!notification) return
        server.removeHistory(notification)
    }

    function clearAll() {
        server.clearHistory()
        selectedIndex = 0
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Up) {
            selectedIndex = navigation.wrap(selectedIndex, -1, notifications.length)
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            selectedIndex = navigation.wrap(selectedIndex, 1, notifications.length)
            event.accepted = true
        } else if (event.key === Qt.Key_Delete || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            dismiss(notifications[selectedIndex])
            event.accepted = true
        }
    }

    Navigation { id: navigation }

    Row {
        width: parent.width
        visible: history.notifications.length > 0
        spacing: Design.spacingSm

        Text {
            width: parent.width - clear.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            text: Design.notificationCount(history.notifications.length)
            color: history.theme.colors.mutedForeground
            font.family: Design.fontFamily
            font.pixelSize: Design.fontSizeXs
        }

        ShellButton {
            id: clear
            visible: history.notifications.length > 0
            theme: history.theme
            compact: true
            text: "Limpar tudo"
            iconName: "clear"
            onClicked: history.clearAll()
        }
    }

    Repeater {
        model: history.notifications

        Rectangle {
            required property var modelData
            required property int index
            width: history.width
            height: 76
            radius: Design.radiusSm
            color: history.activeFocus && history.selectedIndex === index ? history.theme.colors.surfaceActive : pointer.containsMouse ? history.theme.colors.surfaceHover : history.theme.colors.surfaceVariant
            border.width: history.activeFocus && history.selectedIndex === index ? 2 : 0
            border.color: history.theme.colors.accent

            Rectangle {
                anchors {
                    left: parent.left
                    leftMargin: 9
                    verticalCenter: parent.verticalCenter
                }
                width: 38
                height: 38
                radius: Design.radiusSm
                color: history.theme.colors.surface

                ShellIcon {
                    anchors.centerIn: parent
                    name: Design.safeText(modelData.appIcon, Design.safeText(modelData.desktopEntry, "application-x-executable"))
                    fallback: "application-x-executable"
                    fallbackGlyph: "notification"
                    iconSize: 24
                }
            }

            Column {
                anchors {
                    left: parent.left
                    leftMargin: 56
                    right: dismissButton.left
                    rightMargin: 8
                    verticalCenter: parent.verticalCenter
                }
                spacing: 2

                Text {
                    width: parent.width
                    text: Design.safeText(modelData.appName, "Notificação")
                    color: history.theme.colors.mutedForeground
                    elide: Text.ElideRight
                    font.family: Design.fontFamily
                    font.pixelSize: 9
                    font.weight: Design.fontWeightMedium
                }

                Text {
                    width: parent.width
                    text: Design.safeText(modelData.summary, Design.safeText(modelData.appName, "Notificação"))
                    color: history.theme.colors.foreground
                    elide: Text.ElideRight
                    font.family: Design.fontFamily
                    font.pixelSize: Design.fontSizeSm
                    font.weight: Design.fontWeightSemibold
                }

                Text {
                    width: parent.width
                    text: Design.safeText(modelData.body, "Sem detalhes").replace(/<[^>]*>/g, "")
                    color: history.theme.colors.mutedForeground
                    elide: Text.ElideRight
                    font.family: Design.fontFamily
                    font.pixelSize: Design.fontSizeXs
                }
            }

            ShellButton {
                id: dismissButton
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    rightMargin: 8
                }
                theme: history.theme
                compact: true
                iconName: "close"
                onClicked: history.dismiss(modelData)
            }

            MouseArea {
                id: pointer
                anchors {
                    left: parent.left
                    right: dismissButton.left
                    top: parent.top
                    bottom: parent.bottom
                }
                hoverEnabled: true
                onEntered: history.selectedIndex = index
                onClicked: history.forceActiveFocus()
            }
        }
    }

    Column {
        visible: history.notifications.length === 0
        width: parent.width
        spacing: 4

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Nenhuma notificação salva"
            color: history.theme.colors.mutedForeground
            font.family: Design.fontFamily
            font.pixelSize: Design.fontSizeSm
        }
    }
}
