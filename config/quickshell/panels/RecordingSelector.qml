import QtQuick
import QtQuick.Layouts
import "../components"
import ".."

FocusScope {
    id: panel
    required property var controller
    required property var theme
    property int selectedIndex: 0

    function choose() {
        if (selectedIndex === 0) controller.startRegionRecording()
        else controller.startMonitorRecording()
    }

    function select(index) {
        navigation.useKeyboard()
        selectedIndex = Math.max(0, Math.min(1, index))
        const target = selectedIndex === 0 ? regionButton : monitorButton
        target.forceActiveFocus(Qt.TabFocusReason)
    }

    function pointerSelect(index) {
        navigation.usePointer()
        selectedIndex = index
    }

    function takeInitialFocus() {
        select(navigation.reset(2))
    }

    function initialFocusReady() {
        return regionButton.activeFocus || monitorButton.activeFocus || activeFocus
    }

    focus: true
    Navigation { id: navigation; keyboardNavigation: true }
    Keys.priority: Keys.BeforeItem
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            controller.close()
            event.accepted = true
        } else if (event.key === Qt.Key_Left) {
            select(selectedIndex - 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Right) {
            select(selectedIndex + 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            choose()
            event.accepted = true
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Design.spacingLg
        spacing: Design.spacingMd

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: I18n.tr("recording.title")
                color: panel.theme.colors.foreground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeLg
                font.weight: Design.fontWeightSemibold
            }

            ShellButton {
                theme: panel.theme
                iconName: "close"
                compact: true
                onClicked: panel.controller.close()
            }
        }

        Item {
            id: optionsLayer
            Layout.fillWidth: true
            Layout.fillHeight: true

            SelectionHighlight {
                parent: optionsLayer
                theme: panel.theme
                target: panel.selectedIndex === 0 ? regionButton : monitorButton
                active: navigation.keyboardNavigation
            }

            RowLayout {
                anchors.fill: parent
                spacing: Design.spacingSm
                z: 2

                ActionButton {
                    id: regionButton
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    z: 2
                    theme: panel.theme
                    label: I18n.tr("recording.region")
                    iconName: "recordRegion"
                    managedSurface: true
                    suppressHover: navigation.keyboardNavigation
                    KeyNavigation.right: monitorButton
                    onHoveredChanged: if (hovered) panel.pointerSelect(0)
                    onActiveFocusChanged: if (activeFocus) panel.selectedIndex = 0
                    onClicked: {
                        panel.selectedIndex = 0
                        panel.choose()
                    }

                    DelegateSurface {
                        host: optionsLayer
                        target: regionButton
                        theme: panel.theme
                        hovered: regionButton.hovered && !navigation.keyboardNavigation
                    }
                }

                ActionButton {
                    id: monitorButton
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    z: 2
                    theme: panel.theme
                    label: I18n.tr("recording.screen")
                    iconName: "recordMonitor"
                    managedSurface: true
                    suppressHover: navigation.keyboardNavigation
                    KeyNavigation.left: regionButton
                    onHoveredChanged: if (hovered) panel.pointerSelect(1)
                    onActiveFocusChanged: if (activeFocus) panel.selectedIndex = 1
                    onClicked: {
                        panel.selectedIndex = 1
                        panel.choose()
                    }

                    DelegateSurface {
                        host: optionsLayer
                        target: monitorButton
                        theme: panel.theme
                        hovered: monitorButton.hovered && !navigation.keyboardNavigation
                    }
                }
            }
        }
    }

    Component.onCompleted: takeInitialFocus()
}
