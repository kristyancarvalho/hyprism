import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../components"
import ".."

PanelWindow {
    id: window
    required property var shellScreen
    required property var controller
    required property var theme
    readonly property bool compactVisible: controller.targetScreenName !== shellScreen.name || controller.mode === "compact" && !controller.morphClosing
    screen: shellScreen
    visible: shellScreen !== null
    anchors.top: true
    margins.top: Design.compactTopMargin(controller.config.shell)
    implicitWidth: Design.compactWidth(controller.config.shell, shellScreen ? shellScreen.width : Design.compactWidthMax)
    implicitHeight: Design.compactHeight(controller.config.shell)
    color: "transparent"
    exclusiveZone: Design.compactHeight(controller.config.shell) + Design.compactGap(controller.config.shell)
    mask: Region {
        width: window.compactVisible ? window.width : 0
        height: window.compactVisible ? window.height : 0
        radius: Design.compactRadiusFor(controller.config.shell)
    }
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Glass {
        id: surface
        anchors.fill: parent
        visible: window.compactVisible
        radius: Design.compactRadiusFor(controller.config.shell)
        theme: window.theme
        surfaceOpacity: controller.config.shell.surfaceOpacity

        Item {
            anchors.fill: parent
            anchors.leftMargin: Design.compactHorizontalPadding
            anchors.rightMargin: Design.compactHorizontalPadding

            Item {
                id: leftGroup
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(workspaceItem.width, centerGroup.x - Design.compactGroupSpacing)
                height: Design.compactItemHeight

                CompactBarPill {
                    id: workspaceItem
                    anchors.left: parent.left
                    theme: window.theme
                    iconName: "workspace"
                    label: Hyprland.focusedWorkspace ? String(Hyprland.focusedWorkspace.id) : "1"
                    selected: true
                }

                CompactBarItem {
                    id: mediaItem
                    visible: controller.mediaAvailable()
                    anchors.left: workspaceItem.right
                    anchors.leftMargin: Design.compactItemSpacing
                    anchors.right: parent.right
                    theme: window.theme
                    iconName: "media"
                    label: controller.mediaArtist() + " — " + controller.mediaTitle()
                    labelMaximumWidth: Math.max(0, width - Design.compactIconSize - Design.compactItemSpacing - horizontalPadding * 2 - 2)
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
                    theme: window.theme
                    filled: false
                    label: controller.formattedDate("HH:mm")
                    horizontalPadding: Design.compactPlainPadding
                    labelWeight: Design.fontWeightSemibold
                }

                CompactBarItem {
                    visible: controller.weather.temperature !== null
                    theme: window.theme
                    iconName: controller.weatherIconName(controller.weather.weatherCode)
                    label: Math.round(Design.safeNumber(controller.weather.temperature, 0)) + "°"
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

                CompactBarSeparator { theme: window.theme }

                CompactBarItem {
                    theme: window.theme
                    iconName: controller.networkIconName()
                    label: controller.networkLabel()
                    filled: false
                    horizontalPadding: Design.compactPlainPadding
                }

                CompactBarItem {
                    visible: controller.system.bluetooth.available
                    theme: window.theme
                    iconName: controller.bluetoothIconName()
                    iconOnly: true
                    filled: false
                    horizontalPadding: Design.compactPlainPadding
                }

                CompactBarItem {
                    visible: controller.system.battery.available
                    theme: window.theme
                    iconName: controller.batteryIconName()
                    label: controller.batteryText()
                    filled: false
                    horizontalPadding: Design.compactPlainPadding
                }
            }
        }

        HoverHandler {
            id: compactHover
            onHoveredChanged: {
                if (hovered && controller.mode === "compact") hoverOpen.restart()
                else hoverOpen.stop()
            }
        }

        TapHandler {
            onPressedChanged: if (pressed) hoverOpen.stop()
            onTapped: controller.openOnScreen("control", window.shellScreen.name)
        }
    }

    Timer {
        id: hoverOpen
        interval: 180
        onTriggered: if (compactHover.hovered && controller.mode === "compact") controller.openOnScreen("hover", window.shellScreen.name)
    }
}
