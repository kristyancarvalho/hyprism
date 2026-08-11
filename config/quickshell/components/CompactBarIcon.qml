import QtQuick
import ".."

Item {
    id: root
    property string name: "application"
    property color color: "white"
    implicitWidth: Design.compactIconSize + 2
    implicitHeight: Design.compactItemHeight

    Text {
        anchors.fill: parent
        text: Design.icon(root.name)
        color: root.color
        font.family: Design.fontFamilyIcons
        font.pixelSize: Design.compactIconSize
        font.weight: Font.Normal
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        renderType: Text.NativeRendering
    }
}
