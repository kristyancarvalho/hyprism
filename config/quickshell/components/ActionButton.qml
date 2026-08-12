import QtQuick
import ".."

Rectangle {
    id: button
    property var theme
    property string label: ""
    property string iconName: "settings"
    property bool active: false
    property bool available: true
    property bool pending: false
    property bool hovered: pointer.containsMouse && available && !pending
    signal clicked()
    activeFocusOnTab: available
    radius: Design.radiusSm
    color: active && available ? theme.colors.accentDim : hovered ? theme.colors.surfaceHover : theme.colors.surfaceVariant
    border.width: activeFocus ? 2 : Design.outlineWidth
    border.color: active && available || activeFocus ? theme.colors.borderFocused : theme.colors.borderNormal
    opacity: available ? pending ? .72 : 1 : .5
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
            radius: height / 2
            color: button.active && button.available ? button.theme.colors.accentDim : button.theme.colors.surface

            StatusIcon {
                anchors.centerIn: parent
                name: button.pending ? "refresh" : button.iconName
                iconSize: Design.iconMd
                color: button.theme.colors.foreground
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Design.safeText(button.label, "Indisponível")
            color: button.available ? button.theme.colors.foreground : button.theme.colors.mutedForeground
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
