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

    focus: true
    Keys.onPressed: event => {
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

    Component.onCompleted: search.forceActiveFocus()
}
