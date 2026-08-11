import QtQuick
import Quickshell.Services.Mpris

Item {
    id: service
    visible: false
    required property var controller
    readonly property var players: Mpris.players.values || []
    readonly property var selectedPlayer: {
        for (let i = 0; i < players.length; i++) {
            if (players[i] && players[i].isPlaying) return players[i]
        }
        return players.length > 0 ? players[0] : null
    }
    onSelectedPlayerChanged: controller.mediaPlayer = selectedPlayer
    Timer {
        interval: 1000
        repeat: true
        running: service.selectedPlayer !== null && service.selectedPlayer.isPlaying
        onTriggered: {
            if (service.selectedPlayer && service.selectedPlayer.positionSupported) service.selectedPlayer.positionChanged()
        }
    }
    Component.onCompleted: controller.mediaPlayer = selectedPlayer
}
