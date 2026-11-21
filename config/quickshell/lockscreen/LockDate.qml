import QtQuick
import ".."

Text {
    id: date
    required property var controller
    required property var theme
    required property real glyphSize
    readonly property var weekdays: [
        I18n.tr("lockscreen.weekdays.sun"),
        I18n.tr("lockscreen.weekdays.mon"),
        I18n.tr("lockscreen.weekdays.tue"),
        I18n.tr("lockscreen.weekdays.wed"),
        I18n.tr("lockscreen.weekdays.thu"),
        I18n.tr("lockscreen.weekdays.fri"),
        I18n.tr("lockscreen.weekdays.sat")
    ]
    text: weekdays[controller.currentTime.getDay()] + " " + controller.formattedDate("dd/MM/yyyy")
    color: theme.colors.foreground
    font.family: Design.fontFamily
    font.pixelSize: Math.round(glyphSize * .17)
    font.weight: Design.fontWeightMedium
    renderType: Text.NativeRendering
}
