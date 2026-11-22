import QtQuick
import ".."

Glass {
    id: card
    required property var controller
    surfaceOpacity: Design.themedSurfaceOpacity(.84)
    radius: Design.radiusMd

    Column {
        anchors.centerIn: parent
        spacing: 2

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: card.controller.formattedDate("HH:mm")
            color: card.theme.colors.foreground
            font.family: Design.fontFamily
            font.pixelSize: Design.fontSizeXl
            font.weight: Design.fontWeightSemibold
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: card.controller.formattedDate(I18n.locale === "pt-BR" ? "dddd · dd MMMM" : "dddd · MMMM dd")
            color: card.theme.colors.mutedForeground
            font.family: Design.fontFamily
            font.pixelSize: 9
            font.weight: Design.fontWeightMedium
        }
    }
}
