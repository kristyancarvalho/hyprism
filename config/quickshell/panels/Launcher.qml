import QtQuick
import QtQuick.Controls
import "../components"
import ".."

Item {
    id: panel
    required property var controller
    required property var theme
    property string query: ""
    property int selected: 0

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
        return controller.appEntries.filter(app => score(app) >= 0).sort((first, second) => score(second) - score(first)).slice(0, 9)
    }

    function launch(app) {
        if (!app || !Design.safeText(app.exec, "")) return
        controller.run(["sh", "-lc", app.exec])
        controller.close()
    }

    focus: true
    Keys.onPressed: event => {
        const count = results().length
        if (event.key === Qt.Key_Escape) {
            controller.close()
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            selected = navigation.wrap(selected, 1, count)
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            selected = navigation.wrap(selected, -1, count)
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            launch(results()[selected])
            event.accepted = true
        }
    }

    Navigation { id: navigation }

    Column {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 12

        Row {
            id: header
            width: parent.width

            Text {
                width: parent.width - hint.width
                text: "Aplicativos"
                color: panel.theme.colors.foreground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeLg
                font.weight: Design.fontWeightSemibold
            }

            Text {
                id: hint
                text: "↑ ↓ navegar  ·  Enter abrir"
                color: panel.theme.colors.mutedForeground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeXs
            }
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
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeMd
                background: Rectangle {
                    radius: Design.radiusSm
                    color: panel.theme.colors.surfaceVariant
                    border.color: search.activeFocus ? panel.theme.colors.accent : panel.theme.colors.outline
                    border.width: search.activeFocus ? 2 : 1
                }
                onTextChanged: {
                    panel.query = text
                    panel.selected = 0
                }
            }

            StatusIcon {
                anchors {
                    left: parent.left
                    leftMargin: 14
                    verticalCenter: parent.verticalCenter
                }
                name: "search"
                iconSize: Design.iconMd
                color: panel.theme.colors.mutedForeground
            }
        }

        ListView {
            id: resultList
            width: parent.width
            height: Math.max(0, parent.height - header.height - search.height - 24)
            clip: true
            model: panel.results()
            currentIndex: panel.selected
            spacing: 5
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

            delegate: Rectangle {
                required property var modelData
                required property int index
                width: ListView.view.width
                height: 56
                radius: Design.radiusSm
                color: panel.selected === index ? panel.theme.colors.surfaceActive : pointer.containsMouse ? panel.theme.colors.surfaceHover : "transparent"
                border.width: panel.selected === index ? 2 : 0
                border.color: panel.theme.colors.accent

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
                    onEntered: panel.selected = index
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

    Component.onCompleted: search.forceActiveFocus()
}
