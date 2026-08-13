import QtQuick
import QtQuick.Layouts
import "../components"
import ".."

Item {
    id: panel
    required property var controller
    required property var theme
    required property var appService
    property int selectedIndex: 0

    function apply(path) {
        if (!Design.safeText(path, "")) return
        controller.run([controller.rootDir + "/scripts/wallpaper", "set", path])
        controller.close()
    }

    focus: true
    Keys.onPressed: event => {
        const count = controller.wallpaperEntries.length
        if (event.key === Qt.Key_Escape) {
            controller.close()
            event.accepted = true
        } else if (event.key === Qt.Key_Left) {
            selectedIndex = navigation.grid(selectedIndex, -1, 0, grid.columns, count)
            event.accepted = true
        } else if (event.key === Qt.Key_Right) {
            selectedIndex = navigation.grid(selectedIndex, 1, 0, grid.columns, count)
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            selectedIndex = navigation.grid(selectedIndex, 0, -1, grid.columns, count)
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            selectedIndex = navigation.grid(selectedIndex, 0, 1, grid.columns, count)
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            apply(controller.wallpaperEntries[selectedIndex])
            event.accepted = true
        }
    }

    Navigation { id: navigation }

    Column {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 14

        RowLayout {
            id: header
            width: parent.width
            spacing: Design.spacingMd

            Text {
                Layout.fillWidth: true
                text: "Papéis de parede"
                color: panel.theme.colors.foreground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeLg
                font.weight: Design.fontWeightSemibold
                elide: Text.ElideRight
            }

            ShellButton {
                id: refresh
                Layout.preferredWidth: implicitWidth
                theme: panel.theme
                text: "Atualizar"
                iconName: "refresh"
                compact: true
                onClicked: panel.appService.refreshWallpapers()
            }
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
            currentIndex: panel.selectedIndex
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)

            delegate: Item {
                required property var modelData
                required property int index
                width: GridView.view.cellWidth
                height: GridView.view.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: Design.radiusSm
                    color: panel.theme.colors.surfaceVariant
                    border.width: panel.selectedIndex === index ? 2 : 0
                    border.color: panel.theme.colors.accent
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: "file://" + Design.safeText(modelData, "")
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: pointer.containsMouse && panel.selectedIndex !== index ? panel.theme.colors.surfaceHover : "transparent"
                        opacity: .28
                    }

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        height: 30
                        color: "#b0000000"
                    }

                    Text {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                            margins: 8
                        }
                        text: Design.safeText(modelData, "Papel de parede").split("/").pop().replace(/\.[^.]+$/, "")
                        color: "white"
                        elide: Text.ElideRight
                        font.family: Design.fontFamily
                        font.pixelSize: Design.fontSizeXs
                        font.weight: Design.fontWeightMedium
                    }
                }

                MouseArea {
                    id: pointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: panel.selectedIndex = index
                    onClicked: panel.apply(modelData)
                }
            }

            Text {
                anchors.centerIn: parent
                visible: parent.count === 0
                text: "Nenhum papel de parede em ~/Imagens/Wallpapers"
                color: panel.theme.colors.mutedForeground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeSm
            }
        }
    }

    Component.onCompleted: {
        appService.refreshWallpapers()
        forceActiveFocus()
    }
}
