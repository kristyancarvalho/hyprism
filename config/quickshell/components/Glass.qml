import QtQuick

Rectangle {
    id: glass
    property var theme
    property real surfaceOpacity: .88
    property color baseColor: theme ? theme.colors.surface : "#131b21"
    default property alias content: slot.data
    radius: 22
    color: Qt.rgba(baseColor.r, baseColor.g, baseColor.b, surfaceOpacity)
    border.width: 1
    border.color: theme ? theme.colors.outline : "#426172"
    clip: true
    Item { id: slot; anchors.fill: parent }
}
