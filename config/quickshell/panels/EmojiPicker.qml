import QtQuick
import QtQuick.Controls
import "../components"
import ".."

Item {
    id: panel
    required property var controller
    required property var theme
    property string query: ""
    property int selectedIndex: 0
    property var emojis: [
        { glyph: "😀", name: "sorriso" }, { glyph: "😂", name: "alegria" }, { glyph: "❤️", name: "coração" }, { glyph: "👍", name: "positivo" }, { glyph: "✨", name: "brilho" }, { glyph: "🔥", name: "fogo" }, { glyph: "🎉", name: "festa" }, { glyph: "🚀", name: "foguete" }, { glyph: "✅", name: "correto" }, { glyph: "❌", name: "errado" }, { glyph: "⚡", name: "raio" }, { glyph: "🎵", name: "música" }
    ]

    function results() {
        return emojis.filter(item => item.name.indexOf(query.toLowerCase()) >= 0)
    }

    function copy(glyph) {
        controller.run(["sh", "-lc", "printf %s " + "'" + glyph + "' | wl-copy"])
        controller.showOsd("Emoji", glyph)
        controller.close()
    }

    function focusGrid() {
        if (!results().length) return
        grid.forceActiveFocus(Qt.TabFocusReason)
        grid.positionViewAtIndex(selectedIndex, GridView.Contain)
    }

    function takeInitialFocus() {
        search.forceActiveFocus(Qt.ShortcutFocusReason)
    }

    function initialFocusReady() {
        return search.activeFocus || grid.activeFocus
    }

    function handleGridKey(event) {
        const items = results()
        if (event.key === Qt.Key_Escape) {
            controller.close()
            event.accepted = true
        } else if (event.key === Qt.Key_Left) {
            selectedIndex = navigation.grid(selectedIndex, -1, 0, grid.columns, items.length)
            event.accepted = true
        } else if (event.key === Qt.Key_Right) {
            selectedIndex = navigation.grid(selectedIndex, 1, 0, grid.columns, items.length)
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            selectedIndex = navigation.grid(selectedIndex, 0, -1, grid.columns, items.length)
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            selectedIndex = navigation.grid(selectedIndex, 0, 1, grid.columns, items.length)
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (items[selectedIndex]) copy(items[selectedIndex].glyph)
            event.accepted = true
        }
    }

    focus: true
    Keys.onPressed: event => handleGridKey(event)

    Navigation { id: navigation }

    Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 10

        TextField {
            id: search
            width: parent.width
            focus: true
            placeholderText: "Pesquisar emoji…"
            onTextChanged: {
                panel.query = text
                panel.selectedIndex = 0
            }
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Down) {
                    panel.focusGrid()
                    event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    const items = panel.results()
                    if (items[panel.selectedIndex]) panel.copy(items[panel.selectedIndex].glyph)
                    event.accepted = true
                } else if (event.key === Qt.Key_Escape) {
                    panel.controller.close()
                    event.accepted = true
                }
            }
            KeyNavigation.tab: grid
            color: theme.colors.foreground
            placeholderTextColor: theme.colors.mutedForeground
            font.family: Design.fontFamily
            font.pixelSize: Design.fontSizeSm
            background: Rectangle {
                radius: Design.radiusSm
                color: theme.colors.surfaceVariant
                border.width: search.activeFocus ? 2 : 0
                border.color: search.activeFocus ? theme.colors.accent : theme.colors.outline
            }
        }

        GridView {
            id: grid
            property int columns: Math.max(1, Math.floor(width / cellWidth))
            width: parent.width
            height: 220
            cellWidth: 58
            cellHeight: 58
            model: panel.results()
            currentIndex: panel.selectedIndex
            activeFocusOnTab: true
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: event => panel.handleGridKey(event)
            KeyNavigation.backtab: search
            onCurrentIndexChanged: if (currentIndex >= 0) positionViewAtIndex(currentIndex, GridView.Contain)

            delegate: Rectangle {
                required property var modelData
                required property int index
                width: 50
                height: 50
                radius: Design.radiusSm
                color: panel.selectedIndex === index ? theme.colors.surfaceActive : pointer.containsMouse ? theme.colors.surfaceHover : theme.colors.surfaceVariant
                border.width: panel.selectedIndex === index ? 2 : 0
                border.color: theme.colors.accent

                Text { anchors.centerIn: parent; text: modelData.glyph; font.pixelSize: 24 }

                MouseArea {
                    id: pointer
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: panel.selectedIndex = index
                    onClicked: panel.copy(modelData.glyph)
                }
            }
        }
    }

    Component.onCompleted: takeInitialFocus()
}
