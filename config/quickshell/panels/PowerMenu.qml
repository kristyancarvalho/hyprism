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
        { label: I18n.tr("power.lock"), icon: "lock", command: "hyprlock", destructive: false },
        { label: I18n.tr("power.suspend"), icon: "suspend", command: "systemctl suspend", destructive: true },
        { label: I18n.tr("power.logout"), icon: "logout", command: "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit", destructive: true },
        { label: I18n.tr("power.reboot"), icon: "reboot", command: "systemctl reboot", destructive: true },
        { label: I18n.tr("power.shutdown"), icon: "power", command: "systemctl poweroff", destructive: true }
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

    function takeInitialFocus() {
        confirming = ""
        selectedIndex = navigation.reset(entries.length, index => entries[index] && entries[index].disabled !== true)
        forceActiveFocus(Qt.ShortcutFocusReason)
        Qt.callLater(() => selection.updateGeometry(false))
    }

    function initialFocusReady() {
        return activeFocus
    }

    focus: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            controller.close()
            event.accepted = true
        } else if (event.key === Qt.Key_Left) {
            navigation.useKeyboard()
            selectedIndex = navigation.grid(selectedIndex, -1, 0, 3, entries.length)
            event.accepted = true
        } else if (event.key === Qt.Key_Right) {
            navigation.useKeyboard()
            selectedIndex = navigation.grid(selectedIndex, 1, 0, 3, entries.length)
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            navigation.useKeyboard()
            selectedIndex = navigation.grid(selectedIndex, 0, -1, 3, entries.length)
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            navigation.useKeyboard()
            selectedIndex = navigation.grid(selectedIndex, 0, 1, 3, entries.length)
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            action(entries[selectedIndex])
            event.accepted = true
        }
    }

    Navigation { id: navigation; keyboardNavigation: true }

    Column {
        anchors.centerIn: parent
        spacing: 12

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: confirming ? I18n.tr("power.confirm", { action: confirming.toLowerCase() }) : I18n.tr("power.title")
            color: theme.colors.foreground
            font.family: Design.fontFamily
            font.pixelSize: Design.fontSizeMd
            font.weight: Design.fontWeightSemibold
        }

        Item {
            id: optionsLayer
            width: 526
            height: 144

            SelectionHighlight {
                id: selection
                parent: optionsLayer
                theme: panel.theme
                target: optionRepeater.count > panel.selectedIndex ? optionRepeater.itemAt(panel.selectedIndex) : null
                active: navigation.keyboardNavigation
            }

            Grid {
                anchors.fill: parent
                columns: 3
                spacing: 8
                z: 2

                Repeater {
                    id: optionRepeater
                    model: panel.entries

                    ActionButton {
                        id: optionButton
                        required property var modelData
                        required property int index
                        z: 2
                        theme: panel.theme
                        label: modelData.label
                        iconName: modelData.icon
                        managedSurface: true
                        suppressHover: navigation.keyboardNavigation
                        onHoveredChanged: if (hovered) {
                            navigation.usePointer()
                            panel.selectedIndex = index
                        }
                        onActiveFocusChanged: if (activeFocus) panel.selectedIndex = index
                        onClicked: {
                            panel.selectedIndex = index
                            panel.action(modelData)
                        }

                        DelegateSurface {
                            host: optionsLayer
                            target: optionButton
                            theme: panel.theme
                            hovered: optionButton.hovered && !navigation.keyboardNavigation
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: takeInitialFocus()
}
