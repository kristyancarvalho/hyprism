import QtQuick

Rectangle {
    id: button
    property var theme
    property string text: ""
    property string iconName: ""
    property bool active: false
    property bool destructive: false
    property bool compact: false
    signal clicked()
    implicitWidth: content.implicitWidth + (compact ? 18 : 26)
    implicitHeight: compact ? 30 : 38
    radius: height / 2
    color: destructive ? theme.colors.error : active ? theme.colors.accentDim : theme.colors.surfaceVariant
    border.width: 1
    border.color: destructive || active ? theme.colors.accent : theme.colors.outline

    Row {
        id: content
        anchors.centerIn: parent
        spacing: button.iconName ? 7 : 0
        ShellIcon { visible: button.iconName.length > 0; name: button.iconName; iconSize: button.compact ? 15 : 17 }
        Text { text: button.text; color: button.theme.colors.foreground; font { pixelSize: button.compact ? 11 : 12; weight: Font.Medium } }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
        onEntered: button.opacity = .82
        onExited: button.opacity = 1
    }
}
