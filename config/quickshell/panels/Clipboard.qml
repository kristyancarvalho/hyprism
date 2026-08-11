import QtQuick
import QtQuick.Controls
import "../components"
import ".."

Item {
    id: panel
    required property var controller
    required property var theme
    required property var clipboard
    property string query: ""
    property int selectedIndex: 0

    function results() {
        return controller.clipboardEntries.filter(item => Design.safeText(item ? item.text : "", "").toLowerCase().indexOf(query.toLowerCase()) >= 0)
    }

    focus: true
    Keys.onPressed: event => {
        const items = results()
        if (event.key === Qt.Key_Escape) {
            controller.close()
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            selectedIndex = navigation.wrap(selectedIndex, -1, items.length)
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            selectedIndex = navigation.wrap(selectedIndex, 1, items.length)
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (items[selectedIndex]) clipboard.select(items[selectedIndex].id)
            event.accepted = true
        } else if (event.key === Qt.Key_Delete) {
            if (items[selectedIndex]) clipboard.remove(items[selectedIndex].id)
            event.accepted = true
        }
    }

    Navigation { id: navigation }

    Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 10

        Text {
            text: "Área de transferência"
            color: panel.theme.colors.foreground
            font.family: Design.fontFamily
            font.pixelSize: Design.fontSizeLg
            font.weight: Design.fontWeightSemibold
        }

        Row {
            width: parent.width
            spacing: 8

            TextField {
                id: search
                width: parent.width - clear.width - 8
                height: 42
                leftPadding: 14
                focus: true
                placeholderText: "Pesquisar na área de transferência…"
                color: panel.theme.colors.foreground
                placeholderTextColor: panel.theme.colors.mutedForeground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeSm
                onTextChanged: {
                    panel.query = text
                    panel.selectedIndex = 0
                }
                background: Rectangle {
                    radius: Design.radiusSm
                    color: panel.theme.colors.surfaceVariant
                    border.width: search.activeFocus ? 2 : 1
                    border.color: search.activeFocus ? panel.theme.colors.accent : panel.theme.colors.outline
                }
            }

            ShellButton {
                id: clear
                theme: panel.theme
                text: "Limpar"
                iconName: "clear"
                onClicked: panel.clipboard.clear()
            }
        }

        ListView {
            width: parent.width
            height: Math.max(120, parent.height - 104)
            model: panel.results()
            currentIndex: panel.selectedIndex
            clip: true
            spacing: 6
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

            delegate: Rectangle {
                required property var modelData
                required property int index
                width: ListView.view.width
                height: 54
                radius: Design.radiusSm
                color: panel.selectedIndex === index ? panel.theme.colors.surfaceActive : pointer.containsMouse ? panel.theme.colors.surfaceHover : panel.theme.colors.surfaceVariant
                border.width: panel.selectedIndex === index ? 2 : 1
                border.color: panel.selectedIndex === index ? panel.theme.colors.accent : panel.theme.colors.outline

                StatusIcon {
                    anchors {
                        left: parent.left
                        leftMargin: 13
                        verticalCenter: parent.verticalCenter
                    }
                    name: "clipboard"
                    iconSize: Design.iconMd
                    color: panel.theme.colors.accent
                }

                Text {
                    anchors {
                        left: parent.left
                        right: deleteButton.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 46
                        rightMargin: 8
                    }
                    text: Design.safeText(modelData.text, "Conteúdo indisponível").replace(/\n/g, " ")
                    elide: Text.ElideRight
                    color: panel.theme.colors.foreground
                    font.family: Design.fontFamily
                    font.pixelSize: Design.fontSizeSm
                }

                ShellButton {
                    id: deleteButton
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        rightMargin: 7
                    }
                    theme: panel.theme
                    compact: true
                    iconName: "clear"
                    onClicked: panel.clipboard.remove(modelData.id)
                }

                MouseArea {
                    id: pointer
                    anchors {
                        left: parent.left
                        right: deleteButton.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    hoverEnabled: true
                    onEntered: panel.selectedIndex = index
                    onClicked: panel.clipboard.select(modelData.id)
                }
            }

            Text {
                anchors.centerIn: parent
                visible: parent.count === 0
                text: "A área de transferência está vazia"
                color: panel.theme.colors.mutedForeground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeSm
            }
        }
    }

    Component.onCompleted: {
        clipboard.refresh()
        search.forceActiveFocus()
    }
}
