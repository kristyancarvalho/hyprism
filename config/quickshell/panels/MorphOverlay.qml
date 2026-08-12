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
    required property var apps
    required property var clipboard
    required property var notifications
    readonly property bool targetScreen: controller.targetScreenName === shellScreen.name
    readonly property string localMode: controller.mode === "compact" || !targetScreen ? "compact" : controller.mode
    readonly property bool interactive: localMode !== "compact" && localMode !== "hover"
    readonly property int availableWidth: shellScreen ? shellScreen.width : 1024
    readonly property int availableHeight: shellScreen ? shellScreen.height : 768
    readonly property int safeWidth: Math.max(320, availableWidth - 32)
    readonly property int safeHeight: Math.max(Design.compactBarHeight, availableHeight - Design.compactTopMargin(controller.config.shell) - 16)
    readonly property int compactWidth: Design.compactWidth(controller.config.shell, availableWidth)
    readonly property int morphDuration: Math.max(1, Math.round(Design.safeNumber(controller.config.shell.animationNormal, Design.animationMorph)))
    readonly property var desiredGeometry: geometryForMode(localMode)
    property var morphFrom: ({ width: compactWidth, height: Design.compactHeight(controller.config.shell), radius: Design.radiusDefault })
    property var morphTarget: ({ width: compactWidth, height: Design.compactHeight(controller.config.shell), radius: Design.radiusDefault })
    property real morphProgress: 1
    readonly property real morphWidth: morphFrom.width + (morphTarget.width - morphFrom.width) * morphProgress
    readonly property real morphHeight: morphFrom.height + (morphTarget.height - morphFrom.height) * morphProgress
    readonly property real morphRadius: morphFrom.radius + (morphTarget.radius - morphFrom.radius) * morphProgress

    function geometryForMode(mode) {
        let width = compactWidth
        let height = Design.compactHeight(controller.config.shell)
        if (mode === "hover") {
            width = Math.min(safeWidth, controller.mediaAvailable() ? 860 : 700)
            height = controller.mediaAvailable() ? 88 : 64
        } else if (mode === "launcher") {
            width = Math.min(safeWidth, 720)
            height = Design.launcherHeight(controller.launcherResultCount)
        } else if (mode === "wallpaper") {
            width = Math.min(safeWidth, 880)
            const columns = width >= 800 ? 4 : width >= 560 ? 3 : 2
            const rows = Math.max(1, Math.ceil(controller.wallpaperEntries.length / columns))
            height = Math.min(560, 104 + rows * 150)
        } else if (mode === "clipboard") {
            width = Math.min(safeWidth, 700)
            height = 500
        } else if (mode === "control") {
            width = Math.min(safeWidth, 600)
            height = 700
        } else if (mode === "network") {
            width = Math.min(safeWidth, 560)
            height = 440
        } else if (mode === "bluetooth") {
            width = Math.min(safeWidth, 560)
            height = controller.system.bluetooth.available ? Math.min(460, 130 + controller.system.bluetooth.devices.length * 68) : 170
        } else if (mode === "power") {
            width = Math.min(safeWidth, 640)
            height = 300
        } else if (mode === "emoji") {
            width = Math.min(safeWidth, 540)
            height = 360
        } else if (mode === "switcher") {
            width = Math.min(safeWidth, 920)
            height = 220
        }
        return {
            width: Math.round(Design.clamp(width, 320, Math.min(safeWidth, Design.morphSurfaceMaxWidth))),
            height: Math.round(Design.clamp(height, Design.compactBarHeight, Math.min(safeHeight, Design.morphSurfaceMaxHeight))),
            radius: Design.radiusDefault
        }
    }

    function startMorph(nextGeometry) {
        const currentGeometry = { width: morphWidth, height: morphHeight, radius: morphRadius }
        morphAnimation.stop()
        morphFrom = currentGeometry
        morphTarget = nextGeometry
        morphProgress = 0
        morphAnimation.start()
    }

    function focusPanel() {
        if (!interactive || !content.item) return
        window.requestActivate()
        if (content.item.takeInitialFocus) content.item.takeInitialFocus()
        else content.item.forceActiveFocus()
    }

    screen: shellScreen
    visible: shellScreen !== null
    anchors.top: true
    margins.top: Design.compactTopMargin(controller.config.shell)
    implicitWidth: Math.min(safeWidth, Design.morphSurfaceMaxWidth)
    implicitHeight: Math.min(safeHeight, Design.morphSurfaceMaxHeight)
    color: "transparent"
    surfaceFormat.opaque: false
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: morphSurface }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: interactive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onDesiredGeometryChanged: startMorph(desiredGeometry)

    HyprlandFocusGrab {
        windows: [window]
        active: window.visible && window.interactive
        onCleared: if (window.interactive) controller.close()
    }

    Glass {
        id: morphSurface
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.round(window.morphWidth)
        height: Math.round(window.morphHeight)
        radius: window.morphRadius
        theme: window.theme
        surfaceOpacity: controller.config.shell.surfaceOpacity
        clip: true

        HoverHandler {
            id: shellHover
            onHoveredChanged: {
                if (hovered) {
                    hoverClose.stop()
                    if (controller.mode === "compact") hoverOpen.restart()
                } else {
                    hoverOpen.stop()
                    if (window.localMode === "hover") hoverClose.restart()
                }
            }
        }

        TapHandler {
            enabled: window.localMode === "compact" || window.localMode === "hover"
            onPressedChanged: if (pressed) hoverOpen.stop()
            onTapped: controller.openOnScreen("control", window.shellScreen.name)
        }

        Loader {
            id: content
            anchors.fill: parent
            opacity: 1
            sourceComponent: window.localMode === "launcher" ? launcher : window.localMode === "wallpaper" ? wallpaper : window.localMode === "clipboard" ? clipboardPanel : window.localMode === "control" ? control : window.localMode === "network" ? network : window.localMode === "bluetooth" ? bluetooth : window.localMode === "power" ? power : window.localMode === "emoji" ? emoji : window.localMode === "switcher" ? switcher : window.localMode === "hover" ? expanded : compactContent
            onLoaded: {
                opacity = 0
                contentReveal.restart()
                focusTimer.restart()
            }
            Behavior on opacity { NumberAnimation { duration: Design.animationInstant; easing.type: Easing.OutCubic } }
        }
    }

    NumberAnimation {
        id: morphAnimation
        target: window
        property: "morphProgress"
        from: 0
        to: 1
        duration: window.morphDuration
        easing.type: Easing.OutCubic
    }

    Timer {
        id: hoverOpen
        interval: Design.animationFast
        onTriggered: if (shellHover.hovered && controller.mode === "compact") controller.openOnScreen("hover", window.shellScreen.name)
    }

    Timer {
        id: hoverClose
        interval: 240
        onTriggered: if (window.localMode === "hover") controller.close()
    }

    Timer {
        id: focusTimer
        interval: 0
        onTriggered: window.focusPanel()
    }

    Timer {
        id: contentReveal
        interval: 20
        onTriggered: content.opacity = 1
    }

    Component.onCompleted: {
        morphFrom = desiredGeometry
        morphTarget = desiredGeometry
        morphProgress = 1
    }

    Component {
        id: compactContent

        CompactIslandContent {
            shellScreen: window.shellScreen
            controller: window.controller
            theme: window.theme
        }
    }

    Component {
        id: expanded

        Item {
            anchors.fill: parent

            WorkspaceStrip {
                anchors.left: parent.left
                anchors.leftMargin: Design.spacingLg
                anchors.verticalCenter: parent.verticalCenter
                shellScreen: window.shellScreen
                theme: window.theme
            }

            MediaStrip {
                visible: controller.mediaAvailable()
                anchors.centerIn: parent
                width: Math.min(410, parent.width * .48)
                controller: window.controller
                theme: window.theme
            }

            Column {
                visible: !controller.mediaAvailable()
                anchors.centerIn: parent

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: controller.formattedDate("HH:mm")
                    color: theme.colors.foreground
                    font.family: Design.fontFamily
                    font.pixelSize: Design.fontSizeLg
                    font.weight: Design.fontWeightSemibold
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: controller.formattedDate("ddd, dd MMM")
                    color: theme.colors.mutedForeground
                    font.family: Design.fontFamily
                    font.pixelSize: Design.fontSizeXs
                }
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: Design.spacingLg
                anchors.verticalCenter: parent.verticalCenter
                spacing: Design.compactItemSpacing

                CompactBarItem {
                    visible: controller.weather.temperature !== null
                    theme: window.theme
                    iconName: controller.weatherIconName(controller.weather.weatherCode)
                    label: Math.round(Design.safeNumber(controller.weather.temperature, 0)) + "°"
                    filled: false
                }

                CompactBarItem {
                    theme: window.theme
                    iconName: controller.networkIconName()
                    iconOnly: true
                    filled: false
                }

                CompactBarItem {
                    visible: controller.system.bluetooth.available
                    theme: window.theme
                    iconName: controller.bluetoothIconName()
                    iconOnly: true
                    filled: false
                }

                CompactBarItem {
                    visible: controller.system.battery.available
                    theme: window.theme
                    iconName: controller.batteryIconName()
                    trailingIconName: controller.batteryCharging() ? "charging" : ""
                    label: controller.batteryText()
                    filled: false
                }
            }
        }
    }

    Component { id: launcher; Launcher { controller: window.controller; theme: window.theme } }
    Component { id: wallpaper; WallpaperPicker { controller: window.controller; theme: window.theme; appService: window.apps } }
    Component { id: clipboardPanel; Clipboard { controller: window.controller; theme: window.theme; clipboard: window.clipboard } }
    Component { id: control; ControlCenter { controller: window.controller; theme: window.theme; notificationServer: window.notifications } }
    Component { id: network; NetworkPanel { controller: window.controller; theme: window.theme } }
    Component { id: bluetooth; BluetoothPanel { controller: window.controller; theme: window.theme } }
    Component { id: power; PowerMenu { controller: window.controller; theme: window.theme } }
    Component { id: emoji; EmojiPicker { controller: window.controller; theme: window.theme } }
    Component { id: switcher; WindowSwitcher { controller: window.controller; theme: window.theme } }
}
