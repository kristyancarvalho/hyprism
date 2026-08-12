import QtQuick
import ".."

Item {
    id: root
    property string name: "application"
    property color color: "white"
    property int iconSize: Design.compactIconSize
    implicitWidth: iconSize + 2
    implicitHeight: Design.compactItemHeight

    Text {
        anchors.fill: parent
        text: Design.icon(root.name)
        color: root.color
        font.family: Design.fontFamilyIcons
        font.pixelSize: root.iconSize
        font.weight: Font.Normal
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        renderType: Text.NativeRendering
    }
}
