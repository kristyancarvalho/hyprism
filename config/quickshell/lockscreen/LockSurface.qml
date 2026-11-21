import QtQuick
import Quickshell.Wayland
import ".."

WlSessionLockSurface {
    id: surface
    required property var lock
    required property var session
    required property var controller
    required property var theme
    required property var enabledWidgets
    required property string background
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

        LockWidgets {
            controller: surface.controller
            theme: surface.theme
            enabledWidgets: surface.enabledWidgets
            availableWidth: root.width - Design.spacingLg * 4
            availableHeight: Math.max(0, root.height - Design.compactReservedHeight(surface.controller.config.shell) - Design.spacingLg * 4)
            visible: surface.session.secure && (topRow || showMedia || bottomRow)
            opacity: 1 - surface.session.morphProgress
            anchors.horizontalCenter: parent.horizontalCenter
            y: Design.compactReservedHeight(surface.controller.config.shell) + Math.max(Design.spacingLg, (availableHeight - height) * .42)
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
