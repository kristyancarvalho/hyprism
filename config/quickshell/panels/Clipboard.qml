import QtQuick
import "../components"
import ".."

Item {
    id: panel
    required property var controller
    required property var theme
    required property var clipboard
    property string query: ""
    property int selectedIndex: -1
    readonly property var filteredEntries: results()

    function updateResultMetrics() {
        const count = filteredEntries.length
        const itemHeight = filteredEntries.reduce((total, entry) => total + (entry.type === "image" ? 126 : 58), 0)
        controller.clipboardResultCount = count
        controller.clipboardResultHeight = Design.variableListContentHeight(itemHeight, count, 6, 58)
    }

    function results() {
        return controller.clipboardEntries.filter(item => Design.safeText(item ? item.searchText : "", Design.safeText(item ? item.text : "", "")).toLowerCase().indexOf(query.toLowerCase()) >= 0)
    }

    function resultSelectable(index) {
        const entry = filteredEntries[index]
        return entry && entry.disabled !== true
    }

    function handleKey(event) {
        const items = filteredEntries
        if (event.key === Qt.Key_Escape) {
            controller.close()
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            navigation.useKeyboard()
            selectedIndex = navigation.move(selectedIndex, -1, items.length, resultSelectable)
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            navigation.useKeyboard()
            selectedIndex = navigation.move(selectedIndex, 1, items.length, resultSelectable)
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
        resetSelection()
        search.forceActiveFocus(Qt.ShortcutFocusReason)
    }

    function resetSelection() {
        selectedIndex = navigation.reset(filteredEntries.length, resultSelectable)
        entriesList.positionViewAtBeginning()
        Qt.callLater(() => {
            if (selectedIndex >= 0) entriesList.positionViewAtIndex(selectedIndex, ListView.Beginning)
        })
    }

    function initialFocusReady() {
        return search.activeFocus
    }

    focus: true
    Keys.onPressed: event => handleKey(event)
    onFilteredEntriesChanged: {
        updateResultMetrics()
        resetSelection()
    }

    Navigation { id: navigation }

    Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 10

        Text {
            id: title
            text: "Área de transferência"
            color: panel.theme.colors.foreground
            font.family: Design.fontFamily
            font.pixelSize: Design.fontSizeLg
            font.weight: Design.fontWeightSemibold
        }

        Row {
            id: searchRow
            width: parent.width
            spacing: 8

            SearchField {
                id: search
                width: parent.width - clear.width - 8
                height: 42
                theme: panel.theme
                placeholderText: "Pesquisar na área de transferência…"
                onTextChanged: {
                    panel.query = text
                    panel.resetSelection()
                }
                onKeyPressed: event => panel.handleKey(event)
                onClearRequested: text = ""
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
            id: entriesList
            width: parent.width
            height: Math.max(0, parent.height - title.height - searchRow.height - parent.spacing * 2)
            model: panel.filteredEntries
            currentIndex: panel.selectedIndex
            clip: true
            spacing: 6
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

            SelectionHighlight {
                parent: entriesList.contentItem
                theme: panel.theme
                target: entriesList.currentItem
                active: navigation.keyboardNavigation && panel.filteredEntries.length > 0
            }

            delegate: Item {
                id: clipboardDelegate
                required property var modelData
                required property int index
                width: ListView.view.width
                height: modelData.type === "image" ? 126 : 58
                z: 2

                DelegateSurface {
                    host: entriesList.contentItem
                    target: clipboardDelegate
                    theme: panel.theme
                    hovered: pointer.containsMouse && !navigation.keyboardNavigation
                }

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
                    onEntered: {
                        navigation.usePointer()
                        panel.selectedIndex = index
                    }
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
        updateResultMetrics()
        takeInitialFocus()
    }
}
