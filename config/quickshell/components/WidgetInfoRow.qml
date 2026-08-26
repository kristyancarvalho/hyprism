import QtQuick
import ".."

Item {
    id: row
    property var theme
    property string label: ""
    property string value: ""
    property int labelWidth: 108
    property int fontSize: Design.fontSizeXs
    property color labelColor: theme ? theme.colors.mutedForeground : "white"
    property color valueColor: theme ? theme.colors.foreground : "white"
    implicitHeight: Design.widgetDataRowHeight

    Text {
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        width: Math.min(row.labelWidth, parent.width)
        text: Design.safeText(row.label, I18n.tr("common.information"))
        color: row.labelColor
        font.family: Design.fontFamily
        font.pixelSize: row.fontSize
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    Text {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            leftMargin: Math.min(row.labelWidth + Design.spacingSm, parent.width)
        }
        text: Design.safeText(row.value, I18n.tr("common.unavailable"))
        color: row.valueColor
        font.family: Design.fontFamily
        font.pixelSize: row.fontSize
        font.weight: Design.fontWeightSemibold
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
