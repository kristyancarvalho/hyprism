import QtQuick
import ".."

Row {
    id: metric
    property var theme
    property string iconName: "networkSpeed"
    property string label: ""
    property string value: ""
    property var samples: []
    property real maximum: 100
    property color lineColor: theme ? theme.colors.accent : "white"
    spacing: Design.spacingSm
    height: 32

    StatusIcon {
        width: Design.iconSm
        height: parent.height
        name: metric.iconName
        color: metric.lineColor
        iconSize: Design.iconSm
    }

    Column {
        width: 92
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Text {
            width: parent.width
            text: metric.label
            color: metric.theme.colors.mutedForeground
            font.family: Design.fontFamily
            font.pixelSize: 9
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: metric.value
            color: metric.theme.colors.foreground
            font.family: Design.fontFamily
            font.pixelSize: Design.fontSizeXs
            font.weight: Design.fontWeightSemibold
            elide: Text.ElideRight
        }
    }

    Sparkline {
        width: parent.width - 117
        height: 28
        anchors.verticalCenter: parent.verticalCenter
        samples: metric.samples
        maximum: metric.maximum
        lineColor: metric.lineColor
    }
}
