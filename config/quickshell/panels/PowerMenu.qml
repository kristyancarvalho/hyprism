import QtQuick
import "../components"

Item {
    id: panel
    required property var controller
    required property var theme
    property string confirming: ""
    function action(label, command, destructive) {
        if (destructive && confirming !== label) { confirming = label; return }
        controller.run(["sh", "-lc", command]); controller.close()
    }
    focus: true
    Keys.onPressed: event => { if (event.key === Qt.Key_Escape) { controller.close(); event.accepted = true } }
    Column { anchors.centerIn: parent; spacing: 12
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: confirming ? "Click again to confirm " + confirming.toLowerCase() : "Session controls"; color: theme.colors.foreground; font { pixelSize: 16; bold: true } }
        Grid { columns: 3; spacing: 8
            ActionButton { theme: panel.theme; label: "Lock"; icon: "◉"; onClicked: panel.action("Lock", "hyprlock", false) }
            ActionButton { theme: panel.theme; label: "Suspend"; icon: "◐"; onClicked: panel.action("Suspend", "systemctl suspend", true) }
            ActionButton { theme: panel.theme; label: "Logout"; icon: "↪"; onClicked: panel.action("Logout", "hyprctl dispatch exit", true) }
            ActionButton { theme: panel.theme; label: "Reboot"; icon: "↻"; onClicked: panel.action("Reboot", "systemctl reboot", true) }
            ActionButton { theme: panel.theme; label: "Shutdown"; icon: "⏻"; onClicked: panel.action("Shutdown", "systemctl poweroff", true) }
        }
    }
}
