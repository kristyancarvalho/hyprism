import QtQuick
import QtQuick.Controls

Item {
    id: panel
    required property var controller
    required property var theme
    required property var clipboard
    property string query: ""
    function results() { return controller.clipboardEntries.filter(item => item.text.toLowerCase().indexOf(query.toLowerCase()) >= 0) }
    focus: true
    Keys.onPressed: event => { if (event.key === Qt.Key_Escape) { controller.close(); event.accepted = true } }
    Column {
        anchors.fill: parent; anchors.margins: 18; spacing: 10
        Row { width: parent.width; spacing: 8
            TextField { width: parent.width - clear.width - 8; placeholderText: "Search clipboard…"; color: panel.theme.colors.foreground; placeholderTextColor: panel.theme.colors.mutedForeground; onTextChanged: panel.query = text; background: Rectangle { radius: 10; color: panel.theme.colors.surfaceVariant } }
            Button { id: clear; text: "Clear"; onClicked: panel.clipboard.clear() }
        }
        ListView { width: parent.width; height: 300; model: panel.results(); clip: true; spacing: 5
            delegate: Rectangle { required property var modelData; width: ListView.view.width; height: 48; radius: 10; color: panel.theme.colors.surfaceVariant
                Text { anchors { left: parent.left; right: deleteButton.left; verticalCenter: parent.verticalCenter; leftMargin: 10; rightMargin: 8 } text: modelData.text.replace(/\n/g, " "); elide: Text.ElideRight; color: panel.theme.colors.foreground; font.pixelSize: 11 }
                Button { id: deleteButton; anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 4 } text: "×"; onClicked: panel.clipboard.remove(modelData.id) }
                MouseArea { anchors { left: parent.left; right: deleteButton.left; top: parent.top; bottom: parent.bottom } onClicked: panel.clipboard.select(modelData.id) }
            }
            Text { anchors.centerIn: parent; visible: parent.count === 0; text: "Clipboard history is empty"; color: panel.theme.colors.mutedForeground }
        }
    }
    Component.onCompleted: clipboard.refresh()
}
