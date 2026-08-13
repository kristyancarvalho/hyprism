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
    readonly property var filteredEntries: results()

    function results() {
        return controller.clipboardEntries.filter(item => Design.safeText(item ? item.searchText : "", Design.safeText(item ? item.text : "", "")).toLowerCase().indexOf(query.toLowerCase()) >= 0)
    }

    function handleKey(event) {
        const items = filteredEntries
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
            if (items[selectedIndex]) clipboard.select(items[selectedIndex])
            event.accepted = true
        } else if (event.key === Qt.Key_Delete) {
            if (items[selectedIndex]) clipboard.remove(items[selectedIndex].id)
            event.accepted = true
        }
    }

    function takeInitialFocus() {
        search.forceActiveFocus(Qt.ShortcutFocusReason)
    }

    function initialFocusReady() {
        return search.activeFocus
    }

    focus: true
    Keys.onPressed: event => handleKey(event)
    onFilteredEntriesChanged: selectedIndex = navigation.clamp(selectedIndex, filteredEntries.length)

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
                Keys.priority: Keys.BeforeItem
                Keys.onPressed: event => panel.handleKey(event)
                background: Rectangle {
                    radius: Design.radiusSm
                    color: panel.theme.colors.surfaceVariant
                    border.width: search.activeFocus ? 2 : 0
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
            model: panel.filteredEntries
            currentIndex: panel.selectedIndex
            clip: true
            spacing: 6
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

            delegate: Rectangle {
                required property var modelData
                required property int index
                width: ListView.view.width
                height: modelData.type === "image" ? 126 : 58
                radius: Design.radiusSm
                color: panel.selectedIndex === index ? panel.theme.colors.surfaceActive : pointer.containsMouse ? panel.theme.colors.surfaceHover : panel.theme.colors.surfaceVariant
                border.width: panel.selectedIndex === index ? 2 : 0
                border.color: panel.theme.colors.accent

                StatusIcon {
                    visible: modelData.type !== "image"
                    anchors {
                        left: parent.left
                        leftMargin: 13
                        verticalCenter: parent.verticalCenter
                    }
                    name: modelData.type === "unknown" ? "image" : "clipboard"
                    iconSize: Design.iconMd
                    color: panel.theme.colors.accent
                }

                Text {
                    visible: modelData.type !== "image"
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

                Rectangle {
                    visible: modelData.type === "image"
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                        margins: 10
                    }
                    width: 164
                    radius: Design.radiusSm
                    color: panel.theme.colors.surface
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: 5
                        visible: Design.safeText(modelData.thumbnail, "").length > 0
                        source: Design.safeText(modelData.thumbnail, "")
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        cache: true
                    }

                    StatusIcon {
                        anchors.centerIn: parent
                        visible: Design.safeText(modelData.thumbnail, "").length === 0
                        name: "image"
                        iconSize: Design.iconLg
                        color: panel.theme.colors.mutedForeground
                    }
                }

                Column {
                    visible: modelData.type === "image"
                    anchors {
                        left: parent.left
                        leftMargin: 188
                        right: deleteButton.left
                        rightMargin: 8
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 4

                    Text {
                        width: parent.width
                        text: "Imagem copiada"
                        color: panel.theme.colors.foreground
                        font.family: Design.fontFamily
                        font.pixelSize: Design.fontSizeSm
                        font.weight: Design.fontWeightSemibold
                    }

                    Text {
                        width: parent.width
                        text: Design.safeNumber(modelData.width, 0) > 0 && Design.safeNumber(modelData.height, 0) > 0 ? Math.round(modelData.width) + " × " + Math.round(modelData.height) : "Prévia indisponível"
                        color: panel.theme.colors.mutedForeground
                        font.family: Design.fontFamily
                        font.pixelSize: Design.fontSizeXs
                    }
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
                    onClicked: panel.clipboard.select(modelData)
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
        takeInitialFocus()
    }
}
