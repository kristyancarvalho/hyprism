import QtQuick
import "../components"
import ".."

Item {
    id: cluster
    required property var controller
    required property var theme
    required property var enabledWidgets
    required property real availableWidth
    required property real availableHeight
    readonly property int logicalWidth: 428
    readonly property int gap: Design.desktopWidgetGap
    readonly property bool showClock: enabledWidgets.clock === true
    readonly property bool showWeather: enabledWidgets.weather === true
    readonly property bool showMedia: enabledWidgets.media === true && controller.mediaAvailable() && controller.mediaPlayer.isPlaying
    readonly property bool showSystem: enabledWidgets.system === true
    readonly property bool topRow: showClock || showWeather
    readonly property bool bottomRow: showSystem
    readonly property real logicalHeight: (topRow ? 84 : 0) + (topRow && (showMedia || bottomRow) ? gap : 0) + (showMedia ? 112 : 0) + (showMedia && bottomRow ? gap : 0) + (bottomRow ? 48 : 0)
    readonly property real fit: Math.min(1.5, availableWidth / logicalWidth, availableHeight / Math.max(1, logicalHeight))

    visible: topRow || showMedia || bottomRow
    width: logicalWidth * fit
    height: logicalHeight * fit
    enabled: false

    Column {
        width: cluster.logicalWidth
        height: cluster.logicalHeight
        scale: cluster.fit
        transformOrigin: Item.TopLeft
        layer.enabled: true
        layer.smooth: true
        layer.textureSize: Qt.size(Math.ceil(width * scale * 2), Math.ceil(height * scale * 2))
        spacing: cluster.gap

        Row {
            width: parent.width
            height: 84
            spacing: cluster.gap
            visible: cluster.topRow

            ClockCard {
                id: clockCard
                theme: cluster.theme
                controller: cluster.controller
                visible: cluster.showClock
                width: visible ? (cluster.showWeather ? (parent.width - parent.spacing) * .44 : parent.width) : 0
                height: parent.height
            }

            WeatherCard {
                theme: cluster.theme
                controller: cluster.controller
                visible: cluster.showWeather
                width: visible ? parent.width - (clockCard.visible ? clockCard.width + parent.spacing : 0) : 0
                height: parent.height
            }
        }

        MediaCard {
            theme: cluster.theme
            controller: cluster.controller
            interactive: false
            visible: cluster.showMedia
            width: parent.width
            height: visible ? 112 : 0
        }

        Row {
            width: parent.width
            height: 48
            spacing: cluster.gap
            visible: cluster.bottomRow

            Glass {
                theme: cluster.theme
                surfaceOpacity: Design.themedSurfaceOpacity(.84)
                radius: Design.radiusMd
                visible: cluster.showSystem
                width: parent.width
                height: parent.height

                Row {
                    anchors.centerIn: parent
                    spacing: Design.spacingLg

                    WidgetMetric {
                        theme: cluster.theme
                        iconName: "cpu"
                        value: "CPU " + Math.round(Design.clamp(cluster.controller.system.cpu.percent, 0, 100)) + "%"
                    }

                    WidgetMetric {
                        theme: cluster.theme
                        iconName: "memory"
                        value: I18n.tr("widgets.memory") + " " + Math.round(Design.clamp(cluster.controller.system.memory.percent, 0, 100)) + "%"
                    }
                }
            }
        }
    }
}
