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
    readonly property int columnGap: Design.desktopWidgetColumnGap
    readonly property int cardGap: Design.desktopWidgetGap
    readonly property bool hasClockRow: controller.widgetEnabled("clock") || controller.widgetEnabled("weather")
    readonly property bool hasSensors: controller.widgetEnabled("sensors") && controller.monitoring.sensors.available
    readonly property bool hasServices: controller.widgetEnabled("services") && controller.monitoring.services.available && (!controller.widgetConfig("services").problemOnly || !controller.monitoring.services.healthy)
    readonly property bool hasTasks: controller.widgetEnabled("tasks") && controller.tasks.length > 0
    readonly property var serviceProblems: (controller.monitoring.services.items || []).filter(item => item.state !== "running")
    readonly property var visibleSensors: (controller.monitoring.sensors.items || []).slice(0, compactViewport ? 2 : 5)
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

    function sensorThresholds(item) {
        return [
            Design.safeNumber(item ? item.warmCelsius : 60, 60),
            Design.safeNumber(item ? item.hotCelsius : 75, 75),
            Design.safeNumber(item ? item.criticalCelsius : 90, 90)
        ]
    }

    function sensorColor(item) {
        const temperature = Design.safeNumber(item ? item.celsius : 0, 0)
        const thresholds = sensorThresholds(item)
        if (temperature >= thresholds[2]) return theme.colors.error
        if (temperature >= thresholds[1]) return theme.colors.warning
        if (temperature >= thresholds[0]) return theme.colors.accent
        return theme.colors.mutedForeground
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
            spacing: widgetWindow.cardGap

            Row {
                width: parent.width
                height: visible ? 84 : 0
                spacing: widgetWindow.cardGap
                visible: widgetWindow.hasClockRow

                Behavior on height { NumberAnimation { duration: Design.animationMorph; easing.type: Design.easingMorph } }

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
                        spacing: 2

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
                            text: controller.formattedDate(I18n.locale === "pt-BR" ? "dddd · dd MMMM" : "dddd · MMMM dd")
                            color: theme.colors.mutedForeground
                            font.family: Design.fontFamily
                            font.pixelSize: 9
                            font.weight: Design.fontWeightMedium
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
                iconName: "performance"
                title: I18n.tr("widgets.performance")
                contentHeight: 82

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
                contentHeight: 68

                Column {
                    anchors.fill: parent
                    spacing: Design.spacingXs

                    WidgetSparklineRow {
                        width: parent.width
                        theme: widgetWindow.theme
                        iconName: "networkDownload"
                        label: I18n.tr("widgets.download")
                        value: controller.formatRate(controller.system.network.receiveKib)
                        samples: controller.downloadHistory
                        maximum: widgetWindow.historyPeak(controller.downloadHistory)
                        lineColor: theme.colors.accent
                    }

                    WidgetSparklineRow {
                        width: parent.width
                        theme: widgetWindow.theme
                        iconName: "networkUpload"
                        label: I18n.tr("widgets.upload")
                        value: controller.formatRate(controller.system.network.transmitKib)
                        samples: controller.uploadHistory
                        maximum: widgetWindow.historyPeak(controller.uploadHistory)
                        lineColor: theme.colors.secondary
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
                contentHeight: Math.max(46, storageRepeater.count * 50)

                Column {
                    anchors.fill: parent
                    spacing: Design.spacingXs

                    Repeater {
                        id: storageRepeater
                        model: controller.monitoring.storage.mounts || []

                        Column {
                            required property var modelData
                            width: parent.width
                            height: 46
                            spacing: 3
                            Row {
                                width: parent.width
                                Text { width: parent.width * .3; text: controller.storageName(modelData.mount); color: theme.colors.foreground; font.family: Design.fontFamily; font.pixelSize: Design.fontSizeXs; font.weight: Design.fontWeightSemibold; elide: Text.ElideRight }
                                Text { width: parent.width * .7; horizontalAlignment: Text.AlignRight; text: controller.formatBytes(modelData.usedBytes) + " / " + controller.formatBytes(modelData.totalBytes) + "  ·  " + Math.round(Design.clamp(modelData.percent, 0, 100)) + "%"; color: modelData.percent >= 92 ? theme.colors.error : modelData.percent >= 80 ? theme.colors.warning : theme.colors.mutedForeground; font.family: Design.fontFamily; font.pixelSize: 9; elide: Text.ElideRight }
                            }
                            Text { width: parent.width; text: controller.storageMountLabel(modelData.mount); color: theme.colors.mutedForeground; font.family: Design.fontFamily; font.pixelSize: 9; elide: Text.ElideMiddle }
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
            spacing: widgetWindow.cardGap

            DesktopCard {
                id: systemInfoCard
                theme: widgetWindow.theme
                width: parent.width
                visible: controller.widgetEnabled("uptime") && controller.monitoring.systemInfo.available
                height: visible ? implicitHeight : 0
                iconName: "uptime"
                title: I18n.tr("widgets.system")
                property var detailItems: controller.systemInfoDetails()
                contentHeight: 35 + (detailItems.length > 0 ? Design.spacingSm + Math.ceil(detailItems.length / 2) * 39 : 0)

                Column {
                    anchors.fill: parent
                    spacing: 2

                    Text {
                        width: parent.width
                        text: I18n.tr("widgets.kernel")
                        color: theme.colors.mutedForeground
                        font.family: Design.fontFamily
                        font.pixelSize: 9
                    }

                    Text {
                        width: parent.width
                        text: controller.monitoring.systemInfo.kernel
                        color: theme.colors.foreground
                        font.family: Design.fontFamily
                        font.pixelSize: Design.fontSizeSm
                        font.weight: Design.fontWeightSemibold
                        elide: Text.ElideRight
                    }

                    Grid {
                        width: parent.width
                        columns: 2
                        columnSpacing: Design.spacingMd
                        rowSpacing: 3
                        topPadding: Design.spacingSm - 2

                        Repeater {
                            model: systemInfoCard.detailItems

                            Column {
                                required property var modelData
                                width: (systemInfoCard.width - Design.widgetInnerPadding * 2 - Design.spacingMd) / 2
                                height: 36
                                spacing: 1

                                Text {
                                    width: parent.width
                                    text: modelData.label
                                    color: theme.colors.mutedForeground
                                    font.family: Design.fontFamily
                                    font.pixelSize: 9
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: modelData.value
                                    color: theme.colors.foreground
                                    font.family: Design.fontFamily
                                    font.pixelSize: Design.fontSizeXs
                                    font.weight: Design.fontWeightSemibold
                                    elide: Text.ElideRight
                                }
                            }
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
                contentHeight: Math.max(Design.widgetDataRowHeight, widgetWindow.visibleSensors.length * Design.widgetDataRowHeight)

                Column {
                    anchors.fill: parent
                    Repeater {
                        id: sensorRepeater
                        model: widgetWindow.visibleSensors
                        WidgetInfoRow {
                            required property var modelData
                            width: parent.width
                            height: Design.widgetDataRowHeight
                            theme: widgetWindow.theme
                            label: controller.sensorName(modelData)
                            value: Math.round(Design.safeNumber(modelData.celsius, 0)) + "°C"
                            labelWidth: parent.width - 68
                            labelColor: theme.colors.foreground
                            valueColor: widgetWindow.sensorColor(modelData)
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
                value: controller.monitoring.services.healthy
                    ? (controller.monitoring.services.items.length === 1 ? I18n.tr("widgets.monitoredOne") : I18n.tr("widgets.monitoredMany", { count: controller.monitoring.services.items.length })) + " · " + I18n.tr("widgets.healthy")
                    : (widgetWindow.serviceProblems.length === 1 ? I18n.tr("widgets.issueOne") : I18n.tr("widgets.issueMany", { count: widgetWindow.serviceProblems.length }))
                contentHeight: controller.monitoring.services.healthy ? 0 : Math.max(28, serviceRepeater.count * 28)

                Column {
                    anchors.fill: parent
                    Repeater {
                        id: serviceRepeater
                        model: controller.monitoring.services.healthy ? [] : widgetWindow.serviceProblems
                        WidgetInfoRow {
                            required property var modelData
                            width: parent.width
                            height: 28
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
