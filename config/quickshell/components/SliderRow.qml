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
    signal changed(int value)
    implicitHeight: 46
    visible: available

    Row {
        anchors.fill: parent
        spacing: 10

        Rectangle {
            width: 30
            height: 30
            anchors.verticalCenter: parent.verticalCenter
            radius: 15
            color: row.theme.colors.surfaceVariant

            StatusIcon {
                anchors.centerIn: parent
                name: row.iconName
                iconSize: Design.iconSm
                color: row.theme.colors.foreground
            }
        }

        Text {
            width: 92
            anchors.verticalCenter: parent.verticalCenter
            text: Design.safeText(row.label, "Indisponível")
            color: row.theme.colors.foreground
            font.family: Design.fontFamily
            font.pixelSize: Design.fontSizeSm
            font.weight: Design.fontWeightMedium
        }

        Slider {
            id: slider
            width: parent.width - 184
            anchors.verticalCenter: parent.verticalCenter
            activeFocusOnTab: true
            from: 0
            to: 100
            value: Design.clamp(row.value, 0, 100)
            stepSize: 2
            onMoved: row.changed(Math.round(value))
            Keys.onLeftPressed: row.changed(Math.max(0, Math.round(value) - 2))
            Keys.onRightPressed: row.changed(Math.min(100, Math.round(value) + 2))
            background: Rectangle {
                x: slider.leftPadding
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: slider.availableWidth
                height: 5
                radius: 3
                color: row.theme.colors.surfaceVariant
                border.width: slider.activeFocus ? 1 : 0
                border.color: row.theme.colors.accent

                Rectangle {
                    width: slider.visualPosition * parent.width
                    height: parent.height
                    radius: 3
                    color: row.theme.colors.accent
                }
            }
            handle: Rectangle {
                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: slider.activeFocus ? 15 : 13
                height: width
                radius: width / 2
                color: slider.activeFocus ? row.theme.colors.accent : row.theme.colors.foreground
            }
        }

        Text {
            width: 34
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(Design.clamp(row.value, 0, 100)) + "%"
            color: row.theme.colors.mutedForeground
            font.family: Design.fontFamily
            font.pixelSize: Design.fontSizeXs
        }
    }
}
