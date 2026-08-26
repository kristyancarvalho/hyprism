import QtQuick
import ".."

Glass {
    id: card
    property string iconName: "settings"
    property string title: I18n.tr("widgets.system")
    property string value: ""
    property int contentHeight: 60
    property color iconColor: theme ? theme.colors.accent : "white"
    default property alias cardContent: content.data
    surfaceOpacity: .86
    radius: Design.radiusMd
    implicitHeight: Design.widgetInnerPadding * 2 + Design.widgetHeaderHeight + Design.spacingSm + contentHeight

    WidgetHeader {
        id: header
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Design.widgetInnerPadding
        }
        theme: card.theme
        iconName: card.iconName
        title: card.title
        value: card.value
        iconColor: card.iconColor
    }

    Item {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            top: header.bottom
            topMargin: Design.spacingSm
            leftMargin: Design.widgetInnerPadding
            rightMargin: Design.widgetInnerPadding
        }
        height: card.contentHeight
    }
}
