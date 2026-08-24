import QtQuick
import ".."

CompactBarItem {
    id: battery
    required property var controller
    property bool showPercentage: false

    visible: controller.system.battery.available
    iconName: controller.batteryIconName()
    iconColor: theme.colors[controller.batteryColorRole()]
    trailingIconName: controller.batteryCharging() ? "charging" : ""
    label: showPercentage ? controller.batteryText() : ""
    iconOnly: !showPercentage
}
