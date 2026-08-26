import QtQuick
import QtQuick.Controls
import ".."

Item {
    id: row
    property var theme
    property string label: ""
    property string iconName: "settings"
    property int value: 0
    property bool available: true
    readonly property bool controlFocused: slider.activeFocus
    signal changed(int value)
    signal focusEntered()
    implicitHeight: 64
    visible: available

    function takeFocus() {
        slider.forceActiveFocus()
    }

    Rectangle {
        anchors.fill: parent
        radius: Design.radiusSm
        color: "transparent"
        border.width: 0
    }

    Column {
        anchors.fill: parent
        anchors.margins: 7
        spacing: 5

        Row {
            width: parent.width
            height: 24
            spacing: 8

            StatusIcon {
                width: 24
                height: 24
                name: row.iconName
                iconSize: Design.iconSm
                color: row.theme.colors.foreground
            }

            Text {
                width: parent.width - percentage.width - 38
                height: 24
                text: Design.safeText(row.label, I18n.tr("common.unavailable"))
                color: row.theme.colors.foreground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeSm
                font.weight: Design.fontWeightMedium
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                id: percentage
                height: 24
                text: Math.round(Design.clamp(slider.value, 0, 100)) + "%"
                color: row.theme.colors.mutedForeground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeXs
                verticalAlignment: Text.AlignVCenter
            }
        }

        Slider {
            id: slider
            width: parent.width
            height: 21
            activeFocusOnTab: true
            from: 0
            to: 100
            value: Design.clamp(row.value, 0, 100)
            stepSize: 2
            onMoved: row.changed(Math.round(value))
            onActiveFocusChanged: if (activeFocus) row.focusEntered()
            Keys.onPressed: event => {
                const increment = event.modifiers & Qt.ShiftModifier ? 10 : 2
                if (event.key === Qt.Key_Left) {
                    value = Math.max(0, Math.round(value) - increment)
                    row.changed(Math.round(value))
                    event.accepted = true
                } else if (event.key === Qt.Key_Right) {
                    value = Math.min(100, Math.round(value) + increment)
                    row.changed(Math.round(value))
                    event.accepted = true
                }
            }
            background: Rectangle {
                x: slider.leftPadding
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: slider.availableWidth
                height: 5
                radius: Design.radiusSmall
                color: row.theme.colors.surfaceVariant

                Rectangle {
                    width: slider.visualPosition * parent.width
                    height: parent.height
                    radius: Design.radiusSmall
                    color: row.theme.colors.accent
                }
            }
            handle: Rectangle {
                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: slider.activeFocus ? 15 : 13
                height: width
                radius: Design.radiusDefault
                color: slider.activeFocus ? row.theme.colors.accent : row.theme.colors.foreground
            }
        }
    }
}
