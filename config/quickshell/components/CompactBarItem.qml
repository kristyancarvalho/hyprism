import QtQuick
import ".."

Rectangle {
    id: item
    property var theme
    property string iconName: ""
    property string trailingIconName: ""
    property string label: ""
    property bool active: false
    property bool selected: false
    property bool iconOnly: false
    property bool filled: true
    property bool clickable: false
    property int iconSize: Design.compactIconSize
    property int labelSize: Design.compactTextSize
    property int labelMaximumWidth: -1
    property int horizontalPadding: filled ? Design.compactPillPadding : Design.compactPlainPadding
    property int labelWeight: selected ? Design.fontWeightSemibold : Design.fontWeightMedium
    property color iconColor: selected ? theme.colors.background : theme.colors.foreground
    signal clicked()
    implicitWidth: content.implicitWidth + horizontalPadding * 2
    implicitHeight: Design.compactItemHeight
    radius: Design.radiusDefault
    color: !filled ? "transparent" : selected ? theme.colors.accent : active ? theme.colors.accentDim : theme.colors.surfaceElevated
    border.width: 0

    Row {
        id: content
        anchors.centerIn: parent
        height: Design.compactItemHeight
        spacing: item.iconOnly || !item.label || !item.iconName ? 0 : Design.compactItemSpacing

        CompactBarIcon {
            visible: item.iconName.length > 0
            name: item.iconName
            iconSize: item.iconSize
            color: item.iconColor
        }

        CompactBarLabel {
            visible: !item.iconOnly && item.label.length > 0
            width: item.labelMaximumWidth >= 0 ? Math.min(implicitWidth, item.labelMaximumWidth) : implicitWidth
            text: item.label
            color: item.selected ? item.theme.colors.background : item.theme.colors.foreground
            elide: Text.ElideRight
            font.weight: item.labelWeight
            font.pixelSize: item.labelSize
        }

        CompactBarIcon {
            visible: item.trailingIconName.length > 0
            name: item.trailingIconName
            iconSize: Design.iconXs
            color: item.theme.colors.accent
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: item.clickable
        cursorShape: Qt.PointingHandCursor
        onClicked: item.clicked()
    }
}
