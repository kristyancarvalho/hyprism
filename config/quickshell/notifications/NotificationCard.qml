import QtQuick
import QtQuick.Controls
import "../components"

Glass {
    id: card
    required property var notification
    required property var controller
    width: 330; height: Math.max(76, body.implicitHeight + 28); radius: 16; surfaceOpacity: .96
    border.color: notification && notification.urgency === 2 ? theme.colors.error : theme.colors.outline
    visible: notification !== null
    Column { id: body; anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 13 } spacing: 3
        Row { width: parent.width
            ShellIcon { name: notification && notification.appIcon ? notification.appIcon : "dialog-information"; fallback: "dialog-information"; iconSize: 20 }
            Text { anchors.verticalCenter: parent.verticalCenter; text: notification ? (notification.appName + " · " + notification.summary) : ""; width: parent.width - 54; color: theme.colors.foreground; elide: Text.ElideRight; font { pixelSize: 11; bold: true } }
            ShellButton { theme: card.theme; compact: true; iconName: "window-close"; onClicked: notification.dismiss() }
        }
        Text { width: parent.width; text: notification ? notification.body.replace(/<[^>]*>/g, "") : ""; wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight; color: theme.colors.mutedForeground; font.pixelSize: 11 }
        Row { visible: notification && notification.actions.length > 0; spacing: 4
            Repeater { model: notification ? notification.actions : []
                ShellButton { required property var modelData; theme: card.theme; compact: true; text: modelData.text; onClicked: modelData.invoke() }
            }
        }
    }
}
