import QtQuick
import ".."

Item {
    id: header
    property var theme
    property string iconName: "settings"
    property string title: ""
    property string value: ""
    property color iconColor: theme ? theme.colors.accent : "white"
    implicitHeight: Design.widgetHeaderHeight

    Row {
        anchors.fill: parent
        spacing: 6

        StatusIcon {
            width: Design.widgetHeaderHeight
            height: Design.widgetHeaderHeight
            name: header.iconName
            iconSize: Design.widgetIconSize
            color: header.iconColor
        }

        Text {
            width: parent.width - valueLabel.width - Design.widgetHeaderHeight - 12
            height: Design.widgetHeaderHeight
            text: Design.safeText(header.title, "Sistema")
            color: header.theme.colors.foreground
            font.family: Design.fontFamily
            font.pixelSize: Design.fontSizeXs
            font.weight: Design.fontWeightMedium
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        Text {
            id: valueLabel
            height: Design.widgetHeaderHeight
            text: Design.safeText(header.value, "")
            color: header.theme.colors.foreground
            font.family: Design.fontFamily
            font.pixelSize: Design.fontSizeXs
            font.weight: Design.fontWeightSemibold
            verticalAlignment: Text.AlignVCenter
        }
    }
}
