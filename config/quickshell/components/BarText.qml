import QtQuick
import ".."

Text {
    color: parent && parent.theme ? parent.theme.colors.foreground : "white"
    font.family: Design.fontFamily
    font.pixelSize: Design.barFontSize
    font.weight: Design.fontWeightMedium
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
}
