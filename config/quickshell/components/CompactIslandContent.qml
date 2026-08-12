import QtQuick
import ".."

Item {
    id: compact
    required property var shellScreen
    required property var controller
    required property var theme

    Item {
        anchors.fill: parent
        anchors.leftMargin: Design.compactHorizontalPadding
        anchors.rightMargin: Design.compactHorizontalPadding

        Item {
            id: leftGroup
            anchors.left: parent.left
            anchors.right: centerGroup.left
            anchors.rightMargin: Design.compactGroupSpacing
            anchors.verticalCenter: parent.verticalCenter
            height: Design.compactItemHeight

            WorkspaceStrip {
                id: workspaces
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                shellScreen: compact.shellScreen
                theme: compact.theme
            }

            CompactBarItem {
                id: mediaItem
                visible: compact.controller.mediaAvailable()
                anchors.left: workspaces.right
                anchors.leftMargin: Design.compactItemSpacing
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                theme: compact.theme
                iconName: "media"
                label: compact.controller.mediaArtist() + " — " + compact.controller.mediaTitle()
                labelMaximumWidth: Math.max(0, Math.min(210, width - Design.compactIconSize - Design.compactItemSpacing - horizontalPadding * 2 - 2))
                filled: false
                horizontalPadding: Design.compactPlainPadding
            }
        }

        Row {
            id: centerGroup
            anchors.centerIn: parent
            height: Design.compactItemHeight
            spacing: Design.compactItemSpacing

            CompactBarItem {
                theme: compact.theme
                filled: false
                label: compact.controller.formattedDate("HH:mm")
                horizontalPadding: Design.compactPlainPadding
                labelWeight: Design.fontWeightSemibold
            }

            CompactBarItem {
                visible: compact.controller.weather.temperature !== null
                theme: compact.theme
                iconName: compact.controller.weatherIconName(compact.controller.weather.weatherCode)
                label: Math.round(Design.safeNumber(compact.controller.weather.temperature, 0)) + "°"
                filled: false
                horizontalPadding: Design.compactPlainPadding
            }
        }

        Row {
            id: rightGroup
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: Design.compactItemHeight
            spacing: Design.compactItemSpacing

            CompactBarItem {
                theme: compact.theme
                iconName: compact.controller.networkIconName()
                label: compact.controller.networkLabel()
                filled: false
                horizontalPadding: Design.compactPlainPadding
            }

            CompactBarItem {
                visible: compact.controller.system.bluetooth.available
                theme: compact.theme
                iconName: compact.controller.bluetoothIconName()
                iconOnly: true
                filled: false
                horizontalPadding: Design.compactPlainPadding
            }

            CompactBarItem {
                visible: compact.controller.system.battery.available
                theme: compact.theme
                iconName: compact.controller.batteryIconName()
                trailingIconName: compact.controller.batteryCharging() ? "charging" : ""
                label: compact.controller.batteryText()
                filled: false
                horizontalPadding: Design.compactPlainPadding
            }
        }
    }
}
