import QtQuick
import ".."

Rectangle {
    id: pill
    property var theme
    property string iconName: "application"
    property string label: ""
    property bool active: false
    property bool selected: false
    property bool iconOnly: false
    signal clicked()
    implicitWidth: content.implicitWidth + Design.barPillPadding * 2
    implicitHeight: Design.barPillHeight
    radius: height / 2
    color: selected ? theme.colors.accent : active ? theme.colors.accentDim : theme.colors.surfaceElevated
    border.width: Design.outlineWidth
    border.color: selected || active ? theme.colors.accent : theme.colors.outline

    Row {
        id: content
        anchors.centerIn: parent
        spacing: pill.iconOnly || !pill.label ? 0 : 7

        StatusIcon {
            anchors.verticalCenter: parent.verticalCenter
            name: pill.iconName
            iconSize: Design.barIconSize
            color: pill.selected ? pill.theme.colors.background : pill.theme.colors.foreground
        }

        BarText {
            visible: !pill.iconOnly && pill.label.length > 0
            anchors.verticalCenter: parent.verticalCenter
            text: pill.label
            color: pill.selected ? pill.theme.colors.background : pill.theme.colors.foreground
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: pill.clicked()
    }
}
