import QtQuick
import "../components"
import ".."

// Read-only widget cluster. It reuses the desktop clock and weather cards and
// the shared SystemService data; nothing here handles pointer or key input.
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
    readonly property bool showBattery: enabledWidgets.battery === true && controller.system.battery.available
    readonly property bool showSystem: enabledWidgets.system === true
    readonly property bool topRow: showClock || showWeather
    readonly property bool bottomRow: showBattery || showSystem
    readonly property real logicalHeight: (topRow ? 84 : 0) + (topRow && bottomRow ? gap : 0) + (bottomRow ? 48 : 0)
    readonly property real fit: Math.min(1.5, availableWidth / logicalWidth, availableHeight / Math.max(1, logicalHeight))

    visible: topRow || bottomRow
    width: logicalWidth * fit
    height: logicalHeight * fit
    enabled: false

    Column {
        width: cluster.logicalWidth
        height: cluster.logicalHeight
        scale: cluster.fit
        transformOrigin: Item.TopLeft
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

        Row {
            width: parent.width
            height: 48
            spacing: cluster.gap
            visible: cluster.bottomRow

            Glass {
                id: batteryCard
                theme: cluster.theme
                surfaceOpacity: Design.themedSurfaceOpacity(.84)
                radius: Design.radiusMd
                visible: cluster.showBattery
                width: visible ? (cluster.showSystem ? (parent.width - parent.spacing) / 2 : parent.width) : 0
                height: parent.height

                CompactBarItem {
                    anchors.centerIn: parent
                    theme: cluster.theme
                    filled: false
                    iconName: cluster.controller.batteryIconName()
                    iconColor: cluster.theme.colors[cluster.controller.batteryColorRole()]
                    trailingIconName: cluster.controller.batteryCharging() ? "charging" : ""
                    label: cluster.controller.batteryExpandedText()
                }
            }

            Glass {
                theme: cluster.theme
                surfaceOpacity: Design.themedSurfaceOpacity(.84)
                radius: Design.radiusMd
                visible: cluster.showSystem
                width: visible ? parent.width - (batteryCard.visible ? batteryCard.width + parent.spacing : 0) : 0
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
