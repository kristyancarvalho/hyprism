import QtQuick
import Quickshell.Wayland
import ".."

WlSessionLockSurface {
    id: surface
    required property var lock
    required property var session
    required property var controller
    required property var theme
    required property string background
    required property bool weatherEnabled
    required property bool mediaEnabled
    signal surfaceReady()
    color: theme.colors.background

    Item {
        id: root
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => surface.session.handleKey(event)
        Keys.onReleased: event => event.accepted = true

        Component.onCompleted: {
            forceActiveFocus()
            surface.surfaceReady()
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: surface.theme.colors.surfaceVariant }
                GradientStop { position: 1; color: surface.theme.colors.surface }
            }
        }

        Image {
            id: wallpaper
            anchors.fill: parent
            source: surface.background.length > 0 ? "file://" + surface.background : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: false
            cache: false
            smooth: true
            visible: status === Image.Ready
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(surface.theme.colors.background.r, surface.theme.colors.background.g, surface.theme.colors.background.b, wallpaper.visible ? .38 : 0)
        }

        LockClock {
            id: clock
            controller: surface.controller
            theme: surface.theme
            screenHeight: root.height
            visible: surface.session.secure
            opacity: 1 - surface.session.morphProgress
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round((root.height - height) / 2)
        }

        LockDate {
            controller: surface.controller
            theme: surface.theme
            glyphSize: clock.glyphSize
            visible: clock.visible
            opacity: 1 - surface.session.morphProgress
            anchors.horizontalCenter: parent.horizontalCenter
            y: clock.y + clock.height + Design.spacingMd
        }

        LockWeather {
            controller: surface.controller
            theme: surface.theme
            wanted: surface.session.secure && surface.weatherEnabled
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: Design.spacingLg
            anchors.bottomMargin: Design.spacingLg
            opacity: 1 - surface.session.morphProgress
        }

        LockMedia {
            controller: surface.controller
            theme: surface.theme
            wanted: surface.session.secure && surface.mediaEnabled
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Design.spacingLg
            opacity: 1 - surface.session.morphProgress
        }

        LockBattery {
            controller: surface.controller
            theme: surface.theme
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: Design.spacingLg
            anchors.bottomMargin: Design.spacingLg
            opacity: 1 - surface.session.morphProgress
        }

        LockPanel {
            session: surface.session
            controller: surface.controller
            theme: surface.theme
            screenWidth: root.width
        }
    }
}
