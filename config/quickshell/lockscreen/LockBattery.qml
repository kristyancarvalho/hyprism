import QtQuick
import "../components"
import ".."

Row {
    id: indicator
    required property var controller
    required property var theme
    readonly property bool usable: controller.system.battery.available && controller.systemServiceAvailable
    visible: usable
    spacing: Design.compactItemSpacing

    CompactBarIcon {
        name: indicator.controller.batteryIconName()
        color: indicator.theme.colors[indicator.controller.batteryColorRole()]
    }

    CompactBarIcon {
        visible: indicator.controller.batteryCharging()
        name: "charging"
        iconSize: Design.compactConnectivityIconSize
        color: indicator.theme.colors.accent
    }

    CompactBarLabel {
        text: indicator.controller.batteryText()
        color: indicator.theme.colors.foreground
    }
}
