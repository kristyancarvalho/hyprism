import QtQuick
import QtQuick.Controls

Item {
    id: panel
    required property var controller
    required property var theme
    property string query: ""
    property var emojis: [
        {glyph:"😀",name:"sorriso"},{glyph:"😂",name:"alegria"},{glyph:"❤️",name:"coração"},{glyph:"👍",name:"positivo"},{glyph:"✨",name:"brilho"},{glyph:"🔥",name:"fogo"},{glyph:"🎉",name:"festa"},{glyph:"🚀",name:"foguete"},{glyph:"✅",name:"correto"},{glyph:"❌",name:"errado"},{glyph:"⚡",name:"raio"},{glyph:"🎵",name:"música"}
    ]
    function results() { return emojis.filter(item => item.name.indexOf(query.toLowerCase()) >= 0) }
    function copy(glyph) { controller.run(["sh", "-lc", "printf %s " + "'" + glyph + "' | wl-copy"]); controller.showOsd("Emoji", glyph); controller.close() }
    focus: true
    Keys.onPressed: event => { if (event.key === Qt.Key_Escape) { controller.close(); event.accepted = true } }
    Column { anchors.fill: parent; anchors.margins: 18; spacing: 10
        TextField { width: parent.width; focus: true; placeholderText: "Pesquisar emoji…"; onTextChanged: panel.query = text; color: theme.colors.foreground; placeholderTextColor: theme.colors.mutedForeground; background: Rectangle { radius: 10; color: theme.colors.surfaceVariant } }
        GridView { width: parent.width; height: 220; cellWidth: 58; cellHeight: 58; model: panel.results()
            delegate: Rectangle { required property var modelData; width: 50; height: 50; radius: 12; color: theme.colors.surfaceVariant
                Text { anchors.centerIn: parent; text: modelData.glyph; font.pixelSize: 24 }
                MouseArea { anchors.fill: parent; onClicked: panel.copy(modelData.glyph) }
            }
        }
    }
}
