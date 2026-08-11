import QtQuick
import QtQuick.Controls
import "../components"

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
        Text { text: "Área de transferência"; color: panel.theme.colors.foreground; font { pixelSize: 18; bold: true } }
        Row { width: parent.width; spacing: 8
            TextField { width: parent.width - clear.width - 8; height: 42; leftPadding: 14; placeholderText: "Pesquisar na área de transferência…"; color: panel.theme.colors.foreground; placeholderTextColor: panel.theme.colors.mutedForeground; onTextChanged: panel.query = text; background: Rectangle { radius: 13; color: panel.theme.colors.surfaceVariant; border.width: 1; border.color: panel.theme.colors.outline } }
            ShellButton { id: clear; theme: panel.theme; text: "Limpar"; iconName: "edit-clear"; onClicked: panel.clipboard.clear() }
        }
        ListView { width: parent.width; height: Math.max(120, parent.height - 104); model: panel.results(); clip: true; spacing: 6
            delegate: Rectangle { required property var modelData; width: ListView.view.width; height: 54; radius: 14; color: panel.theme.colors.surfaceVariant; border.width: 1; border.color: panel.theme.colors.outline
                ShellIcon { anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter } name: "edit-paste"; iconSize: 20 }
                Text { anchors { left: parent.left; right: deleteButton.left; verticalCenter: parent.verticalCenter; leftMargin: 45; rightMargin: 8 } text: modelData.text.replace(/\n/g, " "); elide: Text.ElideRight; color: panel.theme.colors.foreground; font.pixelSize: 11 }
                ShellButton { id: deleteButton; anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 7 } theme: panel.theme; compact: true; iconName: "edit-clear"; onClicked: panel.clipboard.remove(modelData.id) }
                MouseArea { anchors { left: parent.left; right: deleteButton.left; top: parent.top; bottom: parent.bottom } onClicked: panel.clipboard.select(modelData.id) }
            }
            Text { anchors.centerIn: parent; visible: parent.count === 0; text: "A área de transferência está vazia"; color: panel.theme.colors.mutedForeground }
        }
    }
    Component.onCompleted: clipboard.refresh()
}
