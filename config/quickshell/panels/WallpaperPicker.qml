import QtQuick
import QtQuick.Layouts
import "../components"
import ".."

FocusScope {
    id: panel
    required property var controller
    required property var theme
    required property var appService
    readonly property var filteredWallpapers: filterWallpapers(controller.wallpaperEntries, controller.wallpaperQuery)
    property bool initialSelectionPending: true

    function normalized(value) {
        const lowered = Design.safeText(value, "").toLowerCase()
        const decomposed = lowered.normalize ? lowered.normalize("NFD") : lowered
        return decomposed.replace(/[\u0300-\u036f]/g, "").replace(/[-_]+/g, " ").replace(/\s+/g, " ").trim()
    }

    function filterWallpapers(entries, query) {
        const source = Array.isArray(entries) ? entries : []
        const terms = normalized(query).split(" ").filter(term => term.length > 0)
        if (!terms.length) return source.slice()
        return source.filter(path => {
            const filename = normalized(Design.safeText(path, "").split("/").pop().replace(/\.[^.]+$/, ""))
            return terms.every(term => filename.indexOf(term) >= 0)
        })
    }

    function currentWallpaperIndex() {
        const current = Design.safeText(controller.wallpaperCurrent, "")
        return current ? filteredWallpapers.indexOf(current) : -1
    }

    function clampSelection() {
        const count = filteredWallpapers.length
        controller.wallpaperResultCount = count
        controller.wallpaperSelectedIndex = count > 0 ? Math.max(0, Math.min(controller.wallpaperSelectedIndex, count - 1)) : 0
    }

    function focusGrid() {
        if (!filteredWallpapers.length) {
            searchInput.forceActiveFocus(Qt.TabFocusReason)
            return
        }
        initialSelectionPending = false
        grid.forceActiveFocus(Qt.TabFocusReason)
        controller.wallpaperFocusTarget = "grid"
        grid.positionViewAtIndex(controller.wallpaperSelectedIndex, GridView.Contain)
    }

    function focusSearch() {
        searchInput.forceActiveFocus(Qt.TabFocusReason)
        controller.wallpaperFocusTarget = "search"
    }

    function moveSelection(horizontal, vertical) {
        const count = filteredWallpapers.length
        if (!count) return
        initialSelectionPending = false
        controller.wallpaperSelectedIndex = navigation.grid(controller.wallpaperSelectedIndex, horizontal, vertical, grid.columns, count)
        grid.positionViewAtIndex(controller.wallpaperSelectedIndex, GridView.Contain)
    }

    function applySelected() {
        const index = controller.wallpaperSelectedIndex
        if (index < 0 || index >= filteredWallpapers.length) return
        const path = Design.safeText(filteredWallpapers[index], "")
        if (!path) return
        if (controller.developmentMode) {
            controller.showOsd("Papel de parede", path.split("/").pop())
            return
        }
        controller.run([controller.rootDir + "/scripts/wallpaper", "set", path])
        controller.close()
    }

    function handleGridKey(event) {
        if (event.key === Qt.Key_Escape) {
            controller.close()
            event.accepted = true
        } else if (event.key === Qt.Key_Left) {
            moveSelection(-1, 0)
            event.accepted = true
        } else if (event.key === Qt.Key_Right) {
            moveSelection(1, 0)
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            moveSelection(0, -1)
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            moveSelection(0, 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            applySelected()
            event.accepted = true
        }
    }

    function takeInitialFocus() {
        initialSelectionPending = true
        Qt.callLater(() => filteredWallpapers.length ? focusGrid() : focusSearch())
    }

    function initialFocusReady() {
        return grid.activeFocus || searchInput.activeFocus || refreshButton.activeFocus || clearButton.activeFocus
    }

    focus: true
    Keys.onEscapePressed: event => {
        controller.close()
        event.accepted = true
    }

    Navigation { id: navigation }

    Column {
        anchors.fill: parent
        anchors.margins: Design.spacingLg
        spacing: Design.spacingMd

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
                id: refreshButton
                Layout.preferredWidth: implicitWidth
                theme: panel.theme
                text: "Atualizar"
                iconName: "refresh"
                compact: true
                onClicked: panel.appService.refreshWallpapers()
                KeyNavigation.tab: grid
                KeyNavigation.backtab: clearButton.visible ? clearButton : searchInput
                onActiveFocusChanged: if (activeFocus) panel.controller.wallpaperFocusTarget = "refresh"
            }
        }

        Rectangle {
            id: searchBox
            width: parent.width
            height: 42
            radius: Design.radiusSm
            color: searchInput.activeFocus ? panel.theme.colors.surfaceActive : panel.theme.colors.surfaceVariant
            border.width: searchInput.activeFocus ? 1 : 0
            border.color: panel.theme.colors.accent

            StatusIcon {
                id: searchIcon
                anchors.left: parent.left
                anchors.leftMargin: Design.spacingMd
                anchors.verticalCenter: parent.verticalCenter
                name: "search"
                iconSize: Design.iconSm
                color: panel.theme.colors.mutedForeground
            }

            TextInput {
                id: searchInput
                anchors {
                    left: searchIcon.right
                    right: clearButton.left
                    top: parent.top
                    bottom: parent.bottom
                    leftMargin: Design.spacingSm
                    rightMargin: Design.spacingSm
                }
                text: panel.controller.wallpaperQuery
                color: panel.theme.colors.foreground
                selectionColor: panel.theme.colors.accent
                selectedTextColor: panel.theme.colors.background
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeSm
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                onTextChanged: if (text !== panel.controller.wallpaperQuery) panel.controller.wallpaperQuery = text
                Keys.priority: Keys.BeforeItem
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Down) {
                        panel.focusGrid()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        panel.applySelected()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Escape) {
                        panel.controller.close()
                        event.accepted = true
                    }
                }
                KeyNavigation.tab: clearButton.visible ? clearButton : refreshButton
                KeyNavigation.backtab: grid
                onActiveFocusChanged: if (activeFocus) panel.controller.wallpaperFocusTarget = "search"
            }

            Text {
                anchors {
                    left: searchInput.left
                    right: searchInput.right
                    verticalCenter: parent.verticalCenter
                }
                visible: searchInput.text.length === 0
                text: "Pesquisar papel de parede..."
                color: panel.theme.colors.mutedForeground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeSm
                elide: Text.ElideRight
            }

            ShellButton {
                id: clearButton
                anchors.right: parent.right
                anchors.rightMargin: Design.spacingXs
                anchors.verticalCenter: parent.verticalCenter
                visible: searchInput.text.length > 0
                width: visible ? 34 : 0
                theme: panel.theme
                iconName: "close"
                compact: true
                onClicked: {
                    panel.controller.wallpaperQuery = ""
                    searchInput.forceActiveFocus(Qt.MouseFocusReason)
                }
                KeyNavigation.tab: refreshButton
                KeyNavigation.backtab: searchInput
                onActiveFocusChanged: if (activeFocus) panel.controller.wallpaperFocusTarget = "clear"
            }
        }

        GridView {
            id: grid
            property int columns: width >= 760 ? 4 : width >= 500 ? 3 : 2
            width: parent.width
            height: Math.max(0, parent.height - header.height - searchBox.height - parent.spacing * 2)
            cellWidth: width / columns
            cellHeight: Math.max(112, Math.min(142, cellWidth * .66))
            clip: true
            model: panel.filteredWallpapers
            currentIndex: panel.controller.wallpaperSelectedIndex
            onCurrentIndexChanged: if (currentIndex >= 0) positionViewAtIndex(currentIndex, GridView.Contain)
            activeFocusOnTab: true
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: event => panel.handleGridKey(event)
            KeyNavigation.tab: searchInput
            KeyNavigation.backtab: refreshButton
            onActiveFocusChanged: if (activeFocus) panel.controller.wallpaperFocusTarget = "grid"

            delegate: Item {
                required property var modelData
                required property int index
                width: GridView.view.cellWidth
                height: GridView.view.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: Design.spacingXs
                    radius: Design.radiusSm
                    color: panel.theme.colors.surfaceVariant
                    border.width: panel.controller.wallpaperSelectedIndex === index ? (grid.activeFocus ? 3 : 2) : Design.safeText(modelData, "") === panel.controller.wallpaperCurrent ? 1 : 0
                    border.color: panel.controller.wallpaperSelectedIndex === index ? panel.theme.colors.accent : panel.theme.colors.foreground
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
                        color: pointer.containsMouse && panel.controller.wallpaperSelectedIndex !== index ? panel.theme.colors.surfaceHover : "transparent"
                        opacity: .28
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: grid.activeFocus && panel.controller.wallpaperSelectedIndex === index
                        color: panel.theme.colors.accentDim
                        opacity: .16
                    }

                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: 30
                        color: "#b0000000"
                    }

                    Text {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Design.spacingSm }
                        text: Design.safeText(modelData, "Papel de parede").split("/").pop().replace(/\.[^.]+$/, "") + (Design.safeText(modelData, "") === panel.controller.wallpaperCurrent ? " · Atual" : "")
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
                    onClicked: {
                        panel.controller.wallpaperSelectedIndex = index
                        panel.focusGrid()
                        panel.applySelected()
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: parent.count === 0
                text: panel.controller.wallpaperQuery.length ? "Nenhum papel de parede encontrado" : "Nenhum papel de parede em ~/Imagens/Wallpapers"
                color: panel.theme.colors.mutedForeground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeSm
            }
        }
    }

    onFilteredWallpapersChanged: {
        const currentIndex = currentWallpaperIndex()
        if (initialSelectionPending && !controller.wallpaperQuery.length && currentIndex >= 0) controller.wallpaperSelectedIndex = currentIndex
        clampSelection()
        if (!filteredWallpapers.length) Qt.callLater(() => focusSearch())
        if (initialSelectionPending && filteredWallpapers.length && !searchInput.activeFocus) Qt.callLater(() => focusGrid())
    }
    Component.onCompleted: {
        appService.refreshWallpapers()
        clampSelection()
        takeInitialFocus()
    }
}
