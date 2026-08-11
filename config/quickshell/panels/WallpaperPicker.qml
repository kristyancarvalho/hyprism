import QtQuick
import "../components"

Item {
    id: panel
    required property var controller
    required property var theme
    required property var appService
    function apply(path) { controller.run([controller.rootDir + "/scripts/wallpaper", "set", path]); controller.close() }
    focus: true
    Keys.onPressed: event => { if (event.key === Qt.Key_Escape) { controller.close(); event.accepted = true } }

    Column {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 14

        Row {
            id: header
            width: parent.width
            Text { width: parent.width - refresh.width; anchors.verticalCenter: parent.verticalCenter; text: "Papéis de parede"; color: panel.theme.colors.foreground; font { pixelSize: 18; bold: true } }
            ShellButton { id: refresh; theme: panel.theme; text: "Atualizar"; iconName: "view-refresh"; compact: true; onClicked: panel.appService.refreshWallpapers() }
        }

        GridView {
            id: grid
            property int columns: width >= 760 ? 4 : width >= 500 ? 3 : 2
            width: parent.width
            height: Math.max(0, parent.height - header.height - 14)
            cellWidth: width / columns
            cellHeight: Math.max(118, Math.min(158, cellWidth * .66))
            clip: true
            model: panel.controller.wallpaperEntries

            delegate: Item {
                required property var modelData
                width: GridView.view.cellWidth
                height: GridView.view.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: 16
                    color: panel.theme.colors.surfaceVariant
                    border.width: wallpaperMouse.containsMouse ? 2 : 1
                    border.color: wallpaperMouse.containsMouse ? panel.theme.colors.accent : panel.theme.colors.outline
                    clip: true

                    Image { anchors.fill: parent; source: "file://" + modelData; fillMode: Image.PreserveAspectCrop; asynchronous: true; cache: true }
                    Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 30; color: "#b0000000" }
                    Text { anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 8 } text: modelData.split("/").pop().replace(/\.[^.]+$/, ""); color: "white"; elide: Text.ElideRight; font { pixelSize: 10; weight: Font.Medium } }
                }

                MouseArea { id: wallpaperMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panel.apply(modelData) }
            }

            Text { anchors.centerIn: parent; visible: parent.count === 0; text: "Nenhum papel de parede em ~/Imagens/Wallpapers"; color: panel.theme.colors.mutedForeground }
        }
    }

    Component.onCompleted: appService.refreshWallpapers()
}
