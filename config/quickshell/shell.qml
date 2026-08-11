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
    IpcHandler { target: "shell"
        function toggleControlCenter(): void { controller.toggle("control") }
        function toggleNetwork(): void { controller.toggle("network") }
        function togglePowerSaver(): void { controller.togglePowerSaver() }
        function close(): void { controller.close() }
        function themeChanged(image: string): void { controller.showOsd("Theme", "Updated") }
        function reload(): void { controller.run(["sh", "-lc", "~/.local/share/hyprism/scripts/system/reload-shell"]) }
    }
    IpcHandler { target: "app-launcher"; function toggle(): void { controller.toggle("launcher") } }
    IpcHandler { target: "wallpaper-picker"; function toggle(): void { controller.toggle("wallpaper") } }
    IpcHandler { target: "wallpaper"; function random(): void { controller.run(["sh", "-lc", "~/.local/share/hyprism/scripts/wallpaper random"]) } }
    IpcHandler { target: "clipboard"; function toggle(): void { controller.toggle("clipboard") } }
    IpcHandler { target: "window-switcher"; function forward(): void { controller.switcher(1) } function backward(): void { controller.switcher(-1) } function commit(): void { controller.commitSwitcher() } }
    IpcHandler { target: "notifications"; function toggle(): void { controller.toggle("control") } }
    IpcHandler { target: "power-menu"; function toggle(): void { controller.toggle("power") } }
    IpcHandler { target: "emoji-picker"; function toggle(): void { controller.toggle("emoji") } }
    IpcHandler { target: "osd"
        function volume(value: string): void { controller.showOsd("Volume", value) }
        function brightness(value: string): void { controller.showOsd("Brightness", value) }
        function microphone(value: string): void { controller.showOsd("Microphone", value) }
        function screenshot(value: string): void { controller.showOsd("Screenshot", value.split("/").pop()) }
        function color(value: string): void { controller.showOsd("Color", value) }
        function night(value: string): void { controller.showOsd("Night mode", value) }
        function power(value: string): void { controller.showOsd("Power saver", value) }
    }
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
