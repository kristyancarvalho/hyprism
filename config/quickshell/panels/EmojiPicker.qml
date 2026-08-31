import QtQuick
import Quickshell
import Quickshell.Io
import "../components"
import ".."

FocusScope {
    id: panel
    required property var controller
    required property var theme
    property string query: ""
    property int selectedIndex: -1
    property var emojis: []
    property string dataError: ""
    readonly property var resultModel: filteredEmoji()
    readonly property int resultCount: resultModel.length

    function normalized(value) {
        const lowered = Design.safeText(value, "").toLowerCase()
        const decomposed = lowered.normalize ? lowered.normalize("NFD") : lowered
        return decomposed.replace(/[\u0300-\u036f]/g, "").replace(/[^\p{L}\p{N}]+/gu, " ").trim()
    }

    function filteredEmoji() {
        const raw = query.trim()
        if (!raw) return emojis
        const terms = normalized(query).split(" ").filter(term => term.length > 0)
        return emojis.filter(item => item.glyph === raw || (terms.length > 0 && terms.every(term => item.search.indexOf(term) >= 0)))
    }

    function loadData() {
        try {
            const parsed = JSON.parse(emojiFile.text())
            if (!parsed || !Array.isArray(parsed.emoji) || parsed.emoji.length < 3000) throw new Error("incomplete index")
            emojis = parsed.emoji
            dataError = ""
        } catch (error) {
            emojis = []
            dataError = String(error)
            console.warn("invalid emoji index:", dataError)
        }
    }

    function copy(glyph) {
        controller.run(["wl-copy", glyph])
        controller.showOsd("Emoji", glyph)
        controller.close()
    }

    function resultSelectable(index) {
        const entry = resultModel[index]
        return entry && Design.safeText(entry.glyph, "").length > 0
    }

    function focusGrid() {
        if (!resultCount) return
        grid.forceActiveFocus(Qt.TabFocusReason)
        grid.positionViewAtIndex(selectedIndex, GridView.Contain)
    }

    function takeInitialFocus() {
        resetSelection()
        search.forceInputFocus(Qt.ShortcutFocusReason)
    }

    function resetSelection() {
        selectedIndex = navigation.reset(resultCount, resultSelectable)
        grid.positionViewAtBeginning()
        Qt.callLater(() => {
            if (selectedIndex >= 0) grid.positionViewAtIndex(selectedIndex, GridView.Beginning)
        })
    }

    function initialFocusReady() {
        return search.inputActiveFocus || grid.activeFocus || search.clearButtonItem.activeFocus
    }

    function handleGridKey(event) {
        if (event.key === Qt.Key_Escape) {
            controller.close()
            event.accepted = true
        } else if (event.key === Qt.Key_Left) {
            navigation.useKeyboard()
            selectedIndex = navigation.grid(selectedIndex, -1, 0, grid.columns, resultCount)
            event.accepted = true
        } else if (event.key === Qt.Key_Right) {
            navigation.useKeyboard()
            selectedIndex = navigation.grid(selectedIndex, 1, 0, grid.columns, resultCount)
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            navigation.useKeyboard()
            selectedIndex = navigation.grid(selectedIndex, 0, -1, grid.columns, resultCount)
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            navigation.useKeyboard()
            selectedIndex = navigation.grid(selectedIndex, 0, 1, grid.columns, resultCount)
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (resultModel[selectedIndex]) copy(resultModel[selectedIndex].glyph)
            event.accepted = true
        }
    }

    focus: true
    Keys.onPressed: event => handleGridKey(event)
    onResultCountChanged: {
        controller.emojiResultCount = resultCount
        resetSelection()
        if (!resultCount) search.forceInputFocus(Qt.OtherFocusReason)
    }

    Navigation { id: navigation }

    FileView {
        id: emojiFile
        path: panel.controller.rootDir + "/config/quickshell/data/emoji.json"
        blockLoading: true
        preload: true
        watchChanges: false
        printErrors: true
        onLoaded: panel.loadData()
    }

    Column {
        anchors.fill: parent
        anchors.margins: Design.spacingLg
        spacing: Design.spacingMd

        SearchField {
            id: search
            width: parent.width
            height: 42
            theme: panel.theme
            placeholderText: I18n.tr("emoji.search")
            tabTarget: grid
            backtabTarget: grid
            onTextChanged: {
                panel.query = text
                panel.resetSelection()
            }
            onClearRequested: text = ""
            onKeyPressed: event => {
                if (event.key === Qt.Key_Down) {
                    navigation.useKeyboard()
                    panel.focusGrid()
                    event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (panel.resultModel[panel.selectedIndex]) panel.copy(panel.resultModel[panel.selectedIndex].glyph)
                    event.accepted = true
                } else if (event.key === Qt.Key_Escape) {
                    panel.controller.close()
                    event.accepted = true
                }
            }
        }

        GridView {
            id: grid
            readonly property int columns: Design.gridColumnCount(width, cellWidth)
            width: parent.width
            height: Math.max(0, parent.height - search.height - parent.spacing)
            cellWidth: Design.emojiCellSize
            cellHeight: Design.emojiCellSize
            clip: true
            model: panel.resultModel
            currentIndex: panel.selectedIndex
            activeFocusOnTab: true
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: event => panel.handleGridKey(event)
            KeyNavigation.tab: search
            KeyNavigation.backtab: search.clearVisible ? search.clearButtonItem : search
            onCurrentIndexChanged: if (currentIndex >= 0) positionViewAtIndex(currentIndex, GridView.Contain)

            SelectionHighlight {
                parent: grid.contentItem
                theme: panel.theme
                target: grid.currentItem
                active: navigation.keyboardNavigation && panel.resultCount > 0
                inset: Design.spacingXs
            }

            delegate: Item {
                id: emojiDelegate
                required property var modelData
                required property int index
                width: grid.cellWidth
                height: grid.cellHeight
                z: 2

                DelegateSurface {
                    host: grid.contentItem
                    target: emojiDelegate
                    theme: panel.theme
                    hovered: pointer.containsMouse && !navigation.keyboardNavigation
                    inset: Design.spacingXs
                }

                Item {
                    anchors.centerIn: parent
                    width: Design.emojiButtonSize
                    height: Design.emojiButtonSize

                    Text {
                        anchors.centerIn: parent
                        text: modelData.glyph
                        font.pixelSize: 24
                    }

                    MouseArea {
                        id: pointer
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: {
                            navigation.usePointer()
                            panel.selectedIndex = index
                        }
                        onClicked: panel.copy(modelData.glyph)
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: parent.count === 0
                text: panel.dataError ? I18n.tr("emoji.loadError") : I18n.tr("emoji.empty")
                color: panel.theme.colors.mutedForeground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeSm
            }
        }
    }

    Component.onCompleted: {
        controller.emojiColumnCount = grid.columns
        controller.emojiResultCount = resultCount
        takeInitialFocus()
    }

    Connections {
        target: grid
        function onColumnsChanged() { panel.controller.emojiColumnCount = grid.columns }
    }
}
