import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import "services"
import "panels"
import "widgets"
import "osd"

ShellRoot {
    id: root

    property bool islandLoaded: false
    property bool widgetsLoaded: false
    property bool notificationServerReady: false
    readonly property bool hyprlandAvailable: !!Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")
    property var selectedScreen: null
    function refreshSelectedScreen(): void {
        const screens = Quickshell.screens
        if (!screens || screens.length === 0) {
            selectedScreen = null
            return
        }
        const preferred = shellController.config.shell.primaryMonitor || ""
        const focused = hyprlandAvailable && Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
        for (let i = 0; focused && i < screens.length; i++) {
            if (screens[i].name === focused) { selectedScreen = screens[i]; return }
        }
        for (let i = 0; preferred && preferred !== "focused" && i < screens.length; i++) {
            if (screens[i].name === preferred) { selectedScreen = screens[i]; return }
        }
        selectedScreen = screens[0]
    }
    function selectedScreenName(): string {
        return selectedScreen ? selectedScreen.name : ""
    }

    Theme { id: shellTheme }
    ShellController { id: shellController }
    SystemService { controller: shellController }
    AppService { id: appService; controller: shellController }
    ClipboardService { id: clipboardService; controller: shellController }
    IpcHandler {
        target: "shell"
        function toggleControlCenter(): void { shellController.toggle("control") }
        function toggleNetwork(): void { shellController.toggle("network") }
        function togglePowerSaver(): void { shellController.togglePowerSaver() }
        function close(): void { shellController.close() }
        function themeChanged(image: string): void { shellController.showOsd("Theme", "Updated") }
        function reload(): void { Quickshell.reload(true) }
        function status(): string {
            return JSON.stringify({
                running: true,
                pid: Quickshell.processId,
                mode: shellController.mode,
                screenCount: Quickshell.screens.length,
                primaryScreen: root.selectedScreenName(),
                themeLoaded: true,
                themeSource: shellTheme.sourceName,
                islandLoaded: root.islandLoaded,
                widgetsLoaded: root.widgetsLoaded,
                notificationServer: root.notificationServerReady,
                systemService: shellController.systemServiceAvailable
            })
        }
    }
    IpcHandler { target: "app-launcher"; function toggle(): void { shellController.toggle("launcher") } }
    IpcHandler { target: "wallpaper-picker"; function toggle(): void { shellController.toggle("wallpaper") } }
    IpcHandler { target: "wallpaper"; function random(): void { shellController.run(["sh", "-lc", shellController.rootDir + "/scripts/wallpaper random"]) } }
    IpcHandler { target: "clipboard"; function toggle(): void { shellController.toggle("clipboard") } }
    IpcHandler {
        target: "window-switcher"
        function forward(): void { shellController.switcher(1) }
        function backward(): void { shellController.switcher(-1) }
        function commit(): void { shellController.commitSwitcher() }
    }
    IpcHandler { target: "notifications"; function toggle(): void { shellController.toggle("control") } }
    IpcHandler { target: "power-menu"; function toggle(): void { shellController.toggle("power") } }
    IpcHandler { target: "emoji-picker"; function toggle(): void { shellController.toggle("emoji") } }
    IpcHandler {
        target: "osd"
        function volume(value: string): void { shellController.showOsd("Volume", value) }
        function brightness(value: string): void { shellController.showOsd("Brightness", value) }
        function microphone(value: string): void { shellController.showOsd("Microphone", value) }
        function screenshot(value: string): void { shellController.showOsd("Screenshot", value.split("/").pop()) }
        function color(value: string): void { shellController.showOsd("Color", value) }
        function night(value: string): void { shellController.showOsd("Night mode", value) }
        function power(value: string): void { shellController.showOsd("Power saver", value) }
    }

    FileView {
        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/hyprism/user.json"
        blockLoading: true
        preload: true
        watchChanges: true
        printErrors: false
        onLoaded: {
            try { shellController.config = JSON.parse(text()) }
            catch (error) { console.warn("hyprism config: using defaults:", error) }
        }
        onTextChanged: {
            try { shellController.config = JSON.parse(text()) }
            catch (error) { console.warn("hyprism config update ignored:", error) }
        }
        onFileChanged: reload()
    }
    FileView {
        path: shellTheme.cacheDir + "/theme/theme.json"
        blockLoading: true
        preload: true
        watchChanges: true
        printErrors: false
        onLoaded: {
            try { shellTheme.colors = JSON.parse(text()); shellTheme.generatedLoaded = true }
            catch (error) { console.warn("hyprism theme: using fallback:", error) }
        }
        onTextChanged: {
            try { shellTheme.colors = JSON.parse(text()); shellTheme.generatedLoaded = true }
            catch (error) { console.warn("hyprism theme update ignored:", error) }
        }
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
        onNotification: notification => {
            notification.tracked = true
            newest = notification
            popupTimer.restart()
        }
        Component.onCompleted: root.notificationServerReady = true
    }
    Timer { id: popupTimer; interval: 6500; onTriggered: notificationServer.newest = null }
    Timer {
        interval: 500
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refreshSelectedScreen()
    }

    LazyLoader {
        active: root.selectedScreen !== null
        Island {
            shellScreen: root.selectedScreen
            controller: shellController
            theme: shellTheme
            apps: appService
            clipboard: clipboardService
            notifications: notificationServer
            Component.onCompleted: root.islandLoaded = true
        }
    }
    LazyLoader {
        active: root.selectedScreen !== null
        DesktopWidgets {
            shellScreen: root.selectedScreen
            controller: shellController
            theme: shellTheme
            Component.onCompleted: root.widgetsLoaded = true
        }
    }
    LazyLoader {
        active: root.selectedScreen !== null
        NotificationPopup {
            shellScreen: root.selectedScreen
            notification: notificationServer.newest
            controller: shellController
            theme: shellTheme
        }
    }
    LazyLoader {
        active: root.selectedScreen !== null
        OsdWindow {
            shellScreen: root.selectedScreen
            controller: shellController
            theme: shellTheme
        }
    }
}
