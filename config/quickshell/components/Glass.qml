import QtQuick

Rectangle {
    id: glass
    property var theme
    property real surfaceOpacity: .88
    default property alias content: slot.data
    radius: 22
    color: theme ? theme.colors.surface : "#131b21"
    opacity: surfaceOpacity
    border.width: 1
    border.color: theme ? theme.colors.outline : "#426172"
    clip: true
    Item { id: slot; anchors.fill: parent }
}
