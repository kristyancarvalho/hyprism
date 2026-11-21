import QtQuick
import ".."

Glass {
    id: card
    required property var controller
    readonly property bool playing: controller.mediaPlayer !== null && controller.mediaPlayer.isPlaying
    surfaceOpacity: Design.themedSurfaceOpacity(.88)
    radius: Design.radiusMd

    Row {
        anchors.fill: parent
        anchors.margins: Design.widgetInnerPadding
        spacing: Design.spacingMd

        Rectangle {
            width: 86
            height: 86
            anchors.verticalCenter: parent.verticalCenter
            radius: Design.radiusSm
            color: card.theme.colors.surfaceVariant
            clip: true

            RoundedImage { id: art; anchors.fill: parent; source: card.controller.mediaArtUrl(); fillMode: Image.PreserveAspectCrop; asynchronous: true; cache: true; radius: parent.radius }
            ShellIcon { anchors.centerIn: parent; visible: art.status !== Image.Ready; name: card.controller.applicationIcon(card.controller.mediaPlayer ? card.controller.mediaPlayer.desktopEntry : ""); fallback: "application-x-executable"; fallbackGlyph: "media"; iconSize: 42 }
        }

        Column {
            width: parent.width - 98
            anchors.verticalCenter: parent.verticalCenter
            spacing: Design.spacingXs

            Text { width: parent.width; text: card.controller.mediaTitle(); elide: Text.ElideRight; color: card.theme.colors.foreground; font.family: Design.fontFamily; font.pixelSize: Design.fontSizeSm; font.weight: Design.fontWeightSemibold }
            Text { width: parent.width; text: card.controller.mediaArtist(); elide: Text.ElideRight; color: card.theme.colors.mutedForeground; font.family: Design.fontFamily; font.pixelSize: Design.fontSizeXs }
            Rectangle { width: parent.width; height: 4; radius: Design.radiusSmall; color: card.theme.colors.surfaceVariant; Rectangle { width: parent.width * card.controller.mediaProgress(); height: parent.height; radius: parent.radius; color: card.theme.colors.accent } }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Design.spacingXs
                ShellButton { theme: card.theme; compact: true; iconName: "previous"; onClicked: card.controller.mediaPrevious() }
                ShellButton { theme: card.theme; compact: true; iconName: card.playing ? "pause" : "play"; onClicked: card.controller.mediaToggle() }
                ShellButton { theme: card.theme; compact: true; iconName: "next"; onClicked: card.controller.mediaNext() }
            }
        }
    }
}
