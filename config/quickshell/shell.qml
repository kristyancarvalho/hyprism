import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "services"
import "panels"
import "widgets"
import "osd"
import "notifications"

ShellRoot {
    id: root
    IpcHandler { target: "test"; function ping(): string { return "pong" } }
    Theme { id: theme }
    ShellController { id: controller }
    SystemService { controller: controller }
    AppService { id: apps; controller: controller }
    ClipboardService { id: clipboard; controller: controller }

    FileView {
        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/hyprism/user.json"
        blockLoading: true; preload: true; watchChanges: true; printErrors: false
        onLoaded: { try { controller.config = JSON.parse(text()) } catch (error) { console.warn("hyprism config", error) } }
        onTextChanged: { try { controller.config = JSON.parse(text()) } catch (error) {} }
        onFileChanged: reload()
    }
    FileView {
        path: theme.cacheDir + "/theme/theme.json"
        blockLoading: true; preload: true; watchChanges: true; printErrors: false
        onLoaded: { try { theme.colors = JSON.parse(text()) } catch (error) {} }
        onTextChanged: { try { theme.colors = JSON.parse(text()) } catch (error) {} }
        onFileChanged: reload()
    }

    NotificationServer {
        id: notificationServer
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
        property var newest: null
        onNotification: notification => { notification.tracked = true; newest = notification; popupTimer.restart() }
    }
    Timer { id: popupTimer; interval: 6500; onTriggered: notificationServer.newest = null }


    Island { controller: controller; theme: theme; apps: apps; clipboard: clipboard }
    DesktopWidgets { controller: controller; theme: theme }
    PanelWindow {
        anchors { right: true; top: true }
        margins { top: 18; right: 22 }
        implicitWidth: 330; implicitHeight: notificationServer.newest ? 120 : 0
        color: "transparent"; exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        NotificationCard { anchors.top: parent.top; notification: notificationServer.newest; controller: controller; theme: theme }
    }
    PanelWindow {
        anchors { left: true; right: true; top: true }
        margins.top: controller.config.shell.topMargin + 74
        implicitHeight: 54; color: "transparent"; exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        Osd { anchors.horizontalCenter: parent.horizontalCenter; controller: controller; theme: theme }
    }

}
