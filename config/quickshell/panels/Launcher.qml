import QtQuick
import QtQuick.Controls
import "../components"

Item {
    id: panel
    required property var controller
    required property var theme
    property string query: ""
    property int selected: 0

    function score(app) {
        const haystack = (app.name + " " + app.comment).toLowerCase()
        const needle = query.toLowerCase()
        if (!needle) return 1
        let at = 0
        for (let i = 0; i < needle.length; i++) {
            at = haystack.indexOf(needle[i], at)
            if (at < 0) return -1
            at++
        }
        return 100 - haystack.indexOf(needle[0])
    }
    function results() { return controller.appEntries.filter(app => score(app) >= 0).sort((a,b) => score(b) - score(a)).slice(0, 9) }
    function launch(app) { if (!app) return; controller.run(["sh", "-lc", app.exec]); controller.close() }

    focus: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) { controller.close(); event.accepted = true }
        else if (event.key === Qt.Key_Down) { selected = Math.min(selected + 1, results().length - 1); event.accepted = true }
        else if (event.key === Qt.Key_Up) { selected = Math.max(selected - 1, 0); event.accepted = true }
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { launch(results()[selected]); event.accepted = true }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 12

        Row {
            id: header
            width: parent.width
            Text { width: parent.width - hint.width; text: "Aplicativos"; color: panel.theme.colors.foreground; font { pixelSize: 18; bold: true } }
            Text { id: hint; text: "↑↓ navegar  ·  Enter abrir"; color: panel.theme.colors.mutedForeground; font.pixelSize: 10 }
        }

        Item {
            width: parent.width
            height: 46
            TextField {
                id: search
                anchors.fill: parent
                focus: true
                leftPadding: 46
                rightPadding: 14
                placeholderText: "Pesquisar aplicativos…"
                color: panel.theme.colors.foreground
                placeholderTextColor: panel.theme.colors.mutedForeground
                font.pixelSize: 14
                background: Rectangle { radius: 15; color: panel.theme.colors.surfaceVariant; border.color: search.activeFocus ? panel.theme.colors.accent : panel.theme.colors.outline; border.width: 1 }
                onTextChanged: { panel.query = text; panel.selected = 0 }
            }
            ShellIcon { anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter } name: "edit-find"; iconSize: 20 }
        }

        ListView {
            width: parent.width
            height: Math.max(0, parent.height - header.height - search.height - 24)
            clip: true
            model: panel.results()
            spacing: 5

            delegate: Rectangle {
                required property var modelData
                required property int index
                width: ListView.view.width
                height: 56
                radius: 14
                color: panel.selected === index ? panel.theme.colors.accentDim : indexMouse.containsMouse ? panel.theme.colors.surfaceVariant : "transparent"
                border.width: panel.selected === index ? 1 : 0
                border.color: panel.theme.colors.accent

                Row {
                    anchors.fill: parent
                    anchors.margins: 9
                    spacing: 12
                    ShellIcon { anchors.verticalCenter: parent.verticalCenter; name: modelData.icon || "application-x-executable"; fallback: "application-x-executable"; iconSize: 30; framed: true; frameColor: panel.theme.colors.surface }
                    Column {
                        width: parent.width - 58
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text { width: parent.width; text: modelData.name; elide: Text.ElideRight; color: panel.theme.colors.foreground; font { pixelSize: 13; weight: Font.DemiBold } }
                        Text { width: parent.width; visible: modelData.comment.length > 0; text: modelData.comment; elide: Text.ElideRight; color: panel.theme.colors.mutedForeground; font.pixelSize: 10 }
                    }
                }

                MouseArea { id: indexMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panel.launch(modelData); onEntered: panel.selected = index }
            }

            Text { anchors.centerIn: parent; visible: parent.count === 0; text: "Nenhum aplicativo encontrado"; color: panel.theme.colors.mutedForeground }
        }
    }

    Component.onCompleted: search.forceActiveFocus()
}
