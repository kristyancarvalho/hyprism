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
    property int selectedIndex: 0
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
            if (!parsed || !Array.isArray(parsed.emoji) || parsed.emoji.length < 3000) throw new Error("índice incompleto")
            emojis = parsed.emoji
            dataError = ""
        } catch (error) {
            emojis = []
            dataError = String(error)
            console.warn("índice de emoji inválido:", dataError)
        }
    }

    function copy(glyph) {
        controller.run(["wl-copy", glyph])
        controller.showOsd("Emoji", glyph)
        controller.close()
    }

    function focusGrid() {
        if (!resultCount) return
        grid.forceActiveFocus(Qt.TabFocusReason)
        grid.positionViewAtIndex(selectedIndex, GridView.Contain)
    }

    function takeInitialFocus() {
        search.forceInputFocus(Qt.ShortcutFocusReason)
    }

    function initialFocusReady() {
        return search.inputActiveFocus || grid.activeFocus || search.clearButtonItem.activeFocus
    }

    function handleGridKey(event) {
        if (event.key === Qt.Key_Escape) {
            controller.close()
            event.accepted = true
        } else if (event.key === Qt.Key_Left) {
            selectedIndex = navigation.grid(selectedIndex, -1, 0, grid.columns, resultCount)
            event.accepted = true
        } else if (event.key === Qt.Key_Right) {
            selectedIndex = navigation.grid(selectedIndex, 1, 0, grid.columns, resultCount)
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            selectedIndex = navigation.grid(selectedIndex, 0, -1, grid.columns, resultCount)
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
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
        selectedIndex = navigation.clamp(selectedIndex, resultCount)
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
            placeholderText: "Pesquisar emoji…"
            tabTarget: grid
            backtabTarget: grid
            onTextChanged: {
                panel.query = text
                panel.selectedIndex = 0
            }
            onClearRequested: text = ""
            onKeyPressed: event => {
                if (event.key === Qt.Key_Down) {
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
            readonly property int columns: Design.emojiColumnCount
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

            delegate: Item {
                required property var modelData
                required property int index
                width: grid.cellWidth
                height: grid.cellHeight

                Rectangle {
                    anchors.centerIn: parent
                    width: Design.emojiButtonSize
                    height: Design.emojiButtonSize
                    radius: Design.radiusSm
                    color: panel.selectedIndex === index ? panel.theme.colors.surfaceActive : pointer.containsMouse ? panel.theme.colors.surfaceHover : panel.theme.colors.surfaceVariant
                    border.width: panel.selectedIndex === index ? (grid.activeFocus ? 2 : 1) : 0
                    border.color: panel.theme.colors.accent

                    Behavior on color {
                        ColorAnimation { duration: Design.animationInstant; easing.type: Design.easingMorph }
                    }

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
                        onEntered: panel.selectedIndex = index
                        onClicked: panel.copy(modelData.glyph)
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: parent.count === 0
                text: panel.dataError ? "Não foi possível carregar os emojis" : "Nenhum emoji encontrado"
                color: panel.theme.colors.mutedForeground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeSm
            }
        }
    }

    Component.onCompleted: takeInitialFocus()
}
