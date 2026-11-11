import QtQuick
import ".."

Rectangle {
    id: choice
    required property var theme
    property string label: ""
    property string status: ""
    property var options: []
    property var catalog: ({})
    property string variant: "dark"
    property string value: "wallpaper"
    property int cursor: Math.max(0, options.indexOf(value))
    readonly property int columns: 4
    signal changed(string value)

    implicitHeight: 40 + grid.height + Design.spacingSm
    activeFocusOnTab: true
    radius: Design.radiusSm
    color: theme.colors.surfaceVariant
    onValueChanged: cursor = Math.max(0, options.indexOf(value))
    onActiveFocusChanged: if (!activeFocus) cursor = Math.max(0, options.indexOf(value))

    function swatches(name) {
        const entry = catalog[name]
        const palette = entry ? entry[variant] : null
        return palette ? [palette.background, palette.accent, palette.secondary, palette.tertiary] : []
    }

    function title(name) {
        const entry = catalog[name]
        return entry ? entry.name : I18n.tr("themeSettings.paletteWallpaper")
    }

    Keys.onPressed: event => {
        let next = cursor
        if (event.key === Qt.Key_Left) next = Math.max(0, cursor - 1)
        else if (event.key === Qt.Key_Right) next = Math.min(options.length - 1, cursor + 1)
        else if (event.key === Qt.Key_Up && cursor >= columns) next = cursor - columns
        else if (event.key === Qt.Key_Down && cursor + columns < options.length) next = cursor + columns
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            if (options[cursor] !== value) changed(options[cursor])
            event.accepted = true
            return
        } else return
        cursor = next
        event.accepted = true
    }

    StatusIcon {
        anchors {
            left: parent.left
            leftMargin: Design.spacingMd
            top: parent.top
            topMargin: Design.spacingSm
        }
        name: "image"
        iconSize: Design.iconSm
        color: choice.theme.colors.foreground
    }

    Text {
        anchors {
            left: parent.left
            leftMargin: 40
            top: parent.top
            topMargin: Design.spacingSm
        }
        text: choice.label
        color: choice.theme.colors.foreground
        font.family: Design.fontFamily
        font.pixelSize: Design.fontSizeSm
        font.weight: Design.fontWeightMedium
    }

    Text {
        anchors {
            right: parent.right
            rightMargin: Design.spacingMd
            top: parent.top
            topMargin: Design.spacingSm
        }
        text: choice.status
        visible: text.length > 0
        color: choice.theme.colors.mutedForeground
        font.family: Design.fontFamily
        font.pixelSize: Design.fontSizeXs
    }

    Grid {
        id: grid
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: 34
            leftMargin: Design.spacingSm
            rightMargin: Design.spacingSm
        }
        columns: choice.columns
        spacing: Design.spacingXs
        readonly property real cellWidth: (width - spacing * (columns - 1)) / columns

        Repeater {
            model: choice.options

            Rectangle {
                id: card
                required property string modelData
                required property int index
                readonly property bool selected: modelData === choice.value
                readonly property bool cursorTarget: choice.activeFocus && index === choice.cursor
                width: grid.cellWidth
                height: 48
                radius: Design.radiusXs
                color: selected ? choice.theme.colors.accentDim : choice.theme.colors.surfaceElevated
                border.width: cursorTarget && !selected ? 1 : 0
                border.color: choice.theme.colors.outline
                Behavior on color { ColorAnimation { duration: Design.animationFast; easing.type: Design.easingMorph } }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: choice.theme.colors.foreground
                    opacity: pointer.pressed ? .09 : pointer.containsMouse ? .045 : 0
                    Behavior on opacity { NumberAnimation { duration: Design.animationFast; easing.type: Design.easingMorph } }
                }

                Row {
                    id: swatchRow
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 8
                    spacing: 3
                    visible: card.modelData !== "wallpaper"

                    Repeater {
                        model: choice.swatches(card.modelData)

                        Rectangle {
                            required property string modelData
                            width: 12
                            height: 12
                            radius: 6
                            color: modelData
                            border.width: 1
                            border.color: Qt.rgba(choice.theme.colors.foreground.r, choice.theme.colors.foreground.g, choice.theme.colors.foreground.b, .18)
                        }
                    }
                }

                StatusIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 5
                    visible: card.modelData === "wallpaper"
                    name: "image"
                    iconSize: Design.iconSm
                    color: choice.theme.colors.accent
                }

                Text {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        bottomMargin: 6
                        leftMargin: 4
                        rightMargin: 4
                    }
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: choice.title(card.modelData)
                    color: choice.theme.colors.foreground
                    font.family: Design.fontFamily
                    font.pixelSize: Design.fontSizeXs
                    font.weight: card.selected ? Design.fontWeightSemibold : Design.fontWeightMedium
                }

                MouseArea {
                    id: pointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        choice.forceActiveFocus(Qt.MouseFocusReason)
                        choice.cursor = card.index
                        if (card.modelData !== choice.value) choice.changed(card.modelData)
                    }
                }
            }
        }
    }
}
