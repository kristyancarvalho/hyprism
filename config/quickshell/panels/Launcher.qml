import QtQuick
import QtQuick.Layouts
import "../components"
import ".."

Item {
    id: panel
    required property var controller
    required property var theme
    property string query: ""
    property int selected: 0
    readonly property var resultModel: results()
    readonly property int resultCount: resultModel.length

    function score(app) {
        const name = Design.safeText(app ? app.name : "", "")
        const comment = Design.safeText(app ? app.comment : "", "")
        const haystack = (name + " " + comment).toLowerCase()
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

    function results() {
        return controller.appEntries.filter(app => score(app) >= 0).sort((first, second) => score(second) - score(first)).slice(0, 60)
    }

    function launch(app) {
        controller.launchApplication(app)
    }

    function takeInitialFocus() {
        search.forceInputFocus(Qt.ShortcutFocusReason)
    }

    function initialFocusReady() {
        return search.inputActiveFocus
    }

    function handleKey(event) {
        const count = resultCount
        if (event.key === Qt.Key_Escape) {
            controller.close()
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            navigation.useKeyboard()
            selected = navigation.wrap(selected, 1, count)
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            navigation.useKeyboard()
            selected = navigation.wrap(selected, -1, count)
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            launch(resultModel[selected])
            event.accepted = true
        }
    }

    focus: true
    Keys.onPressed: event => handleKey(event)
    onResultCountChanged: {
        selected = navigation.clamp(selected, resultCount)
        controller.launcherResultCount = resultCount
    }

    Navigation { id: navigation }

    Column {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 12

        RowLayout {
            id: header
            width: parent.width
            spacing: Design.spacingMd

            Text {
                Layout.fillWidth: true
                text: "Aplicativos"
                color: panel.theme.colors.foreground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeLg
                font.weight: Design.fontWeightSemibold
            }

            Text {
                id: hint
                Layout.preferredWidth: implicitWidth
                text: "↑ ↓ navegar  ·  Enter abrir"
                color: panel.theme.colors.mutedForeground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeXs
            }
        }

        SearchField {
            id: search
            width: parent.width
            height: 46
            theme: panel.theme
            placeholderText: "Pesquisar aplicativos…"
            onTextChanged: {
                panel.query = text
                panel.selected = 0
                navigation.keyboardNavigation = false
            }
            onKeyPressed: event => panel.handleKey(event)
            onClearRequested: text = ""
        }

        ListView {
            id: resultList
            width: parent.width
            height: Math.max(Design.launcherResultRowHeight, parent.height - header.height - search.height - 24)
            clip: true
            model: panel.resultModel
            currentIndex: panel.selected
            spacing: 5
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

            SelectionHighlight {
                parent: resultList.contentItem
                theme: panel.theme
                target: resultList.currentItem
                active: navigation.keyboardNavigation && panel.resultCount > 0
            }

            delegate: Item {
                id: resultDelegate
                required property var modelData
                required property int index
                width: ListView.view.width
                height: Design.launcherResultRowHeight
                z: 2

                DelegateSurface {
                    host: resultList.contentItem
                    target: resultDelegate
                    theme: panel.theme
                    hovered: pointer.containsMouse && !navigation.keyboardNavigation
                }

                Row {
                    anchors.fill: parent
                    anchors.margins: 9
                    spacing: 12

                    ShellIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: Design.safeText(modelData.icon, "application-x-executable")
                        fallback: "application-x-executable"
                        iconSize: 30
                        framed: true
                        frameColor: panel.theme.colors.surface
                    }

                    Column {
                        width: parent.width - 58
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            width: parent.width
                            text: Design.safeText(modelData.name, "Aplicativo")
                            elide: Text.ElideRight
                            color: panel.theme.colors.foreground
                            font.family: Design.fontFamily
                            font.pixelSize: Design.fontSizeSm
                            font.weight: Design.fontWeightSemibold
                        }

                        Text {
                            width: parent.width
                            visible: text.length > 0
                            text: Design.safeText(modelData.comment, "")
                            elide: Text.ElideRight
                            color: panel.theme.colors.mutedForeground
                            font.family: Design.fontFamily
                            font.pixelSize: Design.fontSizeXs
                        }
                    }
                }

                MouseArea {
                    id: pointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: panel.launch(modelData)
                    onEntered: {
                        navigation.usePointer()
                        panel.selected = index
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: parent.count === 0
                text: "Nenhum aplicativo encontrado"
                color: panel.theme.colors.mutedForeground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeSm
            }
        }
    }

    Component.onCompleted: {
        controller.launcherResultCount = resultCount
        takeInitialFocus()
    }
}
