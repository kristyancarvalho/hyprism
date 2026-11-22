import QtQuick
import Quickshell.Services.Mpris
import "../components"
import ".."

Glass {
    id: media
    required property var controller
    required property var theme
    required property bool wanted
    readonly property var player: controller.mediaPlayer
    readonly property bool active: wanted && controller.mediaAvailable() && (player.isPlaying || player.playbackState === MprisPlaybackState.Paused)
    readonly property int padding: Design.spacingSm
    surfaceOpacity: Design.themedSurfaceOpacity(.88)
    radius: Design.radiusMd
    visible: active
    width: Math.min(316, parent.width - Design.spacingLg * 2)
    height: strip.implicitHeight + padding * 2

    MediaStrip {
        id: strip
        anchors.fill: parent
        anchors.margins: media.padding
        controller: media.controller
        theme: media.theme
        keyboardControls: false
    }
}
