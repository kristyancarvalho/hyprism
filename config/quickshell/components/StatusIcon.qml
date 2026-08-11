import QtQuick
import ".."

Text {
    id: icon
    property string name: "application"
    property int iconSize: Design.iconSm
    text: Design.icon(name)
    color: parent && parent.theme ? parent.theme.colors.foreground : "white"
    font.family: Design.fontFamilyIcons
    font.pixelSize: iconSize
    font.weight: Font.Normal
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
    width: iconSize + 2
    height: iconSize + 2
}
