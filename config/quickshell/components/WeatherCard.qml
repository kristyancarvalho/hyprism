import QtQuick
import ".."

Glass {
    id: card
    required property var controller
    surfaceOpacity: Design.themedSurfaceOpacity(.84)
    radius: Design.radiusMd

    Row {
        anchors.fill: parent
        anchors.margins: Design.widgetInnerPadding
        spacing: Design.spacingSm

        StatusIcon {
            anchors.verticalCenter: parent.verticalCenter
            name: card.controller.weatherIconName(card.controller.weather.weatherCode)
            iconSize: Design.iconLg
            color: card.theme.colors.accent
        }

        Column {
            width: parent.width - Design.iconLg - Design.spacingMd
            anchors.verticalCenter: parent.verticalCenter

            Text {
                width: parent.width
                text: card.controller.weather.temperature === null ? "--°" : Math.round(Design.safeNumber(card.controller.weather.temperature, 0)) + "°C"
                color: card.theme.colors.foreground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeLg
                font.weight: Design.fontWeightSemibold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: card.controller.weatherCondition(Design.safeNumber(card.controller.weather.weatherCode, -1))
                color: card.theme.colors.foreground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeXs
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: Design.safeText(card.controller.weather.city, I18n.tr("weather.local"))
                color: card.theme.colors.mutedForeground
                font.family: Design.fontFamily
                font.pixelSize: 9
                elide: Text.ElideRight
            }
        }
    }
}
