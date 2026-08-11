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
        let haystack = (app.name + " " + app.comment).toLowerCase(), needle = query.toLowerCase()
        if (!needle) return 1
        let at = 0; for (let i = 0; i < needle.length; i++) { at = haystack.indexOf(needle[i], at); if (at < 0) return -1; at++ }
        return 100 - haystack.indexOf(needle[0])
    }
    function results() { return controller.appEntries.filter(app => score(app) >= 0).sort((a,b) => score(b) - score(a)).slice(0, 8) }
    function launch(app) { if (!app) return; controller.run(["sh", "-lc", app.exec]); controller.close() }
    focus: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) { controller.close(); event.accepted = true }
        else if (event.key === Qt.Key_Down) { selected = Math.min(selected + 1, results().length - 1); event.accepted = true }
        else if (event.key === Qt.Key_Up) { selected = Math.max(selected - 1, 0); event.accepted = true }
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { launch(results()[selected]); event.accepted = true }
    }
    Column {
        anchors.fill: parent; anchors.margins: 18; spacing: 10
        TextField {
            id: search; width: parent.width; focus: true; placeholderText: "Search applications…"; color: panel.theme.colors.foreground
            placeholderTextColor: panel.theme.colors.mutedForeground; font.pixelSize: 15
            background: Rectangle { radius: 12; color: panel.theme.colors.surfaceVariant; border.color: panel.theme.colors.outline; border.width: 1 }
            onTextChanged: { panel.query = text; panel.selected = 0 }
        }
        ListView {
            width: parent.width; height: 322; clip: true; model: panel.results(); spacing: 4
            delegate: Rectangle {
                required property var modelData; required property int index
                width: ListView.view.width; height: 42; radius: 10
                color: panel.selected === index ? panel.theme.colors.accentDim : "transparent"
                Row { anchors.fill: parent; anchors.margins: 8; spacing: 10
                    Text { width: 26; text: "◈"; color: panel.theme.colors.accent; font.pixelSize: 17; verticalAlignment: Text.AlignVCenter }
                    Column { width: parent.width - 44; anchors.verticalCenter: parent.verticalCenter
                        Text { width: parent.width; text: modelData.name; elide: Text.ElideRight; color: panel.theme.colors.foreground; font.pixelSize: 13 }
                        Text { width: parent.width; text: modelData.comment; elide: Text.ElideRight; color: panel.theme.colors.mutedForeground; font.pixelSize: 10 }
                    }
                }
                MouseArea { anchors.fill: parent; onClicked: panel.launch(modelData); onEntered: panel.selected = index }
            }
            Text { anchors.centerIn: parent; visible: parent.count === 0; text: "No matching applications"; color: panel.theme.colors.mutedForeground }
        }
    }
    Component.onCompleted: search.forceActiveFocus()
}
