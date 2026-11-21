import QtQuick
import ".."

Column {
    id: clock
    required property var controller
    required property var theme
    required property real screenHeight
    readonly property real glyphSize: Design.clamp(screenHeight * .125, 64, 170)
    visible: controller.widgetEnabled("clock")
    spacing: -glyphSize * .08

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: clock.controller.formattedDate("HH")
        color: clock.theme.colors.foreground
        font.family: Design.fontFamily
        font.pixelSize: clock.glyphSize
        font.weight: Design.fontWeightSemibold
        renderType: Text.NativeRendering
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: clock.controller.formattedDate("mm")
        color: clock.theme.colors.accent
        font.family: Design.fontFamily
        font.pixelSize: clock.glyphSize
        font.weight: Design.fontWeightSemibold
        renderType: Text.NativeRendering
    }
}
