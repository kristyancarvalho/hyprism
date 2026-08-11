import QtQuick

Rectangle {
    id: button
    property var theme
    property string label: ""
    property string icon: ""
    property bool active: false
    signal clicked()
    radius: 14
    color: active ? theme.colors.accentDim : theme.colors.surfaceVariant
    border.width: 1
    border.color: active ? theme.colors.accent : theme.colors.outline
    implicitWidth: 140
    implicitHeight: 64
    Behavior on color { ColorAnimation { duration: 130 } }
    Column {
        anchors.centerIn: parent; spacing: 3
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: button.icon; color: button.active ? button.theme.colors.accent : button.theme.colors.foreground; font.pixelSize: 18 }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: button.label; color: button.theme.colors.foreground; font.pixelSize: 11; elide: Text.ElideRight; width: button.width - 14; horizontalAlignment: Text.AlignHCenter }
    }
    MouseArea { anchors.fill: parent; hoverEnabled: true; onClicked: button.clicked(); onEntered: button.opacity = .88; onExited: button.opacity = 1 }
}
