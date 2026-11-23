/**
 * Pixie SDDM - PowerBar Component
 * Author: xCaptaiN09
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Row {
    id: powerBarRoot
    spacing: 8
    height: 34

    property var power
    property color textColor: "white"
    property color accentColor: "white"
    property color surfaceColor: "black"
    property string fontFamily: ""
    property string iconFamily: ""
    property string suspendText: "Suspend"
    property string restartText: "Restart"
    property string shutdownText: "Shut down"
    property string layoutText: "Keyboard layout"

    readonly property var entries: [
        { glyph: 0xF04B2, label: suspendText, available: power ? power.canSuspend : false, action: "suspend" },
        { glyph: 0xF0709, label: restartText, available: power ? power.canReboot : false, action: "reboot" },
        { glyph: 0xF0425, label: shutdownText, available: power ? power.canPowerOff : false, action: "powerOff" }
    ]

    Row {
        id: batteryRow
        spacing: 5
        visible: typeof battery !== "undefined" && typeof battery.percent !== "undefined"
        anchors.verticalCenter: parent.verticalCenter

        Text {
            id: batteryText
            text: (typeof battery !== "undefined" ? battery.percent : "0") + "%"
            color: textColor
            font.family: powerBarRoot.fontFamily
            font.pixelSize: 14
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            id: batteryIcon
            text: String.fromCodePoint((typeof battery !== "undefined" && battery.charging) ? 0xF140B : 0xF0079)
            color: textColor
            font.pixelSize: 18
            font.family: powerBarRoot.iconFamily
            anchors.verticalCenter: parent.verticalCenter
        }

        Timer {
            interval: 5000
            running: typeof battery !== "undefined" && battery.present
            repeat: true
            onTriggered: {
                batteryText.text = battery.percent + "%"
                batteryIcon.text = String.fromCodePoint(battery.charging ? 0xF140B : 0xF0079)
            }
        }
    }

    Item {
        id: layoutIndicator
        visible: typeof keyboard !== "undefined" && keyboard.layouts.length > 1
        width: layoutLabel.implicitWidth + 12
        height: 30
        anchors.verticalCenter: parent.verticalCenter

        Text {
            id: layoutLabel
            anchors.centerIn: parent
            text: (typeof keyboard !== "undefined" && keyboard.layouts[keyboard.currentLayout]) ? keyboard.layouts[keyboard.currentLayout].shortName : "US"
            color: layoutMouse.containsMouse ? accentColor : textColor
            font.family: powerBarRoot.fontFamily
            font.pixelSize: 14
            font.capitalization: Font.AllUppercase
        }

        MouseArea {
            id: layoutMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length
            ToolTip.visible: containsMouse
            ToolTip.text: powerBarRoot.layoutText
        }
    }

    Repeater {
        model: powerBarRoot.entries

        Button {
            id: powerButton
            required property var modelData
            visible: modelData.available
            width: 34
            height: 34
            padding: 0
            focusPolicy: Qt.NoFocus
            onClicked: powerBarRoot.power[modelData.action]()
            ToolTip.visible: hovered
            ToolTip.text: modelData.label
            Accessible.name: modelData.label
            contentItem: Text {
                text: String.fromCodePoint(powerButton.modelData.glyph)
                color: powerButton.down || powerButton.hovered ? powerBarRoot.accentColor : powerBarRoot.textColor
                font.pixelSize: 21
                font.family: powerBarRoot.iconFamily
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                radius: 12
                color: powerButton.down ? Qt.rgba(powerBarRoot.surfaceColor.r, powerBarRoot.surfaceColor.g, powerBarRoot.surfaceColor.b, .95) : (powerButton.hovered ? Qt.rgba(powerBarRoot.surfaceColor.r, powerBarRoot.surfaceColor.g, powerBarRoot.surfaceColor.b, .7) : "transparent")
            }
        }
    }
}
