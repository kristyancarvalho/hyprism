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
    readonly property bool compactVisible: controller.mode === "compact" || controller.targetScreenName !== shellScreen.name
    screen: shellScreen
    visible: shellScreen !== null
    anchors.top: true
    margins.top: Design.compactTopMargin(controller.config.shell)
    implicitWidth: Math.min(shellScreen ? shellScreen.width - 32 : 560, Math.max(520, controller.config.shell.islandWidth))
    implicitHeight: Design.compactHeight(controller.config.shell)
    color: "transparent"
    exclusiveZone: Design.compactHeight(controller.config.shell) + Design.compactGap(controller.config.shell)
    mask: Region {
        width: window.compactVisible ? window.width : 0
        height: window.compactVisible ? window.height : 0
        radius: Design.compactRadius
    }
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Glass {
        id: surface
        anchors.fill: parent
        visible: window.compactVisible
        radius: Design.compactRadius
        theme: window.theme
        surfaceOpacity: controller.config.shell.surfaceOpacity

        Item {
            anchors.fill: parent
            anchors.leftMargin: Design.compactHorizontalPadding
            anchors.rightMargin: Design.compactHorizontalPadding

            Row {
                id: leftGroup
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                height: Design.compactItemHeight
                spacing: Design.compactGroupSpacing

                CompactBarPill {
                    theme: window.theme
                    iconName: "workspace"
                    label: Hyprland.focusedWorkspace ? String(Hyprland.focusedWorkspace.id) : "1"
                    selected: true
                }

                CompactBarPill {
                    visible: controller.mediaAvailable()
                    width: visible ? Math.min(176, Math.max(118, implicitWidth)) : 0
                    theme: window.theme
                    iconName: "media"
                    label: controller.mediaArtist() + " — " + controller.mediaTitle()
                    labelMaximumWidth: 132
                    onClicked: controller.mediaToggle()
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
                    selected: false
                }

                CompactBarSeparator { theme: window.theme }

                CompactBarPill {
                    visible: controller.weather.temperature !== null
                    theme: window.theme
                    iconName: controller.weatherIconName(controller.weather.weatherCode)
                    label: Math.round(Design.safeNumber(controller.weather.temperature, 0)) + "°"
                }
            }

            Row {
                id: rightGroup
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: Design.compactItemHeight
                spacing: Design.compactItemSpacing

                CompactBarPill {
                    theme: window.theme
                    iconName: controller.networkIconName()
                    label: controller.networkLabel()
                    active: controller.system.network.enabled
                }

                CompactBarPill {
                    visible: controller.system.bluetooth.available
                    theme: window.theme
                    iconName: controller.bluetoothIconName()
                    iconOnly: true
                    active: controller.system.bluetooth.powered
                }

                CompactBarPill {
                    visible: controller.system.battery.available
                    theme: window.theme
                    iconName: controller.batteryIconName()
                    label: controller.batteryText()
                }
            }
        }

        HoverHandler {
            onHoveredChanged: if (hovered && controller.mode === "compact") controller.openOnScreen("hover", window.shellScreen.name)
        }

        TapHandler {
            onTapped: controller.openOnScreen("control", window.shellScreen.name)
        }
    }
}
