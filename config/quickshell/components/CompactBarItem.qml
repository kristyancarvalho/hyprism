import QtQuick
import ".."

Rectangle {
    id: item
    property var theme
    property string iconName: ""
    property string label: ""
    property bool active: false
    property bool selected: false
    property bool iconOnly: false
    property bool filled: true
    property int labelMaximumWidth: 0
    signal clicked()
    implicitWidth: content.implicitWidth + Design.compactHorizontalPadding * 2
    implicitHeight: Design.compactItemHeight
    radius: height / 2
    color: !filled ? "transparent" : selected ? theme.colors.accent : active ? theme.colors.accentDim : theme.colors.surfaceElevated
    border.width: filled ? Design.outlineWidth : 0
    border.color: selected || active ? theme.colors.accent : theme.colors.outline

    Row {
        id: content
        anchors.centerIn: parent
        height: Design.compactItemHeight
        spacing: item.iconOnly || !item.label || !item.iconName ? 0 : Design.compactItemSpacing

        CompactBarIcon {
            visible: item.iconName.length > 0
            name: item.iconName
            color: item.selected ? item.theme.colors.background : item.theme.colors.foreground
        }

        CompactBarLabel {
            visible: !item.iconOnly && item.label.length > 0
            width: item.labelMaximumWidth > 0 ? Math.min(implicitWidth, item.labelMaximumWidth) : implicitWidth
            text: item.label
            color: item.selected ? item.theme.colors.background : item.theme.colors.foreground
            elide: Text.ElideRight
            font.weight: item.selected ? Design.fontWeightSemibold : Design.fontWeightMedium
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: item.clicked()
    }
}
