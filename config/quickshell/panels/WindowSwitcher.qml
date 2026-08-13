import QtQuick
import QtQuick.Layouts
import "../components"
import ".."

Item {
    id: panel
    required property var controller
    required property var theme
    focus: true

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            controller.close()
            event.accepted = true
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
            controller.switcher(-1)
            event.accepted = true
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
            controller.switcher(event.modifiers & Qt.ShiftModifier ? -1 : 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            controller.commitSwitcher()
            event.accepted = true
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        RowLayout {
            width: parent.width
            spacing: Design.spacingMd

            Text {
                Layout.fillWidth: true
                text: "Trocar janela"
                color: panel.theme.colors.foreground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeMd
                font.weight: Design.fontWeightSemibold
            }

            Text {
                id: hint
                Layout.preferredWidth: implicitWidth
                text: "← → navegar  ·  solte Alt para abrir"
                color: panel.theme.colors.mutedForeground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeXs
            }
        }

        ListView {
            id: windows
            width: parent.width
            height: parent.height - 30
            orientation: ListView.Horizontal
            spacing: 10
            clip: true
            model: controller.switcherWindows
            currentIndex: controller.switcherIndex
            preferredHighlightBegin: width * .34
            preferredHighlightEnd: width * .66
            highlightRangeMode: ListView.ApplyRange
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

            delegate: Rectangle {
                required property var modelData
                required property int index
                property bool selected: controller.switcherIndex === index
                width: Math.max(148, Math.min(180, (ListView.view.width - 30) / Math.min(4, Math.max(1, ListView.view.count))))
                height: ListView.view.height
                radius: Design.radiusMd
                color: selected ? panel.theme.colors.surfaceActive : pointer.containsMouse ? panel.theme.colors.surfaceHover : panel.theme.colors.surfaceVariant
                border.width: selected ? 2 : 0
                border.color: panel.theme.colors.accent

                Column {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 7

                    ShellIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: modelData ? modelData.icon : "application-x-executable"
                        fallback: "application-x-executable"
                        iconSize: 38
                        framed: true
                        frameColor: selected ? panel.theme.colors.accentDim : panel.theme.colors.surface
                    }

                    Text {
                        width: parent.width
                        text: modelData ? modelData.applicationName : "Janela"
                        color: panel.theme.colors.foreground
                        font.family: Design.fontFamily
                        font.pixelSize: Design.fontSizeSm
                        font.weight: Design.fontWeightSemibold
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: Design.safeText(modelData ? modelData.title : "", modelData && modelData.minimized ? "Janela minimizada" : "Sem título")
                        color: panel.theme.colors.mutedForeground
                        font.family: Design.fontFamily
                        font.pixelSize: Design.fontSizeXs
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.Wrap
                    }
                }

                MouseArea {
                    id: pointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: controller.switcherIndex = index
                    onClicked: controller.commitSwitcher()
                }
            }
        }
    }
}
