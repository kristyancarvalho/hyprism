import QtQuick
import QtQuick.Layouts
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
    readonly property bool targetScreen: !!shellScreen && controller.targetScreenName === shellScreen.name
    readonly property string localMode: controller.mode === "compact" || !targetScreen ? "compact" : controller.mode
    readonly property bool interactive: localMode !== "compact" && localMode !== "hover"
    readonly property bool fullscreenActive: HyprlandService.monitorHasFullscreen(shellScreen)
    readonly property int availableWidth: shellScreen ? shellScreen.width : 1024
    readonly property int availableHeight: shellScreen ? shellScreen.height : 768
    readonly property int safeWidth: Math.max(320, availableWidth - 32)
    readonly property int safeHeight: Math.max(Design.compactBarHeight, availableHeight - Design.compactTopMargin(controller.config.shell) - 16)
    readonly property int compactWidth: Design.compactWidth(controller.config.shell, availableWidth)
    readonly property int morphDuration: Math.max(1, Math.round(Design.safeNumber(controller.config.shell.animationNormal, Design.animationMorph)))
    readonly property var desiredGeometry: geometryForMode(localMode)
    property var morphFrom: ({ width: compactWidth, height: Design.compactHeight(controller.config.shell), radius: Design.radiusIslandCompact })
    property var morphTarget: ({ width: compactWidth, height: Design.compactHeight(controller.config.shell), radius: Design.radiusIslandCompact })
    property real morphProgress: 1
    property bool acceptsFocusDismissal: false
    readonly property real morphWidth: Design.clamp(morphFrom.width + (morphTarget.width - morphFrom.width) * morphProgress, 320, implicitWidth)
    readonly property real morphHeight: Design.clamp(morphFrom.height + (morphTarget.height - morphFrom.height) * morphProgress, Design.compactHeight(controller.config.shell), implicitHeight)
    readonly property real morphRadius: morphFrom.radius + (morphTarget.radius - morphFrom.radius) * morphProgress

    function geometryForMode(mode) {
        let width = compactWidth
        let height = Design.compactHeight(controller.config.shell)
        if (mode === "hover") {
            width = Math.min(safeWidth, 860)
            height = controller.mediaAvailable() ? 88 : 64
        } else if (mode === "launcher") {
            width = Math.min(safeWidth, 720)
            height = Design.launcherHeight(controller.launcherResultCount)
        } else if (mode === "wallpaper") {
            width = Math.min(safeWidth, 880)
            const columns = width >= 796 ? 4 : width >= 536 ? 3 : 2
            const rows = Math.max(1, Math.ceil(controller.wallpaperResultCount / columns))
            const cellHeight = Math.max(112, Math.min(142, (width - Design.spacingLg * 2) / columns * .66))
            height = Math.min(560, 132 + rows * cellHeight)
        } else if (mode === "clipboard") {
            width = Math.min(safeWidth, 700)
            height = Math.min(500, 120 + Math.max(58, controller.clipboardResultHeight))
        } else if (mode === "control") {
            width = Math.min(safeWidth, 600)
            height = 700
        } else if (mode === "network") {
            width = Math.min(safeWidth, 560)
            height = controller.networkResultCount ? Math.min(440, 76 + Design.listContentHeight(controller.networkResultCount, 56, 6, 58)) : 170
        } else if (mode === "bluetooth") {
            width = Math.min(safeWidth, 560)
            height = controller.system.bluetooth.available && controller.system.bluetooth.devices.length ? Math.min(460, 76 + Design.listContentHeight(controller.system.bluetooth.devices.length, 58, 6, 58)) : 170
        } else if (mode === "power") {
            width = Math.min(safeWidth, 640)
            height = 300
        } else if (mode === "emoji") {
            width = Math.min(safeWidth, Design.emojiPickerWidth)
            const columns = Design.gridColumnCount(width - 2 * Design.spacingLg, Design.emojiCellSize)
            height = Math.min(360, 90 + Design.gridContentHeight(controller.emojiResultCount, columns, Design.emojiCellSize, Design.emojiCellSize))
        } else if (mode === "switcher") {
            width = Math.min(safeWidth, 920)
            height = 220
        } else if (mode === "recordingSelector") {
            width = Math.min(safeWidth, 480)
            height = 184
        }
        return {
            width: Math.round(Design.clamp(width, 320, Math.min(safeWidth, Design.morphSurfaceMaxWidth))),
            height: Math.round(Design.clamp(height, Design.compactBarHeight, Math.min(safeHeight, Design.morphSurfaceMaxHeight))),
            radius: mode === "compact" ? Design.radiusIslandCompact : Design.radiusIslandExpanded
        }
    }

    function startMorph(nextGeometry) {
        if (morphAnimation.running && Math.abs(morphTarget.width - nextGeometry.width) < .5 && Math.abs(morphTarget.height - nextGeometry.height) < .5 && Math.abs(morphTarget.radius - nextGeometry.radius) < .1) return
        const currentGeometry = { width: morphWidth, height: morphHeight, radius: morphRadius }
        if (Math.abs(currentGeometry.width - nextGeometry.width) < .5 && Math.abs(currentGeometry.height - nextGeometry.height) < .5 && Math.abs(currentGeometry.radius - nextGeometry.radius) < .1) {
            morphFrom = nextGeometry
            morphTarget = nextGeometry
            morphProgress = 1
            return
        }
        morphAnimation.stop()
        morphFrom = currentGeometry
        morphTarget = nextGeometry
        morphProgress = 0
        morphAnimation.start()
    }

    function focusPanel() {
        if (!interactive || !content.item) return
        if (content.item.takeInitialFocus) content.item.takeInitialFocus()
        else content.item.forceActiveFocus()
        controller.panelFocusReady = content.item.initialFocusReady ? content.item.initialFocusReady() : content.item.activeFocus
    }

    screen: shellScreen
    visible: shellScreen !== null && (!fullscreenActive || interactive)
    anchors.top: true
    margins.top: Design.compactTopMargin(controller.config.shell)
    implicitWidth: Math.min(safeWidth, Design.morphSurfaceMaxWidth + Design.morphOvershootMargin)
    implicitHeight: Math.min(safeHeight, Design.morphSurfaceMaxHeight + Design.morphOvershootMargin)
    color: "transparent"
    surfaceFormat.opaque: false
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: morphSurface }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: interactive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onDesiredGeometryChanged: startMorph(desiredGeometry)

    HyprlandFocusGrab {
        id: focusGrab
        windows: [window]
        onCleared: {
            if (!window.interactive) return
            if (window.acceptsFocusDismissal) controller.close()
            else focusActivation.restart()
        }
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
        outlined: true
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
            onTapped: controller.openHub(window.shellScreen.name)
        }

        Loader {
            id: content
            anchors.fill: parent
            opacity: 1
            sourceComponent: window.localMode === "launcher" ? launcher : window.localMode === "wallpaper" ? wallpaper : window.localMode === "clipboard" ? clipboardPanel : window.localMode === "control" ? control : window.localMode === "network" ? network : window.localMode === "bluetooth" ? bluetooth : window.localMode === "power" ? power : window.localMode === "emoji" ? emoji : window.localMode === "switcher" ? switcher : window.localMode === "recordingSelector" ? recordingSelector : window.localMode === "hover" ? expanded : compactContent
            onLoaded: focusTimer.restart()
        }
    }

    NumberAnimation {
        id: morphAnimation
        target: window
        property: "morphProgress"
        from: 0
        to: 1
        duration: window.morphDuration
        easing.type: Design.easingPanelMorph
        easing.overshoot: Design.panelMorphOvershoot
    }

    Timer {
        id: hoverOpen
        interval: Design.animationFast
        onTriggered: if (shellHover.hovered && controller.mode === "compact" && !window.fullscreenActive) controller.openPanel("hover", window.shellScreen.name)
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
        id: focusActivation
        interval: 40
        onTriggered: {
            if (!window.interactive) return
            focusGrab.active = true
            window.focusPanel()
        }
    }

    Timer {
        id: focusDismissalReady
        interval: 240
        onTriggered: if (window.interactive) window.acceptsFocusDismissal = true
    }

    Timer {
        id: recordingSurfaceRelease
        interval: 0
        onTriggered: {
            if (!window.interactive && window.targetScreen && controller.recordingSelecting)
                controller.confirmRecordingSurfaceReleased()
        }
    }

    Component.onCompleted: {
        morphFrom = desiredGeometry
        morphTarget = desiredGeometry
        morphProgress = 1
    }

    onFullscreenActiveChanged: if (fullscreenActive && localMode === "hover") controller.close()
    onInteractiveChanged: {
        if (interactive) {
            acceptsFocusDismissal = false
            focusActivation.restart()
            focusDismissalReady.restart()
        } else {
            acceptsFocusDismissal = false
            focusActivation.stop()
            focusDismissalReady.stop()
            focusGrab.active = false
            if (targetScreen && controller.recordingSelecting) recordingSurfaceRelease.restart()
        }
    }

    Component {
        id: compactContent

        CompactIslandContent {
            shellScreen: window.shellScreen
            controller: window.controller
            theme: window.theme
            notifications: window.notifications
        }
    }

    Component {
        id: expanded

        Item {
            anchors.fill: parent

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Design.spacingLg
                anchors.rightMargin: Design.spacingLg
                spacing: Design.spacingSm

            WorkspaceStrip {
                Layout.alignment: Qt.AlignVCenter
                shellScreen: window.shellScreen
                theme: window.theme
            }

            Item {
                Layout.fillWidth: true
                Layout.minimumWidth: 80
                Layout.maximumWidth: 410
                Layout.preferredHeight: 60
                clip: true

                MediaStrip {
                    visible: controller.mediaAvailable() && !controller.recording
                    anchors {
                        left: mediaDnd.right
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                        leftMargin: mediaDnd.visible ? Design.compactItemSpacing : 0
                    }
                    controller: window.controller
                    theme: window.theme
                }

                DndIndicator {
                    id: mediaDnd
                    visible: controller.mediaAvailable() && !controller.recording && (active || opacity > 0)
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    theme: window.theme
                    notifications: window.notifications
                }

                Row {
                    visible: !controller.mediaAvailable() && !controller.recording
                    anchors.centerIn: parent
                    spacing: Design.compactItemSpacing

                    DndIndicator {
                        anchors.verticalCenter: parent.verticalCenter
                        theme: window.theme
                        notifications: window.notifications
                    }

                    Column {
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
                }

                Row {
                    visible: controller.recording
                    anchors.centerIn: parent
                    spacing: Design.spacingSm

                    DndIndicator {
                        anchors.verticalCenter: parent.verticalCenter
                        theme: window.theme
                        notifications: window.notifications
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        color: theme.colors.warning
                        width: 8
                        height: 8
                        radius: 4
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: controller.recordingElapsedText()
                        color: theme.colors.foreground
                        font.family: Design.fontFamily
                        font.pixelSize: Design.fontSizeSm
                        font.weight: Design.fontWeightSemibold
                    }

                    ShellButton {
                        theme: window.theme
                        text: "Parar"
                        iconName: "close"
                        compact: true
                        warning: true
                        onClicked: controller.stopRecording()
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: Design.compactItemSpacing

                CompactBarItem {
                    visible: controller.weather.temperature !== null
                    theme: window.theme
                    iconName: controller.weatherIconName(controller.weather.weatherCode)
                    label: Math.round(Design.safeNumber(controller.weather.temperature, 0)) + "°"
                    iconOnly: window.morphWidth < 720
                    labelMaximumWidth: 48
                    filled: false
                }

                CompactBarItem {
                    theme: window.theme
                    iconName: controller.networkIconName()
                    iconSize: Design.compactConnectivityIconSize
                    labelSize: Design.compactConnectivityTextSize
                    label: controller.networkLabel()
                    iconOnly: window.morphWidth < 760
                    labelMaximumWidth: 110
                    filled: false
                }

                CompactBarItem {
                    visible: controller.system.bluetooth.available
                    theme: window.theme
                    iconName: controller.bluetoothIconName()
                    iconSize: Design.compactConnectivityIconSize
                    labelSize: Design.compactConnectivityTextSize
                    label: controller.bluetoothExpandedText()
                    iconOnly: window.morphWidth < 840
                    labelMaximumWidth: 130
                    filled: false
                }

                BatteryStatus {
                    theme: window.theme
                    controller: window.controller
                    showPercentage: window.morphWidth >= 800
                    labelMaximumWidth: 105
                    filled: false
                }
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
    Component { id: recordingSelector; RecordingSelector { controller: window.controller; theme: window.theme } }
}
