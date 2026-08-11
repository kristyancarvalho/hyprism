import QtQuick
import "../components"

Glass {
    id: osd
    required property var controller
    property bool percentageValue: /^\d+%?$/.test(controller.osdValue)
    property string iconName: controller.osdKind === "Volume" ? controller.volumeIconName() : controller.osdKind === "Brilho" ? "display-brightness" : controller.osdKind === "Microfone" ? controller.microphoneIconName() : controller.osdKind === "Captura" ? "camera-photo" : controller.osdKind === "Cor" ? "color-select" : controller.osdKind === "Modo noturno" ? "weather-clear-night" : "preferences-system"
    width: 320; height: 58; radius: 20; surfaceOpacity: .96
    visible: controller.osdKind.length > 0
    opacity: visible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 130 } }
    Row { anchors.fill: parent; anchors.margins: 14; spacing: 10
        ShellIcon { anchors.verticalCenter: parent.verticalCenter; name: osd.iconName; iconSize: 22; framed: true; frameColor: theme.colors.surfaceVariant }
        Text { text: controller.osdKind; color: theme.colors.foreground; width: osd.percentageValue ? 92 : 118; anchors.verticalCenter: parent.verticalCenter; font { pixelSize: 12; weight: Font.Medium } }
        Rectangle { visible: osd.percentageValue; width: 112; height: 5; radius: 3; anchors.verticalCenter: parent.verticalCenter; color: theme.colors.surfaceVariant
            Rectangle { width: Math.min(parent.width, (parseInt(controller.osdValue) || 100) * parent.width / 100); height: parent.height; radius: 3; color: theme.colors.accent }
        }
        Text { width: osd.percentageValue ? 38 : 122; text: controller.osdValue; elide: Text.ElideRight; color: theme.colors.foreground; anchors.verticalCenter: parent.verticalCenter; font.pixelSize: 11 }
    }
}
