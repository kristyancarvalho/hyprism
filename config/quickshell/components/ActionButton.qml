import QtQuick
import ".."

Rectangle {
    id: button
    property var theme
    property string label: ""
    property string iconName: "settings"
    property bool active: false
    signal clicked()
    activeFocusOnTab: true
    radius: Design.radiusSm
    color: active || activeFocus ? theme.colors.accentDim : pointer.containsMouse ? theme.colors.surfaceHover : theme.colors.surfaceVariant
    border.width: activeFocus ? 2 : Design.outlineWidth
    border.color: active || activeFocus ? theme.colors.accent : theme.colors.outline
    implicitWidth: 170
    implicitHeight: 68

    Row {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 36
            height: 36
            radius: 18
            color: button.active ? button.theme.colors.accentDim : button.theme.colors.surface

            StatusIcon {
                anchors.centerIn: parent
                name: button.iconName
                iconSize: Design.iconMd
                color: button.theme.colors.foreground
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Design.safeText(button.label, "Indisponível")
            color: button.theme.colors.foreground
            font.family: Design.fontFamily
            font.pixelSize: Design.fontSizeSm
            font.weight: Design.fontWeightMedium
            elide: Text.ElideRight
            width: parent.width - 58
            wrapMode: Text.WordWrap
            maximumLineCount: 2
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            button.clicked()
            event.accepted = true
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            button.forceActiveFocus()
            button.clicked()
        }
    }
}
