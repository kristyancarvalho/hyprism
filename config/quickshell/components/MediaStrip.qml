import QtQuick
import ".."

Item {
    id: media
    required property var controller
    required property var theme
    property bool expanded: true
    activeFocusOnTab: true
    implicitWidth: expanded ? 390 : 210
    implicitHeight: expanded ? 60 : Design.barPillHeight

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            controller.mediaToggle()
            event.accepted = true
        } else if (event.key === Qt.Key_Left) {
            controller.mediaPrevious()
            event.accepted = true
        } else if (event.key === Qt.Key_Right) {
            controller.mediaNext()
            event.accepted = true
        }
    }

    Row {
        anchors.fill: parent
        spacing: 10

        Rectangle {
            visible: media.expanded
            width: media.height
            height: media.height
            radius: Design.radiusSm
            color: media.theme.colors.surfaceElevated
            clip: true

            Image {
                id: artwork
                anchors.fill: parent
                source: media.controller.mediaArtUrl()
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
            }

            StatusIcon {
                anchors.centerIn: parent
                visible: artwork.status !== Image.Ready
                name: "media"
                iconSize: Design.iconLg
                color: media.theme.colors.mutedForeground
            }
        }

        Column {
            width: media.expanded ? Math.max(130, parent.width - controls.width - (artwork.parent.visible ? artwork.parent.width + 20 : 10)) : parent.width
            anchors.verticalCenter: parent.verticalCenter
            spacing: media.expanded ? 3 : 0

            Text {
                width: parent.width
                text: media.controller.mediaTitle()
                color: media.theme.colors.foreground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeSm
                font.weight: Design.fontWeightSemibold
                elide: Text.ElideRight
            }

            Text {
                visible: media.expanded
                width: parent.width
                text: media.controller.mediaArtist()
                color: media.theme.colors.mutedForeground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeXs
                elide: Text.ElideRight
            }

            Row {
                visible: media.expanded
                width: parent.width
                spacing: 7

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Design.formatDuration(media.controller.mediaPlayer ? media.controller.mediaPlayer.position : 0)
                    color: media.theme.colors.mutedForeground
                    font.family: Design.fontFamily
                    font.pixelSize: 9
                }

                Rectangle {
                    width: Math.max(40, parent.width - 70)
                    height: 4
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 2
                    color: media.theme.colors.surfaceVariant

                    Rectangle {
                        width: parent.width * media.controller.mediaProgress()
                        height: parent.height
                        radius: parent.radius
                        color: media.theme.colors.accent
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Design.formatDuration(media.controller.mediaPlayer ? media.controller.mediaPlayer.length : 0)
                    color: media.theme.colors.mutedForeground
                    font.family: Design.fontFamily
                    font.pixelSize: 9
                }
            }
        }

        Row {
            id: controls
            visible: media.expanded
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            ShellButton { theme: media.theme; compact: true; iconName: "previous"; onClicked: media.controller.mediaPrevious() }
            ShellButton { theme: media.theme; compact: true; iconName: media.controller.mediaPlayer && media.controller.mediaPlayer.isPlaying ? "pause" : "play"; onClicked: media.controller.mediaToggle() }
            ShellButton { theme: media.theme; compact: true; iconName: "next"; onClicked: media.controller.mediaNext() }
        }
    }
}
