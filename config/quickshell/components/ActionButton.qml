import QtQuick

Rectangle {
    id: button
    property var theme
    property string label: ""
    property string iconName: "preferences-system"
    property bool active: false
    signal clicked()
    radius: 14
    color: active ? theme.colors.accentDim : theme.colors.surfaceVariant
    border.width: 1
    border.color: active ? theme.colors.accent : theme.colors.outline
    implicitWidth: 170
    implicitHeight: 72
    Behavior on color { ColorAnimation { duration: 130 } }
    Row {
        anchors.fill: parent; anchors.margins: 12; spacing: 10
        ShellIcon { anchors.verticalCenter: parent.verticalCenter; name: button.iconName; iconSize: 24; framed: true; frameColor: button.active ? button.theme.colors.accentDim : button.theme.colors.surface }
        Text { anchors.verticalCenter: parent.verticalCenter; text: button.label; color: button.theme.colors.foreground; font { pixelSize: 12; weight: Font.Medium } elide: Text.ElideRight; width: parent.width - 58; wrapMode: Text.WordWrap; maximumLineCount: 2 }
    }
    MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: button.clicked(); onEntered: button.opacity = .84; onExited: button.opacity = 1 }
}
