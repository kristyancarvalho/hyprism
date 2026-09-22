import QtQuick
import QtQuick.Layouts
import "../components"
import ".."

FocusScope {
    id: panel
    required property var controller
    required property var theme
    property string feedback: ""
    readonly property var schedule: controller.config.appearance.schedule || ({})
    readonly property int appearanceIndex: schedule.enabled ? 0 : controller.lightTheme ? 1 : 2

    function validTime(value) {
        const match = /^(\d{2}):(\d{2})$/.exec(value)
        return match && Number(match[1]) < 24 && Number(match[2]) < 60
    }

    function saveSchedule() {
        feedback = ""
        if (!validTime(lightStart.text) || !validTime(darkStart.text)) {
            feedback = I18n.tr("themeSettings.invalidTime")
            return
        }
        if (lightStart.text === darkStart.text) {
            feedback = I18n.tr("themeSettings.sameTime")
            return
        }
        controller.setThemeSchedule(lightStart.text, darkStart.text, true)
        feedback = I18n.tr("themeSettings.saved")
    }

    function takeInitialFocus() {
        appearance.forceActiveFocus(Qt.ShortcutFocusReason)
    }

    function initialFocusReady() {
        return appearance.activeFocus || temperature.activeFocus || opacity.activeFocus || corners.activeFocus || resetButton.activeFocus || lightStart.inputActiveFocus || darkStart.inputActiveFocus
    }

    focus: true
    Keys.onEscapePressed: event => {
        controller.close()
        event.accepted = true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Design.spacingLg
        spacing: Design.spacingSm

        RowLayout {
            Layout.fillWidth: true
            spacing: Design.spacingSm

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Design.spacingXs

                Text {
                    Layout.fillWidth: true
                    text: I18n.tr("themeSettings.title")
                    color: panel.theme.colors.foreground
                    font.family: Design.fontFamily
                    font.pixelSize: Design.fontSizeLg
                    font.weight: Design.fontWeightSemibold
                }

                Text {
                    Layout.fillWidth: true
                    text: I18n.tr("themeSettings.description")
                    color: panel.theme.colors.mutedForeground
                    font.family: Design.fontFamily
                    font.pixelSize: Design.fontSizeSm
                }
            }

            ShellButton {
                theme: panel.theme
                iconName: "close"
                compact: true
                onClicked: panel.controller.close()
            }
        }

        DiscreteLevelPill {
            id: appearance
            Layout.fillWidth: true
            theme: panel.theme
            label: I18n.tr("themeSettings.appearance")
            iconName: "lightTheme"
            options: [I18n.tr("themeSettings.auto"), I18n.tr("themeSettings.light"), I18n.tr("themeSettings.dark")]
            value: panel.appearanceIndex
            onChanged: value => panel.controller.setAppearanceMode(["auto", "light", "dark"][value])
        }

        RowLayout {
            Layout.fillWidth: true
            visible: panel.schedule.enabled === true
            enabled: visible
            spacing: Design.spacingSm

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Design.spacingXs

                Text {
                    text: I18n.tr("themeSettings.lightStart")
                    color: panel.theme.colors.mutedForeground
                    font.family: Design.fontFamily
                    font.pixelSize: Design.fontSizeXs
                }

                SearchField {
                    id: lightStart
                    Layout.fillWidth: true
                    theme: panel.theme
                    text: Design.safeText(panel.schedule.lightStart, "07:00")
                    iconName: "lightTheme"
                    placeholderText: "07:00"
                    clearButtonEnabled: false
                    tabTarget: darkStart
                    backtabTarget: appearance
                    onKeyPressed: event => {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            panel.saveSchedule()
                            event.accepted = true
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Design.spacingXs

                Text {
                    text: I18n.tr("themeSettings.darkStart")
                    color: panel.theme.colors.mutedForeground
                    font.family: Design.fontFamily
                    font.pixelSize: Design.fontSizeXs
                }

                SearchField {
                    id: darkStart
                    Layout.fillWidth: true
                    theme: panel.theme
                    text: Design.safeText(panel.schedule.darkStart, "18:00")
                    iconName: "night"
                    placeholderText: "18:00"
                    clearButtonEnabled: false
                    tabTarget: saveButton
                    backtabTarget: lightStart
                    onKeyPressed: event => {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            panel.saveSchedule()
                            event.accepted = true
                        }
                    }
                }
            }

            ShellButton {
                id: saveButton
                Layout.alignment: Qt.AlignBottom
                theme: panel.theme
                text: I18n.tr("themeSettings.save")
                compact: true
                iconName: "check"
                onClicked: panel.saveSchedule()
            }
        }

        Text {
            Layout.fillWidth: true
            visible: panel.schedule.enabled && panel.feedback.length > 0
            text: panel.feedback
            color: panel.feedback === I18n.tr("themeSettings.saved") ? panel.theme.colors.accent : panel.theme.colors.error
            font.family: Design.fontFamily
            font.pixelSize: Design.fontSizeXs
            elide: Text.ElideRight
        }

        DiscreteLevelPill {
            id: temperature
            Layout.fillWidth: true
            theme: panel.theme
            label: I18n.tr("themeSettings.whiteTemperature")
            iconName: "whiteTemperature"
            options: [I18n.tr("themeSettings.temperatureNeutral"), I18n.tr("themeSettings.temperatureSoft"), I18n.tr("themeSettings.temperatureWarm"), I18n.tr("themeSettings.temperatureAmber")]
            value: panel.controller.whiteTemperature
            onChanged: value => panel.controller.setWhiteTemperature(value)
        }

        DiscreteLevelPill {
            id: opacity
            Layout.fillWidth: true
            theme: panel.theme
            label: I18n.tr("themeSettings.surfaceOpacity")
            iconName: "brightness"
            options: [I18n.tr("themeSettings.opacitySolid"), I18n.tr("themeSettings.opacitySoft"), I18n.tr("themeSettings.opacityGlass"), I18n.tr("themeSettings.opacityAiry")]
            value: panel.controller.surfaceOpacityIndex
            onChanged: value => panel.controller.setSurfaceOpacityPreset(value)
        }

        DiscreteLevelPill {
            id: corners
            Layout.fillWidth: true
            theme: panel.theme
            label: I18n.tr("themeSettings.cornerRadius")
            iconName: "settings"
            options: [I18n.tr("themeSettings.radiusSharp"), I18n.tr("themeSettings.radiusDefault"), I18n.tr("themeSettings.radiusSoft"), I18n.tr("themeSettings.radiusRound")]
            value: panel.controller.cornerRadiusPreset
            onChanged: value => panel.controller.setCornerRadiusPreset(value)
        }

        ShellButton {
            id: resetButton
            Layout.fillWidth: true
            theme: panel.theme
            text: I18n.tr("themeSettings.reset")
            iconName: "refresh"
            onClicked: panel.controller.resetThemeSettings()
        }
    }
}
