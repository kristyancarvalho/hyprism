import QtQuick

Rectangle {
    id: chip
    property var theme
    property string iconName: ""
    property string label: ""
    property bool highlighted: false
    implicitWidth: content.implicitWidth + 18
    implicitHeight: 32
    radius: height / 2
    color: highlighted ? theme.colors.accentDim : theme.colors.surfaceVariant
    border.width: 1
    border.color: highlighted ? theme.colors.accent : theme.colors.outline

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 7
        ShellIcon { name: chip.iconName; iconSize: 16 }
        Text { text: chip.label; color: chip.theme.colors.foreground; font { pixelSize: 11; weight: Font.Medium } }
    }
}
