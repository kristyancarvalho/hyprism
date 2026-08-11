import QtQuick
import QtQuick.Controls

Item {
    id: row
    property var theme
    property string label: ""
    property string icon: ""
    property int value: 0
    property bool available: true
    signal changed(int value)
    implicitHeight: 42
    visible: available
    Row {
        anchors.fill: parent; spacing: 10
        Text { width: 24; anchors.verticalCenter: parent.verticalCenter; text: row.icon; color: row.theme.colors.accent; font.pixelSize: 16 }
        Text { width: 84; anchors.verticalCenter: parent.verticalCenter; text: row.label; color: row.theme.colors.foreground; font.pixelSize: 12 }
        Slider {
            id: slider; width: parent.width - 162; anchors.verticalCenter: parent.verticalCenter
            from: 0; to: 100; value: row.value
            onMoved: row.changed(Math.round(value))
            background: Rectangle { x: slider.leftPadding; y: slider.topPadding + slider.availableHeight / 2 - height / 2; width: slider.availableWidth; height: 5; radius: 3; color: row.theme.colors.surfaceVariant; Rectangle { width: slider.visualPosition * parent.width; height: parent.height; radius: 3; color: row.theme.colors.accent } }
            handle: Rectangle { x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width); y: slider.topPadding + slider.availableHeight / 2 - height / 2; width: 13; height: 13; radius: 7; color: row.theme.colors.foreground }
        }
        Text { width: 34; anchors.verticalCenter: parent.verticalCenter; text: row.value + "%"; color: row.theme.colors.mutedForeground; font.pixelSize: 11 }
    }
}
