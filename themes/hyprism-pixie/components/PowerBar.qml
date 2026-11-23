/**
 * Pixie SDDM - PowerBar Component
 * Author: xCaptaiN09
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Row {
    id: powerBarRoot
    spacing: 20
    height: 30

    property color textColor: "white"
    property color accentColor: "white"
    property color surfaceColor: "black"

    FontLoader { id: iconFont; source: "../assets/fonts/MaterialDesignIcons.ttf" }

    Row {
        id: batteryRow
        spacing: 5
        visible: typeof battery !== "undefined" && typeof battery.percent !== "undefined"
        anchors.verticalCenter: parent.verticalCenter

        Text {
            id: batteryText
            text: (typeof battery !== "undefined" ? battery.percent : "0") + "%"
            color: textColor
            font.pixelSize: 14
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            id: batteryIcon
            text: (typeof battery !== "undefined" && battery.charging) ? "󱐋" : "󰁹"
            color: textColor
            font.pixelSize: 18
            font.family: iconFont.name
            anchors.verticalCenter: parent.verticalCenter
        }

        // Bulletproof Live Update: SDDM sometimes fails to emit battery signals,
        // so we force a check every 5 seconds.
        Timer {
            interval: 5000
            running: typeof battery !== "undefined" && battery.present
            repeat: true
            onTriggered: {
                batteryText.text = battery.percent + "%"
                batteryIcon.text = battery.charging ? "󱐋" : "󰁹"
            }
        }
    }

    Text {
        text: (typeof keyboard !== "undefined" && keyboard.layouts[keyboard.currentLayout]) ? keyboard.layouts[keyboard.currentLayout].shortName : "US"
        color: textColor
        font.pixelSize: 14
        font.capitalization: Font.AllUppercase
        visible: typeof keyboard !== "undefined" && keyboard.layouts.length > 1
        anchors.verticalCenter: parent.verticalCenter

        MouseArea {
            anchors.fill: parent
            onClicked: {
                keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length
            }
        }
    }

    Button {
        visible: sddm.canSuspend
        width: 30
        height: 30
        padding: 0
        focusPolicy: Qt.NoFocus
        text: "󰤄"
        onClicked: sddm.suspend()
        contentItem: Text { text: parent.text; color: parent.hovered ? accentColor : textColor; font.pixelSize: 20; font.family: iconFont.name; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        background: Rectangle { radius: 10; color: parent.hovered ? Qt.rgba(powerBarRoot.surfaceColor.r, powerBarRoot.surfaceColor.g, powerBarRoot.surfaceColor.b, .7) : "transparent" }
    }

    Button {
        visible: sddm.canReboot
        width: 30
        height: 30
        padding: 0
        focusPolicy: Qt.NoFocus
        text: "󰑐"
        onClicked: sddm.reboot()
        contentItem: Text { text: parent.text; color: parent.hovered ? accentColor : textColor; font.pixelSize: 20; font.family: iconFont.name; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        background: Rectangle { radius: 10; color: parent.hovered ? Qt.rgba(powerBarRoot.surfaceColor.r, powerBarRoot.surfaceColor.g, powerBarRoot.surfaceColor.b, .7) : "transparent" }
    }

    Button {
        visible: sddm.canPowerOff
        width: 30
        height: 30
        padding: 0
        focusPolicy: Qt.NoFocus
        text: "󰐥"
        onClicked: sddm.powerOff()
        contentItem: Text { text: parent.text; color: parent.hovered ? accentColor : textColor; font.pixelSize: 20; font.family: iconFont.name; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        background: Rectangle { radius: 10; color: parent.hovered ? Qt.rgba(powerBarRoot.surfaceColor.r, powerBarRoot.surfaceColor.g, powerBarRoot.surfaceColor.b, .7) : "transparent" }
    }
}
