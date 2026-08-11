import QtQuick
import "../components"

Item {
    id: panel
    required property var controller
    required property var theme
    focus: true
    Keys.onPressed: event => { if (event.key === Qt.Key_Escape) { controller.close(); event.accepted = true } }

    ListView {
        anchors.fill: parent
        anchors.margins: 16
        orientation: ListView.Horizontal
        spacing: 10
        clip: true
        model: controller.switcherWindows
        currentIndex: controller.switcherIndex
        preferredHighlightBegin: width * .3
        preferredHighlightEnd: width * .7
        highlightRangeMode: ListView.ApplyRange

        delegate: Rectangle {
            required property var modelData
            required property int index
            width: 158
            height: ListView.view.height
            radius: 16
            color: controller.switcherIndex === index ? theme.colors.accentDim : theme.colors.surfaceVariant
            border.width: controller.switcherIndex === index ? 2 : 1
            border.color: controller.switcherIndex === index ? theme.colors.accent : theme.colors.outline

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 7
                ShellIcon { anchors.horizontalCenter: parent.horizontalCenter; name: modelData.appId || "application-x-executable"; fallback: "application-x-executable"; iconSize: 34; framed: true; frameColor: theme.colors.surface }
                Text { width: parent.width; text: modelData.appId || "Janela"; color: theme.colors.foreground; font { pixelSize: 12; bold: true } horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight }
                Text { width: parent.width; text: modelData.title; color: theme.colors.mutedForeground; font.pixelSize: 10; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight }
            }
        }
    }
}
