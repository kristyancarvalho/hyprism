import QtQuick
import ".."

Rectangle {
    id: button
    property var theme
    property string text: ""
    property string iconName: ""
    property bool active: false
    property bool destructive: false
    property bool compact: false
    property bool available: true
    property bool pending: false
    property bool hovered: pointer.containsMouse && available && !pending
    signal clicked()
    activeFocusOnTab: available
    implicitWidth: content.implicitWidth + (compact ? 18 : 26)
    implicitHeight: compact ? 30 : 38
    radius: Design.radiusDefault
    color: destructive && available ? theme.colors.error : active && available ? theme.colors.accentDim : hovered ? theme.colors.surfaceHover : theme.colors.surfaceVariant
    border.width: activeFocus ? 2 : Design.outlineWidth
    border.color: activeFocus || active ? theme.colors.borderFocused : theme.colors.borderNormal
    opacity: available ? pending ? .72 : 1 : .5

    Row {
        id: content
        anchors.centerIn: parent
        spacing: button.iconName ? 7 : 0

        StatusIcon {
            visible: button.iconName.length > 0
            anchors.verticalCenter: parent.verticalCenter
            name: button.pending ? "refresh" : button.iconName
            iconSize: button.compact ? Design.iconXs : Design.iconSm
            color: button.theme.colors.foreground
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: button.text
            color: button.theme.colors.foreground
            font.family: Design.fontFamily
            font.pixelSize: button.compact ? Design.fontSizeXs : Design.fontSizeSm
            font.weight: Design.fontWeightMedium
        }
    }

    Keys.onPressed: event => {
        if (button.available && !button.pending && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)) {
            button.clicked()
            event.accepted = true
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: button.available && !button.pending
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            button.forceActiveFocus()
            button.clicked()
        }
    }
}
