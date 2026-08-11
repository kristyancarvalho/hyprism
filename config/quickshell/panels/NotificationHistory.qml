import QtQuick
import QtQuick.Controls
import Quickshell.Services.Notifications

Column {
    id: history
    required property var controller
    required property var theme
    spacing: 6
    Row { width: parent.width
        Text { text: NotificationServer.trackedNotifications.count + " saved"; color: history.theme.colors.mutedForeground; font.pixelSize: 11; width: parent.width - clear.width }
        Button { id: clear; text: "Clear"; onClicked: { for (let i = NotificationServer.trackedNotifications.count - 1; i >= 0; i--) NotificationServer.trackedNotifications.get(i).dismiss() } }
    }
    Repeater { model: NotificationServer.trackedNotifications
        Rectangle { required property var modelData; width: history.width; height: 58; radius: 10; color: history.theme.colors.surfaceVariant
            Text { anchors { left: parent.left; right: dismiss.left; top: parent.top; margins: 8 } text: modelData.appName + " · " + modelData.summary; color: history.theme.colors.foreground; elide: Text.ElideRight; font.pixelSize: 11 }
            Text { anchors { left: parent.left; right: dismiss.left; bottom: parent.bottom; margins: 8 } text: modelData.body; color: history.theme.colors.mutedForeground; elide: Text.ElideRight; font.pixelSize: 10 }
            Button { id: dismiss; anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 4 } text: "×"; onClicked: modelData.dismiss() }
        }
    }
    Text { visible: NotificationServer.trackedNotifications.count === 0; text: "No notifications"; color: history.theme.colors.mutedForeground; font.pixelSize: 11 }
}
