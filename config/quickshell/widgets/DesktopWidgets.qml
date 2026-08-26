import QtQuick
import Quickshell
import Quickshell.Wayland
import "../components"
import ".."

PanelWindow {
    id: widgetWindow
    required property var shellScreen
    required property var controller
    required property var theme
    readonly property int columnGap: Design.spacingMd
    readonly property bool hasClockRow: controller.widgetEnabled("clock") || controller.widgetEnabled("weather")
    readonly property bool hasSensors: controller.widgetEnabled("sensors") && controller.monitoring.sensors.available
    readonly property bool hasServices: controller.widgetEnabled("services") && controller.monitoring.services.available && (!controller.widgetConfig("services").problemOnly || !controller.monitoring.services.healthy)
    readonly property bool hasTasks: controller.widgetEnabled("tasks") && controller.tasks.length > 0
    readonly property bool compactViewport: shellScreen && shellScreen.height < 900
    readonly property int visibleTaskLimit: Math.min(controller.widgetNumber("tasks", "limit", 3, 1, 6), compactViewport ? 1 : 3)
    readonly property int visibleProcessLimit: Math.min(controller.widgetNumber("processes", "limit", 3, 1, 6), compactViewport ? 2 : 3)
    readonly property int logicalWidth: shellScreen ? Math.min(shellScreen.width - Design.spacingLg * 2, Math.min(700, Math.max(570, shellScreen.width * .56))) : 680
    readonly property int logicalHeight: Math.max(primaryColumn.implicitHeight, secondaryColumn.implicitHeight)
    readonly property real effectiveScale: Math.min(Design.widgetScale, usableHeight / Math.max(1, logicalHeight), shellScreen ? (shellScreen.width - Design.spacingLg * 2) / logicalWidth : Design.widgetScale)
    readonly property int cardWidth: Math.max(200, Math.floor((logicalWidth - columnGap) / 2))
    readonly property string layoutPosition: controller.widgetLayoutPosition()
    readonly property int usableTop: Design.compactReservedHeight(controller.config.shell) + Design.spacingLg
    readonly property int usableHeight: shellScreen ? Math.max(0, shellScreen.height - usableTop - Design.spacingLg) : 0
    readonly property int centeredTop: usableTop + Math.max(0, Math.floor((usableHeight - implicitHeight) / 2))
    screen: shellScreen
    visible: shellScreen !== null && !HyprlandService.monitorHasFullscreen(shellScreen)
    anchors {
        right: widgetWindow.layoutPosition === "top-right" || widgetWindow.layoutPosition === "bottom-right"
        left: widgetWindow.layoutPosition === "top-left" || widgetWindow.layoutPosition === "bottom-left"
        top: widgetWindow.layoutPosition !== "bottom-left" && widgetWindow.layoutPosition !== "bottom-right"
        bottom: widgetWindow.layoutPosition === "bottom-left" || widgetWindow.layoutPosition === "bottom-right"
    }
    margins {
        top: widgetWindow.layoutPosition === "center" ? widgetWindow.centeredTop : widgetWindow.usableTop
        bottom: Design.spacingLg
        right: Design.spacingLg
        left: Design.spacingLg
    }
    implicitWidth: logicalWidth * effectiveScale
    implicitHeight: logicalHeight * effectiveScale
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    function historyPeak(samples) {
        const values = Array.isArray(samples) ? samples : []
        let peak = 1
        for (let index = 0; index < values.length; index++) peak = Math.max(peak, Design.safeNumber(values[index], 0))
        return peak * 1.15
    }

    Row {
        width: widgetWindow.logicalWidth
        height: widgetWindow.logicalHeight
        scale: widgetWindow.effectiveScale
        transformOrigin: Item.TopLeft
        spacing: widgetWindow.columnGap

        Column {
            id: primaryColumn
            width: widgetWindow.cardWidth
            spacing: Design.spacingSm

            Row {
                width: parent.width
                height: visible ? 96 : 0
                spacing: Design.spacingSm
                visible: widgetWindow.hasClockRow

                Glass {
                    id: clockCard
                    theme: widgetWindow.theme
                    surfaceOpacity: .84
                    width: controller.widgetEnabled("clock") ? (controller.widgetEnabled("weather") ? (parent.width - parent.spacing) * .44 : parent.width) : 0
                    height: parent.height
                    radius: Design.radiusMd
                    visible: controller.widgetEnabled("clock")

                    Column {
                        anchors.centerIn: parent
                        spacing: 0

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: controller.formattedDate("HH:mm")
                            color: theme.colors.foreground
                            font.family: Design.fontFamily
                            font.pixelSize: Design.fontSizeXl
                            font.weight: Design.fontWeightSemibold
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: controller.formattedDate("dddd")
                            color: theme.colors.foreground
                            font.family: Design.fontFamily
                            font.pixelSize: Design.fontSizeXs
                            font.weight: Design.fontWeightMedium
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: controller.formattedDate(I18n.locale === "pt-BR" ? "dd 'de' MMMM" : "MMMM dd")
                            color: theme.colors.mutedForeground
                            font.family: Design.fontFamily
                            font.pixelSize: 9
                        }
                    }
                }

                Glass {
                    theme: widgetWindow.theme
                    surfaceOpacity: .84
                    width: controller.widgetEnabled("weather") ? parent.width - clockCard.width - (clockCard.visible ? parent.spacing : 0) : 0
                    height: parent.height
                    radius: Design.radiusMd
                    visible: controller.widgetEnabled("weather")

                    Row {
                        anchors.fill: parent
                        anchors.margins: Design.widgetInnerPadding
                        spacing: Design.spacingSm

                        StatusIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: controller.weatherIconName(controller.weather.weatherCode)
                            iconSize: Design.iconLg
                            color: theme.colors.accent
                        }

                        Column {
                            width: parent.width - Design.iconLg - Design.spacingMd
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                width: parent.width
                                text: controller.weather.temperature === null ? "--°" : Math.round(Design.safeNumber(controller.weather.temperature, 0)) + "°C"
                                color: theme.colors.foreground
                                font.family: Design.fontFamily
                                font.pixelSize: Design.fontSizeLg
                                font.weight: Design.fontWeightSemibold
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: controller.weatherCondition(Design.safeNumber(controller.weather.weatherCode, -1))
                                color: theme.colors.foreground
                                font.family: Design.fontFamily
                                font.pixelSize: Design.fontSizeXs
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: Design.safeText(controller.weather.city, I18n.tr("weather.local"))
                                color: theme.colors.mutedForeground
                                font.family: Design.fontFamily
                                font.pixelSize: 9
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }

            DesktopCard {
                theme: widgetWindow.theme
                width: parent.width
                visible: controller.widgetEnabled("system")
                height: visible ? implicitHeight : 0
                iconName: "cpu"
                title: I18n.tr("widgets.system")
                value: Math.round(Design.clamp(controller.system.cpu.percent, 0, 100)) + "% CPU"
                contentHeight: 88

                Row {
                    anchors.fill: parent
                    spacing: Design.spacingSm

                    Rectangle {
                        width: (parent.width - parent.spacing) / 2
                        height: parent.height
                        radius: Design.radiusSm
                        color: theme.colors.surfaceVariant
                        clip: true

                        WidgetHeader {
                            id: cpuHeader
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Design.spacingSm }
                            theme: widgetWindow.theme
                            iconName: "cpu"
                            title: "CPU"
                            value: Math.round(Design.clamp(controller.system.cpu.percent, 0, 100)) + "%"
                        }

                        Sparkline {
                            anchors { left: parent.left; right: parent.right; top: cpuHeader.bottom; bottom: parent.bottom; margins: Design.spacingSm; topMargin: 2 }
                            samples: controller.cpuHistory
                            lineColor: theme.colors.accent
                        }
                    }

                    Rectangle {
                        width: (parent.width - parent.spacing) / 2
                        height: parent.height
                        radius: Design.radiusSm
                        color: theme.colors.surfaceVariant
                        clip: true

                        WidgetHeader {
                            id: memoryHeader
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Design.spacingSm }
                            theme: widgetWindow.theme
                            iconName: "memory"
                            title: "RAM"
                            value: Math.round(Design.clamp(controller.system.memory.percent, 0, 100)) + "%"
                            iconColor: theme.colors.secondary
                        }

                        Sparkline {
                            anchors { left: parent.left; right: parent.right; top: memoryHeader.bottom; bottom: parent.bottom; margins: Design.spacingSm; topMargin: 2 }
                            samples: controller.memoryHistory
                            lineColor: theme.colors.secondary
                        }
                    }
                }
            }

            DesktopCard {
                theme: widgetWindow.theme
                width: parent.width
                visible: controller.widgetEnabled("network")
                height: visible ? implicitHeight : 0
                iconName: "networkSpeed"
                title: I18n.tr("widgets.network")
                value: controller.networkLabel()
                contentHeight: 110

                Column {
                    anchors.fill: parent
                    spacing: Design.spacingSm

                    Row {
                        width: parent.width
                        height: 51
                        spacing: Design.spacingSm
                        StatusIcon { name: "networkDownload"; color: theme.colors.accent; iconSize: Design.iconSm; anchors.verticalCenter: parent.verticalCenter }
                        Column {
                            width: 86
                            anchors.verticalCenter: parent.verticalCenter
                            Text { text: I18n.tr("widgets.download"); color: theme.colors.mutedForeground; font.family: Design.fontFamily; font.pixelSize: 9 }
                            Text { text: controller.formatRate(controller.system.network.receiveKib); color: theme.colors.foreground; font.family: Design.fontFamily; font.pixelSize: Design.fontSizeXs; font.weight: Design.fontWeightSemibold }
                        }
                        Sparkline { width: parent.width - 124; height: parent.height; samples: controller.downloadHistory; maximum: widgetWindow.historyPeak(controller.downloadHistory); lineColor: theme.colors.accent }
                    }

                    Row {
                        width: parent.width
                        height: 51
                        spacing: Design.spacingSm
                        StatusIcon { name: "networkUpload"; color: theme.colors.secondary; iconSize: Design.iconSm; anchors.verticalCenter: parent.verticalCenter }
                        Column {
                            width: 86
                            anchors.verticalCenter: parent.verticalCenter
                            Text { text: I18n.tr("widgets.upload"); color: theme.colors.mutedForeground; font.family: Design.fontFamily; font.pixelSize: 9 }
                            Text { text: controller.formatRate(controller.system.network.transmitKib); color: theme.colors.foreground; font.family: Design.fontFamily; font.pixelSize: Design.fontSizeXs; font.weight: Design.fontWeightSemibold }
                        }
                        Sparkline { width: parent.width - 124; height: parent.height; samples: controller.uploadHistory; maximum: widgetWindow.historyPeak(controller.uploadHistory); lineColor: theme.colors.secondary }
                    }
                }
            }

            DesktopCard {
                theme: widgetWindow.theme
                width: parent.width
                visible: controller.widgetEnabled("storage") && controller.monitoring.storage.available
                height: visible ? implicitHeight : 0
                iconName: "storage"
                title: I18n.tr("widgets.storage")
                contentHeight: Math.max(38, storageRepeater.count * 42)

                Column {
                    anchors.fill: parent
                    spacing: Design.spacingXs

                    Repeater {
                        id: storageRepeater
                        model: controller.monitoring.storage.mounts || []

                        Column {
                            required property var modelData
                            width: parent.width
                            height: 38
                            spacing: 3
                            Row {
                                width: parent.width
                                Text { width: parent.width * .24; text: Design.safeText(modelData.mount, "/"); color: theme.colors.foreground; font.family: Design.fontFamily; font.pixelSize: Design.fontSizeXs; font.weight: Design.fontWeightSemibold }
                                Text { width: parent.width * .76; horizontalAlignment: Text.AlignRight; text: controller.formatBytes(modelData.usedBytes) + " / " + controller.formatBytes(modelData.totalBytes) + "  ·  " + Math.round(Design.clamp(modelData.percent, 0, 100)) + "%"; color: modelData.percent >= 92 ? theme.colors.error : modelData.percent >= 80 ? theme.colors.warning : theme.colors.mutedForeground; font.family: Design.fontFamily; font.pixelSize: 9 }
                            }
                            Rectangle {
                                width: parent.width
                                height: 4
                                radius: Design.radiusSmall
                                color: theme.colors.surfaceVariant
                                Rectangle { width: parent.width * Design.clamp(modelData.percent, 0, 100) / 100; height: parent.height; radius: parent.radius; color: modelData.percent >= 92 ? theme.colors.error : modelData.percent >= 80 ? theme.colors.warning : theme.colors.accent }
                            }
                        }
                    }
                }
            }
        }

        Column {
            id: secondaryColumn
            width: widgetWindow.cardWidth
            spacing: Design.spacingSm

            DesktopCard {
                theme: widgetWindow.theme
                width: parent.width
                visible: controller.widgetEnabled("uptime") && controller.monitoring.systemInfo.available
                height: visible ? implicitHeight : 0
                iconName: "uptime"
                title: I18n.tr("widgets.system")
                contentHeight: systemRows.count * Design.widgetDataRowHeight

                Column {
                    anchors.fill: parent

                    Repeater {
                        id: systemRows
                        model: [
                            { label: I18n.tr("widgets.kernel"), value: controller.monitoring.systemInfo.kernel },
                            { label: I18n.tr("widgets.uptime"), value: controller.formatUptime(controller.monitoring.uptime.uptimeSeconds) },
                            { label: I18n.tr("widgets.lastSnapshot"), value: controller.snapshotAgeText() },
                            { label: I18n.tr("widgets.session"), value: controller.monitoring.systemInfo.session },
                            { label: I18n.tr("widgets.updates"), value: controller.updateCountText() }
                        ]

                        WidgetInfoRow {
                            required property var modelData
                            width: parent.width
                            height: Design.widgetDataRowHeight
                            theme: widgetWindow.theme
                            label: modelData.label
                            value: modelData.value
                        }
                    }
                }
            }

            DesktopCard {
                theme: widgetWindow.theme
                width: parent.width
                visible: widgetWindow.hasSensors
                height: visible ? implicitHeight : 0
                iconName: "temperature"
                title: I18n.tr("widgets.sensors")
                contentHeight: Math.max(Design.widgetDataRowHeight, sensorRepeater.count * Design.widgetDataRowHeight)

                Column {
                    anchors.fill: parent
                    Repeater {
                        id: sensorRepeater
                        model: (controller.monitoring.sensors.items || []).slice(0, widgetWindow.compactViewport ? 2 : 4)
                        WidgetInfoRow {
                            required property var modelData
                            width: parent.width
                            height: Design.widgetDataRowHeight
                            theme: widgetWindow.theme
                            label: Design.safeText(modelData.label, I18n.tr("widgets.temperature"))
                            value: Math.round(Design.safeNumber(modelData.celsius, 0)) + "°C"
                            labelWidth: parent.width - 68
                            labelColor: theme.colors.foreground
                            valueColor: modelData.celsius >= 90 ? theme.colors.error : modelData.celsius >= 78 ? theme.colors.warning : theme.colors.accent
                        }
                    }
                }
            }

            DesktopCard {
                theme: widgetWindow.theme
                width: parent.width
                visible: widgetWindow.hasServices
                height: visible ? implicitHeight : 0
                iconName: "services"
                title: I18n.tr("widgets.services")
                value: controller.monitoring.services.healthy ? I18n.tr("widgets.healthy") : I18n.tr("widgets.attention")
                contentHeight: controller.monitoring.services.healthy ? 28 : Math.max(28, serviceRepeater.count * 27)

                Column {
                    anchors.fill: parent

                    Text {
                        visible: controller.monitoring.services.healthy
                        width: parent.width
                        height: parent.height
                        text: I18n.tr("widgets.servicesHealthy")
                        color: theme.colors.mutedForeground
                        font.family: Design.fontFamily
                        font.pixelSize: Design.fontSizeXs
                        verticalAlignment: Text.AlignVCenter
                    }

                    Repeater {
                        id: serviceRepeater
                        model: controller.monitoring.services.healthy ? [] : (controller.monitoring.services.items || []).filter(item => item.state !== "running")
                        WidgetInfoRow {
                            required property var modelData
                            width: parent.width
                            height: 27
                            theme: widgetWindow.theme
                            label: controller.serviceName(modelData)
                            value: controller.serviceStateText(modelData.state)
                            labelWidth: parent.width - 108
                            labelColor: theme.colors.foreground
                            valueColor: modelData.state === "failed" ? theme.colors.error : theme.colors.warning
                        }
                    }
                }
            }

            DesktopCard {
                theme: widgetWindow.theme
                width: parent.width
                visible: widgetWindow.hasTasks
                height: visible ? implicitHeight : 0
                iconName: "tasks"
                title: I18n.tr("widgets.tasks")
                value: controller.tasks.length === 1 ? I18n.tr("widgets.activeOne") : I18n.tr("widgets.activeMany", { count: controller.tasks.length })
                contentHeight: Math.min(widgetWindow.visibleTaskLimit, controller.tasks.length) * 58

                Column {
                    anchors.fill: parent
                    spacing: Design.spacingXs
                    Repeater {
                        model: controller.tasks.slice(0, widgetWindow.visibleTaskLimit)
                        Column {
                            required property var modelData
                            width: parent.width
                            height: 54
                            spacing: 3
                            Row {
                                width: parent.width
                                Text { width: parent.width - 52; text: Design.safeText(modelData.title, I18n.tr("widgets.task")); color: theme.colors.foreground; font.family: Design.fontFamily; font.pixelSize: Design.fontSizeXs; font.weight: Design.fontWeightSemibold; elide: Text.ElideRight }
                                Text { width: 52; horizontalAlignment: Text.AlignRight; text: modelData.indeterminate ? "…" : Math.round(Design.clamp(modelData.progress, 0, 100)) + "%"; color: modelData.status === "failed" ? theme.colors.error : theme.colors.accent; font.family: Design.fontFamily; font.pixelSize: Design.fontSizeXs }
                            }
                            Rectangle {
                                width: parent.width
                                height: 4
                                radius: Design.radiusSmall
                                color: theme.colors.surfaceVariant
                                Rectangle { width: modelData.indeterminate ? parent.width * .35 : parent.width * Design.clamp(modelData.progress, 0, 100) / 100; height: parent.height; radius: parent.radius; color: modelData.status === "failed" ? theme.colors.error : theme.colors.accent }
                            }
                            Text { width: parent.width; text: modelData.eta > 0 ? I18n.tr("widgets.remaining", { minutes: Math.ceil(modelData.eta / 60) }) : Design.safeText(modelData.subtitle, I18n.tr("widgets.inProgress")); color: theme.colors.mutedForeground; font.family: Design.fontFamily; font.pixelSize: 9; elide: Text.ElideRight }
                        }
                    }
                }
            }

            DesktopCard {
                theme: widgetWindow.theme
                width: parent.width
                visible: controller.widgetEnabled("processes") && controller.monitoring.processes.available
                height: visible ? implicitHeight : 0
                iconName: "processes"
                title: I18n.tr("widgets.processes")
                value: controller.monitoring.uptime.processCount > 0 ? I18n.tr("widgets.activeMany", { count: controller.monitoring.uptime.processCount }) : ""
                contentHeight: 34 + widgetWindow.visibleProcessLimit * 28

                Row {
                    anchors.fill: parent
                    spacing: Design.spacingMd

                    Column {
                        width: (parent.width - parent.spacing) / 2
                        height: parent.height
                        spacing: 3
                        Text { text: "CPU"; color: theme.colors.accent; font.family: Design.fontFamily; font.pixelSize: Design.fontSizeXs; font.weight: Design.fontWeightSemibold }
                        Repeater {
                            model: (controller.monitoring.processes.cpu || []).slice(0, widgetWindow.visibleProcessLimit)
                            WidgetInfoRow {
                                required property var modelData
                                width: parent.width
                                height: 28
                                theme: widgetWindow.theme
                                label: Design.safeText(modelData.name, I18n.tr("widgets.process"))
                                value: Math.round(Design.safeNumber(modelData.cpuPercent, 0)) + "%"
                                labelWidth: parent.width - 50
                                fontSize: 9
                                labelColor: theme.colors.foreground
                                valueColor: theme.colors.mutedForeground
                            }
                        }
                    }

                    Column {
                        width: (parent.width - parent.spacing) / 2
                        height: parent.height
                        spacing: 3
                        Text { text: I18n.tr("widgets.memory"); color: theme.colors.secondary; font.family: Design.fontFamily; font.pixelSize: Design.fontSizeXs; font.weight: Design.fontWeightSemibold }
                        Repeater {
                            model: (controller.monitoring.processes.memory || []).slice(0, widgetWindow.visibleProcessLimit)
                            WidgetInfoRow {
                                required property var modelData
                                width: parent.width
                                height: 28
                                theme: widgetWindow.theme
                                label: Design.safeText(modelData.name, I18n.tr("widgets.process"))
                                value: controller.formatBytes(modelData.memoryBytes)
                                labelWidth: parent.width - 66
                                fontSize: 9
                                labelColor: theme.colors.foreground
                                valueColor: theme.colors.mutedForeground
                            }
                        }
                    }
                }
            }

            Glass {
                theme: widgetWindow.theme
                surfaceOpacity: .88
                width: parent.width
                height: visible ? 112 : 0
                radius: Design.radiusMd
                visible: controller.widgetEnabled("media") && controller.mediaAvailable()

                Row {
                    anchors.fill: parent
                    anchors.margins: Design.widgetInnerPadding
                    spacing: Design.spacingMd

                    Rectangle {
                        width: 86
                        height: 86
                        anchors.verticalCenter: parent.verticalCenter
                        radius: Design.radiusSm
                        color: theme.colors.surfaceVariant
                        clip: true

                        RoundedImage { id: mediaArt; anchors.fill: parent; source: controller.mediaArtUrl(); fillMode: Image.PreserveAspectCrop; asynchronous: true; cache: true; radius: parent.radius }
                        ShellIcon { anchors.centerIn: parent; visible: mediaArt.status !== Image.Ready; name: controller.applicationIcon(controller.mediaPlayer ? controller.mediaPlayer.desktopEntry : ""); fallback: "application-x-executable"; fallbackGlyph: "media"; iconSize: 42 }
                    }

                    Column {
                        width: parent.width - 98
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Design.spacingXs
                        Text { width: parent.width; text: controller.mediaTitle(); elide: Text.ElideRight; color: theme.colors.foreground; font.family: Design.fontFamily; font.pixelSize: Design.fontSizeSm; font.weight: Design.fontWeightSemibold }
                        Text { width: parent.width; text: controller.mediaArtist(); elide: Text.ElideRight; color: theme.colors.mutedForeground; font.family: Design.fontFamily; font.pixelSize: Design.fontSizeXs }
                        Rectangle { width: parent.width; height: 4; radius: Design.radiusSmall; color: theme.colors.surfaceVariant; Rectangle { width: parent.width * controller.mediaProgress(); height: parent.height; radius: parent.radius; color: theme.colors.accent } }
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: Design.spacingXs
                            ShellButton { theme: widgetWindow.theme; compact: true; iconName: "previous"; onClicked: controller.mediaPrevious() }
                            ShellButton { theme: widgetWindow.theme; compact: true; iconName: controller.mediaPlayer && controller.mediaPlayer.isPlaying ? "pause" : "play"; onClicked: controller.mediaToggle() }
                            ShellButton { theme: widgetWindow.theme; compact: true; iconName: "next"; onClicked: controller.mediaNext() }
                        }
                    }
                }
            }
        }
    }
}
