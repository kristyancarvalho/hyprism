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
        selectedIndex = Math.max(0, Math.min(1, index))
        const target = selectedIndex === 0 ? regionButton : monitorButton
        target.forceActiveFocus(Qt.TabFocusReason)
    }

    function takeInitialFocus() {
        select(0)
    }

    function initialFocusReady() {
        return regionButton.activeFocus || monitorButton.activeFocus || activeFocus
    }

    focus: true
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
                text: "Gravar tela"
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

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Design.spacingSm

            ActionButton {
                id: regionButton
                Layout.fillWidth: true
                Layout.fillHeight: true
                theme: panel.theme
                label: "Região"
                iconName: "recordRegion"
                active: panel.selectedIndex === 0
                KeyNavigation.right: monitorButton
                onActiveFocusChanged: if (activeFocus) panel.selectedIndex = 0
                onClicked: {
                    panel.selectedIndex = 0
                    panel.choose()
                }
            }

            ActionButton {
                id: monitorButton
                Layout.fillWidth: true
                Layout.fillHeight: true
                theme: panel.theme
                label: "Tela inteira"
                iconName: "recordMonitor"
                active: panel.selectedIndex === 1
                KeyNavigation.left: regionButton
                onActiveFocusChanged: if (activeFocus) panel.selectedIndex = 1
                onClicked: {
                    panel.selectedIndex = 1
                    panel.choose()
                }
            }
        }
    }

    Component.onCompleted: takeInitialFocus()
}
