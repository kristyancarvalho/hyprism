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

    function validTime(value) {
        const match = /^(\d{2}):(\d{2})$/.exec(value)
        return match && Number(match[1]) < 24 && Number(match[2]) < 60
    }

    function save(enabled) {
        feedback = ""
        if (!validTime(lightStart.text) || !validTime(darkStart.text)) {
            feedback = I18n.tr("themeSchedule.invalidTime")
            return
        }
        if (lightStart.text === darkStart.text) {
            feedback = I18n.tr("themeSchedule.sameTime")
            return
        }
        controller.setThemeSchedule(lightStart.text, darkStart.text, enabled)
        feedback = I18n.tr("themeSchedule.saved")
    }

    function takeInitialFocus() {
        lightStart.forceInputFocus(Qt.ShortcutFocusReason)
    }

    function initialFocusReady() {
        return lightStart.inputActiveFocus || darkStart.inputActiveFocus || automatic.activeFocus || saveButton.activeFocus
    }

    focus: true
    Keys.onEscapePressed: event => {
        controller.close()
        event.accepted = true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Design.spacingLg
        spacing: Design.spacingMd

        RowLayout {
            Layout.fillWidth: true
            spacing: Design.spacingSm

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Design.spacingXs

                Text {
                    Layout.fillWidth: true
                    text: I18n.tr("themeSchedule.title")
                    color: panel.theme.colors.foreground
                    font.family: Design.fontFamily
                    font.pixelSize: Design.fontSizeLg
                    font.weight: Design.fontWeightSemibold
                }

                Text {
                    Layout.fillWidth: true
                    text: I18n.tr("themeSchedule.description")
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

        RowLayout {
            Layout.fillWidth: true
            spacing: Design.spacingMd

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Design.spacingXs

                Text {
                    text: I18n.tr("themeSchedule.lightStart")
                    color: panel.theme.colors.foreground
                    font.family: Design.fontFamily
                    font.pixelSize: Design.fontSizeSm
                    font.weight: Design.fontWeightMedium
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
                    onKeyPressed: event => {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            panel.save(panel.schedule.enabled === true)
                            event.accepted = true
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Design.spacingXs

                Text {
                    text: I18n.tr("themeSchedule.darkStart")
                    color: panel.theme.colors.foreground
                    font.family: Design.fontFamily
                    font.pixelSize: Design.fontSizeSm
                    font.weight: Design.fontWeightMedium
                }

                SearchField {
                    id: darkStart
                    Layout.fillWidth: true
                    theme: panel.theme
                    text: Design.safeText(panel.schedule.darkStart, "18:00")
                    iconName: "night"
                    placeholderText: "18:00"
                    clearButtonEnabled: false
                    tabTarget: automatic
                    backtabTarget: lightStart
                    onKeyPressed: event => {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            panel.save(panel.schedule.enabled === true)
                            event.accepted = true
                        }
                    }
                }
            }
        }

        ActionButton {
            id: automatic
            Layout.fillWidth: true
            Layout.preferredHeight: 58
            theme: panel.theme
            label: I18n.tr("themeSchedule.automatic")
            iconName: "calendar"
            active: panel.schedule.enabled === true
            KeyNavigation.backtab: darkStart
            KeyNavigation.tab: saveButton
            onClicked: panel.save(panel.schedule.enabled !== true)
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Design.spacingSm

            Text {
                Layout.fillWidth: true
                text: panel.feedback
                color: panel.feedback === I18n.tr("themeSchedule.saved") ? panel.theme.colors.accent : panel.theme.colors.error
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeXs
                elide: Text.ElideRight
            }

            ShellButton {
                id: saveButton
                Layout.preferredWidth: implicitWidth
                theme: panel.theme
                text: I18n.tr("themeSchedule.save")
                iconName: "check"
                KeyNavigation.backtab: automatic
                KeyNavigation.tab: lightStart
                onClicked: panel.save(panel.schedule.enabled === true)
            }
        }
    }
}
