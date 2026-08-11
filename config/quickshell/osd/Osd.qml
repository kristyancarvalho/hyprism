import QtQuick
import "../components"

Glass {
    id: osd
    required property var controller
    width: 290; height: 54; radius: 18; surfaceOpacity: .96
    visible: controller.osdKind.length > 0
    opacity: visible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 130 } }
    Row { anchors.fill: parent; anchors.margins: 14; spacing: 10
        Text { text: controller.osdKind === "Volume" ? "◖" : controller.osdKind === "Brilho" ? "☼" : "◈"; color: theme.colors.accent; font.pixelSize: 18 }
        Text { text: controller.osdKind; color: theme.colors.foreground; width: 92; anchors.verticalCenter: parent.verticalCenter; font.pixelSize: 12 }
        Rectangle { width: 112; height: 5; radius: 3; anchors.verticalCenter: parent.verticalCenter; color: theme.colors.surfaceVariant
            Rectangle { width: Math.min(parent.width, (parseInt(controller.osdValue) || 100) * parent.width / 100); height: parent.height; radius: 3; color: theme.colors.accent }
        }
        Text { text: controller.osdValue; color: theme.colors.foreground; anchors.verticalCenter: parent.verticalCenter; font.pixelSize: 11 }
    }
}
