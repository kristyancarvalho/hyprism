import QtQuick
import "../components"
import ".."

Glass {
    id: osd
    required property var controller
    property bool percentageValue: /^\d+%?$/.test(controller.osdValue)
    property string iconName: controller.osdKind === "Volume" ? controller.volumeIconName() : controller.osdKind === "Brilho" ? "brightness" : controller.osdKind === "Microfone" ? controller.microphoneIconName() : controller.osdKind === "Captura" ? "screenshot" : controller.osdKind === "Cor" ? "colorPicker" : controller.osdKind === "Modo noturno" ? "night" : controller.osdKind === "Economia de energia" ? "powerSaver" : "settings"
    width: 320
    height: 58
    radius: Design.radiusMd
    surfaceOpacity: .96
    visible: controller.osdKind.length > 0
    opacity: visible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 130 } }

    Row {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        Rectangle {
            width: 30
            height: 30
            anchors.verticalCenter: parent.verticalCenter
            radius: 15
            color: theme.colors.surfaceVariant

            StatusIcon { anchors.centerIn: parent; name: osd.iconName; iconSize: Design.iconMd; color: theme.colors.foreground }
        }

        Text {
            text: Design.safeText(controller.osdKind, "Sistema")
            color: theme.colors.foreground
            width: osd.percentageValue ? 92 : 118
            anchors.verticalCenter: parent.verticalCenter
            font.family: Design.fontFamily
            font.pixelSize: Design.fontSizeSm
            font.weight: Design.fontWeightMedium
        }

        Rectangle {
            visible: osd.percentageValue
            width: 112
            height: 5
            radius: 3
            anchors.verticalCenter: parent.verticalCenter
            color: theme.colors.surfaceVariant

            Rectangle {
                width: Design.clamp(parseInt(controller.osdValue), 0, 100) * parent.width / 100
                height: parent.height
                radius: 3
                color: theme.colors.accent
            }
        }

        Text {
            width: osd.percentageValue ? 38 : 122
            text: Design.safeText(controller.osdValue, "Indisponível")
            elide: Text.ElideRight
            color: theme.colors.foreground
            anchors.verticalCenter: parent.verticalCenter
            font.family: Design.fontFamily
            font.pixelSize: Design.fontSizeXs
        }
    }
}
