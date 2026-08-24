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
    spacing: Design.notificationSpacing
    activeFocusOnTab: true
    onNotificationsChanged: selectedIndex = navigation.clamp(selectedIndex, notifications.length)

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
            navigation.useKeyboard()
            selectedIndex = navigation.wrap(selectedIndex, -1, notifications.length)
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            navigation.useKeyboard()
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

    ListView {
        id: historyList
        width: parent.width
        height: {
            const visibleCount = Math.min(3, count)
            return visibleCount * Design.notificationHistoryRowHeight + Math.max(0, visibleCount - 1) * spacing
        }
        spacing: Design.notificationSpacing
        clip: true
        model: history.notifications
        currentIndex: history.selectedIndex
        onCurrentIndexChanged: if (currentIndex >= 0) positionViewAtIndex(currentIndex, ListView.Contain)

        SelectionHighlight {
            parent: historyList.contentItem
            theme: history.theme
            target: historyList.currentItem
            active: navigation.keyboardNavigation && history.activeFocus && history.notifications.length > 0
        }

        delegate: Rectangle {
            required property var modelData
            required property int index
            width: ListView.view.width
            height: Design.notificationHistoryRowHeight
            radius: Design.radiusSm
            color: navigation.keyboardNavigation && history.activeFocus ? "transparent" : pointer.containsMouse ? history.theme.colors.surfaceHover : history.theme.colors.surfaceVariant
            border.width: 0

            Behavior on color { ColorAnimation { duration: Design.animationFast; easing.type: Design.easingMorph } }

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
                onEntered: {
                    navigation.usePointer()
                    history.selectedIndex = index
                }
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
