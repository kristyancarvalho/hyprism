import QtQuick
import ".."

Text {
    implicitHeight: Design.compactItemHeight
    color: "white"
    font.family: Design.fontFamily
    font.pixelSize: Design.compactTextSize
    font.weight: Design.fontWeightMedium
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
}
