import QtQuick
import QtQuick.Effects
import ".."

RectangularShadow {
    property var theme

    color: Design.surfaceShadowColor(theme)
    blur: Design.surfaceShadowBlur
    spread: 0
    offset: Qt.vector2d(0, Design.surfaceShadowOffsetY)
}
