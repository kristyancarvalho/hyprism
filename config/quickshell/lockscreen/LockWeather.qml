import QtQuick
import "../components"
import ".."

Row {
    id: indicator
    required property var controller
    required property var theme
    required property bool wanted
    readonly property var weather: controller.weather
    readonly property bool usable: weather.temperature !== null && weather.temperature !== undefined && Design.safeNumber(weather.weatherCode, -1) >= 0
    visible: wanted && usable
    spacing: Design.compactItemSpacing

    CompactBarIcon {
        name: indicator.controller.weatherIconName(Design.safeNumber(indicator.weather.weatherCode, -1))
        color: indicator.theme.colors.accent
    }

    CompactBarLabel {
        text: Math.round(Design.safeNumber(indicator.weather.temperature, 0)) + "°C"
        color: indicator.theme.colors.foreground
    }
}
