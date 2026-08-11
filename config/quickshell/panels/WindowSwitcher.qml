import QtQuick

Item {
    id: panel
    required property var controller
    required property var theme
    focus: true
    Keys.onPressed: event => { if (event.key === Qt.Key_Escape) { controller.close(); event.accepted = true } }
    Row {
        anchors.centerIn: parent; spacing: 10
        Repeater { model: controller.switcherWindows
            Rectangle { required property var modelData; required property int index; width: 146; height: 104; radius: 16
                color: controller.switcherIndex === index ? theme.colors.accentDim : theme.colors.surfaceVariant
                border.width: controller.switcherIndex === index ? 2 : 1; border.color: controller.switcherIndex === index ? theme.colors.accent : theme.colors.outline
                Column { anchors.fill: parent; anchors.margins: 12; spacing: 7
                    Text { text: "◈"; color: theme.colors.accent; font.pixelSize: 21 }
                    Text { width: parent.width; text: modelData.appId || "Janela"; color: theme.colors.foreground; font { pixelSize: 12; bold: true } elide: Text.ElideRight }
                    Text { width: parent.width; text: modelData.title; color: theme.colors.mutedForeground; font.pixelSize: 10; elide: Text.ElideRight }
                }
            }
        }
    }
}
