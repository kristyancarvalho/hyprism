import QtQuick
import QtQuick.Controls

Item {
    id: panel
    required property var controller
    required property var theme
    required property var appService
    function apply(path) { controller.run([controller.rootDir + "/scripts/wallpaper", "set", path]); controller.close() }
    focus: true
    Keys.onPressed: event => { if (event.key === Qt.Key_Escape) { controller.close(); event.accepted = true } }
    Column {
        anchors.fill: parent; anchors.margins: 18; spacing: 10
        Row { width: parent.width
            Text { text: "Papéis de parede"; color: panel.theme.colors.foreground; font { pixelSize: 17; bold: true } width: parent.width - refresh.width }
            Button { id: refresh; text: "Atualizar"; onClicked: panel.appService.refreshWallpapers() }
        }
        GridView {
            width: parent.width; height: 352; cellWidth: 148; cellHeight: 118; clip: true; model: panel.controller.wallpaperEntries
            delegate: Item {
                required property var modelData; width: 138; height: 108
                Rectangle { anchors.fill: parent; radius: 12; color: panel.theme.colors.surfaceVariant; border.width: 1; border.color: panel.theme.colors.outline; clip: true
                    Image { anchors.fill: parent; source: "file://" + modelData; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                    Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 25; color: "#a0000000" }
                    Text { anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 6 } text: modelData.split("/").pop(); color: "white"; elide: Text.ElideRight; font.pixelSize: 9 }
                }
                MouseArea { anchors.fill: parent; onClicked: panel.apply(modelData) }
            }
            Text { anchors.centerIn: parent; visible: parent.count === 0; text: "Nenhum papel de parede em ~/Imagens/Wallpapers"; color: panel.theme.colors.mutedForeground }
        }
    }
    Component.onCompleted: appService.refreshWallpapers()
}
