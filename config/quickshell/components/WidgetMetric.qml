import QtQuick
import ".."

Row {
    id: metric
    property var theme
    property string iconName: "settings"
    property string trailingIconName: ""
    property string value: ""
    spacing: 5
    height: Design.widgetHeaderHeight

    StatusIcon {
        width: Design.widgetHeaderHeight
        height: Design.widgetHeaderHeight
        name: metric.iconName
        iconSize: Design.iconXs
        color: metric.theme.colors.mutedForeground
    }

    Text {
        height: Design.widgetHeaderHeight
        text: Design.safeText(metric.value, "")
        color: metric.theme.colors.mutedForeground
        font.family: Design.fontFamily
        font.pixelSize: 9
        verticalAlignment: Text.AlignVCenter
    }

    StatusIcon {
        visible: metric.trailingIconName.length > 0
        width: visible ? Design.iconXs : 0
        height: Design.widgetHeaderHeight
        name: metric.trailingIconName
        iconSize: 9
        color: metric.theme.colors.accent
    }
}
