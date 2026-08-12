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
    screen: shellScreen
    visible: shellScreen !== null
    anchors {
        right: true
        top: true
    }
    margins {
        top: Design.compactReservedHeight(controller.config.shell) + 18
        right: 20
    }
    implicitWidth: shellScreen ? Math.min(360, Math.max(310, shellScreen.width * .34)) : 340
    implicitHeight: stack.implicitHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    Column {
        id: stack
        width: parent.width
        spacing: 10

        Row {
            width: parent.width
            height: 96
            spacing: 10

            Glass {
                id: clockCard
                theme: widgetWindow.theme
                surfaceOpacity: .84
                width: (parent.width - 10) * .44
                height: parent.height
                radius: Design.radiusMd
                visible: controller.config.shell.widgets.clock

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
                        text: controller.formattedDate("dd 'de' MMMM")
                        color: theme.colors.mutedForeground
                        font.family: Design.fontFamily
                        font.pixelSize: 9
                    }
                }
            }

            Glass {
                theme: widgetWindow.theme
                surfaceOpacity: .84
                width: parent.width - clockCard.width - 10
                height: parent.height
                radius: Design.radiusMd
                visible: controller.config.shell.widgets.weather

                Row {
                    anchors.fill: parent
                    anchors.margins: 13
                    spacing: 11

                    StatusIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: controller.weatherIconName(controller.weather.weatherCode)
                        iconSize: 34
                        color: theme.colors.accent
                    }

                    Column {
                        width: parent.width - 48
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0

                        Text {
                            width: parent.width
                            text: controller.weather.temperature === null ? "--°" : Math.round(Design.safeNumber(controller.weather.temperature, 0)) + "°C"
                            color: theme.colors.foreground
                            font.family: Design.fontFamily
                            font.pixelSize: 23
                            font.weight: Design.fontWeightSemibold
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: controller.weatherCondition(Design.safeNumber(controller.weather.weatherCode, -1))
                            color: theme.colors.foreground
                            font.family: Design.fontFamily
                            font.pixelSize: Design.fontSizeXs
                            font.weight: Design.fontWeightMedium
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: Design.safeText(controller.weather.city, "São Paulo")
                            color: theme.colors.mutedForeground
                            font.family: Design.fontFamily
                            font.pixelSize: 9
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            visible: controller.weather.minimum !== null && controller.weather.maximum !== null
                            text: "Mín. " + Math.round(Design.safeNumber(controller.weather.minimum, 0)) + "°  ·  Máx. " + Math.round(Design.safeNumber(controller.weather.maximum, 0)) + "°"
                            color: theme.colors.mutedForeground
                            font.family: Design.fontFamily
                            font.pixelSize: 9
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        Glass {
            theme: widgetWindow.theme
            surfaceOpacity: .84
            width: parent.width
            height: 148
            radius: Design.radiusMd
            visible: controller.config.shell.widgets.system

            Column {
                anchors.fill: parent
                anchors.margins: 13
                spacing: 8

                Row {
                    width: parent.width
                    height: 90
                    spacing: 10

                    Rectangle {
                        id: cpuCard
                        width: (parent.width - 10) / 2
                        height: parent.height
                        radius: Design.radiusSm
                        color: theme.colors.surfaceVariant
                        clip: true

                        WidgetHeader {
                            id: cpuHeader
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: Design.widgetInnerPadding
                            }
                            theme: widgetWindow.theme
                            iconName: "cpu"
                            title: "Processador"
                            value: Math.round(Design.clamp(controller.system.cpu.percent, 0, 100)) + "%"
                            iconColor: theme.colors.accent
                        }

                        Sparkline {
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: cpuHeader.bottom
                                bottom: parent.bottom
                                leftMargin: Design.widgetInnerPadding
                                rightMargin: Design.widgetInnerPadding
                                topMargin: 3
                                bottomMargin: Design.widgetInnerPadding
                            }
                            samples: controller.cpuHistory
                            lineColor: theme.colors.accent
                        }
                    }

                    Rectangle {
                        id: memoryCard
                        width: (parent.width - 10) / 2
                        height: parent.height
                        radius: Design.radiusSm
                        color: theme.colors.surfaceVariant
                        clip: true

                        WidgetHeader {
                            id: memoryHeader
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: Design.widgetInnerPadding
                            }
                            theme: widgetWindow.theme
                            iconName: "memory"
                            title: "Memória"
                            value: Math.round(Design.clamp(controller.system.memory.percent, 0, 100)) + "%"
                            iconColor: theme.colors.secondary
                        }

                        Sparkline {
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: memoryHeader.bottom
                                bottom: parent.bottom
                                leftMargin: Design.widgetInnerPadding
                                rightMargin: Design.widgetInnerPadding
                                topMargin: 3
                                bottomMargin: Design.widgetInnerPadding
                            }
                            samples: controller.memoryHistory
                            lineColor: theme.colors.secondary
                        }
                    }
                }

                Row {
                    width: parent.width
                    height: 24
                    spacing: 12

                    WidgetMetric {
                        visible: controller.system.battery.available
                        theme: widgetWindow.theme
                        iconName: controller.batteryIconName()
                        trailingIconName: controller.batteryCharging() ? "charging" : ""
                        value: controller.batteryText()
                    }

                    WidgetMetric {
                        visible: controller.system.temperature.available
                        theme: widgetWindow.theme
                        iconName: "temperature"
                        value: Math.round(Design.safeNumber(controller.system.temperature.celsius, 0)) + "°C"
                    }

                    WidgetMetric {
                        visible: controller.system.gpu.available
                        theme: widgetWindow.theme
                        iconName: "gpu"
                        value: Math.round(Design.clamp(controller.system.gpu.percent, 0, 100)) + "%"
                    }

                    WidgetMetric {
                        visible: controller.system.network.enabled
                        theme: widgetWindow.theme
                        iconName: "networkSpeed"
                        value: Math.round(Design.safeNumber(controller.system.network.receiveKib, 0)) + " KiB/s"
                    }
                }
            }
        }

        Glass {
            theme: widgetWindow.theme
            surfaceOpacity: .88
            width: parent.width
            height: controller.mediaAvailable() ? 112 : 0
            radius: Design.radiusMd
            visible: height > 0 && controller.config.shell.widgets.media
            activeFocusOnTab: true

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    controller.mediaToggle()
                    event.accepted = true
                } else if (event.key === Qt.Key_Left) {
                    controller.mediaPrevious()
                    event.accepted = true
                } else if (event.key === Qt.Key_Right) {
                    controller.mediaNext()
                    event.accepted = true
                }
            }

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                radius: parent.radius
                border.width: parent.activeFocus ? 2 : 0
                border.color: theme.colors.accent
            }

            Row {
                anchors.fill: parent
                anchors.margins: 13
                spacing: 12

                Rectangle {
                    width: 86
                    height: 86
                    anchors.verticalCenter: parent.verticalCenter
                    radius: Design.radiusSm
                    color: theme.colors.surfaceVariant
                    clip: true

                    Image {
                        id: mediaArt
                        anchors.fill: parent
                        source: controller.mediaArtUrl()
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }

                    ShellIcon {
                        anchors.centerIn: parent
                        visible: mediaArt.status !== Image.Ready
                        name: controller.applicationIcon(controller.mediaPlayer ? controller.mediaPlayer.desktopEntry : "")
                        fallback: "application-x-executable"
                        fallbackGlyph: "media"
                        iconSize: 42
                    }
                }

                Column {
                    width: parent.width - 98
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Text {
                        width: parent.width
                        text: controller.mediaTitle()
                        elide: Text.ElideRight
                        color: theme.colors.foreground
                        font.family: Design.fontFamily
                        font.pixelSize: Design.fontSizeSm
                        font.weight: Design.fontWeightSemibold
                    }

                    Text {
                        width: parent.width
                        text: controller.mediaArtist()
                        elide: Text.ElideRight
                        color: theme.colors.mutedForeground
                        font.family: Design.fontFamily
                        font.pixelSize: Design.fontSizeXs
                    }

                    Rectangle {
                        width: parent.width
                        height: 4
                        radius: Design.radiusSmall
                        color: theme.colors.surfaceVariant

                        Rectangle {
                            width: parent.width * controller.mediaProgress()
                            height: parent.height
                            radius: Design.radiusSmall
                            color: theme.colors.accent
                        }
                    }

                    Row {
                        width: parent.width

                        Text {
                            width: parent.width - duration.width
                            text: Design.formatDuration(controller.mediaPlayer ? controller.mediaPlayer.position : 0)
                            color: theme.colors.mutedForeground
                            font.family: Design.fontFamily
                            font.pixelSize: 9
                        }
                        Text {
                            id: duration
                            text: Design.formatDuration(controller.mediaPlayer ? controller.mediaPlayer.length : 0)
                            color: theme.colors.mutedForeground
                            font.family: Design.fontFamily
                            font.pixelSize: 9
                        }
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 5
                        ShellButton { theme: widgetWindow.theme; compact: true; iconName: "previous"; onClicked: controller.mediaPrevious() }
                        ShellButton { theme: widgetWindow.theme; compact: true; iconName: controller.mediaPlayer && controller.mediaPlayer.isPlaying ? "pause" : "play"; onClicked: controller.mediaToggle() }
                        ShellButton { theme: widgetWindow.theme; compact: true; iconName: "next"; onClicked: controller.mediaNext() }
                    }
                }
            }
        }
    }
}
