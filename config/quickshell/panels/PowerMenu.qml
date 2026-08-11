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
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: confirming ? "Clique novamente para confirmar: " + confirming.toLowerCase() : "Controles da sessão"; color: theme.colors.foreground; font { pixelSize: 16; bold: true } }
        Grid { columns: 3; spacing: 8
            ActionButton { theme: panel.theme; label: "Bloquear"; iconName: "system-lock-screen"; onClicked: panel.action("Bloquear", "hyprlock", false) }
            ActionButton { theme: panel.theme; label: "Suspender"; iconName: "system-suspend"; onClicked: panel.action("Suspender", "systemctl suspend", true) }
            ActionButton { theme: panel.theme; label: "Encerrar sessão"; iconName: "system-log-out"; onClicked: panel.action("Encerrar sessão", "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'", true) }
            ActionButton { theme: panel.theme; label: "Reiniciar"; iconName: "system-reboot"; onClicked: panel.action("Reiniciar", "systemctl reboot", true) }
            ActionButton { theme: panel.theme; label: "Desligar"; iconName: "system-shutdown"; onClicked: panel.action("Desligar", "systemctl poweroff", true) }
        }
    }
}
