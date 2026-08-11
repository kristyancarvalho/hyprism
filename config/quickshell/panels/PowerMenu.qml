import QtQuick
import "../components"
import ".."

Item {
    id: panel
    required property var controller
    required property var theme
    property string confirming: ""
    property int selectedIndex: 0
    readonly property var entries: [
        { label: "Bloquear", icon: "lock", command: "hyprlock", destructive: false },
        { label: "Suspender", icon: "suspend", command: "systemctl suspend", destructive: true },
        { label: "Encerrar sessão", icon: "logout", command: "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit", destructive: true },
        { label: "Reiniciar", icon: "reboot", command: "systemctl reboot", destructive: true },
        { label: "Desligar", icon: "power", command: "systemctl poweroff", destructive: true }
    ]

    function action(entry) {
        if (!entry) return
        if (entry.destructive && confirming !== entry.label) {
            confirming = entry.label
            return
        }
        controller.run(["sh", "-lc", entry.command])
        controller.close()
    }

    focus: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            controller.close()
            event.accepted = true
        } else if (event.key === Qt.Key_Left) {
            selectedIndex = navigation.grid(selectedIndex, -1, 0, 3, entries.length)
            event.accepted = true
        } else if (event.key === Qt.Key_Right) {
            selectedIndex = navigation.grid(selectedIndex, 1, 0, 3, entries.length)
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            selectedIndex = navigation.grid(selectedIndex, 0, -1, 3, entries.length)
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            selectedIndex = navigation.grid(selectedIndex, 0, 1, 3, entries.length)
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            action(entries[selectedIndex])
            event.accepted = true
        }
    }

    Navigation { id: navigation }

    Column {
        anchors.centerIn: parent
        spacing: 12

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: confirming ? "Ative novamente para confirmar: " + confirming.toLowerCase() : "Controles da sessão"
            color: theme.colors.foreground
            font.family: Design.fontFamily
            font.pixelSize: Design.fontSizeMd
            font.weight: Design.fontWeightSemibold
        }

        Grid {
            columns: 3
            spacing: 8

            Repeater {
                model: panel.entries

                ActionButton {
                    required property var modelData
                    required property int index
                    theme: panel.theme
                    label: modelData.label
                    iconName: modelData.icon
                    active: panel.selectedIndex === index
                    onActiveFocusChanged: if (activeFocus) panel.selectedIndex = index
                    onClicked: {
                        panel.selectedIndex = index
                        panel.action(modelData)
                    }
                }
            }
        }
    }

    Component.onCompleted: forceActiveFocus()
}
