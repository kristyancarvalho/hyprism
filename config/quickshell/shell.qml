//@ pragma ShellId hyprism
//@ pragma DefaultEnv QT_QUICK_BACKEND = software
//@ pragma IconTheme Papirus-Dark
pragma ComponentBehavior: Bound

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
    property string notificationScreenName: ""
    property var popupNotifications: []
    readonly property var focusedScreen: screenByName(focusedScreenName())
    readonly property var transientScreen: screenByName(shellController.targetScreenName) || focusedScreen
    readonly property var osdScreen: shellController.mode === "compact" ? focusedScreen : transientScreen
    readonly property var notificationScreen: screenByName(notificationScreenName) || focusedScreen

    function screenByName(name: string): var {
        const screens = Quickshell.screens
        for (let i = 0; screens && i < screens.length; i++) {
            if (screens[i].name === name) return screens[i]
        }
        return null
    }

    function focusedScreenName(): string {
        const focused = hyprlandAvailable && Hyprland.focusedMonitor ? Design.safeText(Hyprland.focusedMonitor.name, "") : ""
        if (screenByName(focused)) return focused
        const preferred = Design.safeText(shellController.config.shell.primaryMonitor, "")
        if (preferred !== "focused" && screenByName(preferred)) return preferred
        return Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0].name : ""
    }

    function prepareTransient(): void {
        shellController.targetScreenName = focusedScreenName()
    }

    function toggleTransient(mode: string): void {
        prepareTransient()
        shellController.toggle(mode)
    }

    function removePopup(notification): void {
        popupNotifications = popupNotifications.filter(item => item && item !== notification)
        notificationServer.newest = popupNotifications.length ? popupNotifications[popupNotifications.length - 1] : null
    }

    function expirePopup(): void {
        if (!popupNotifications.length) return
        popupNotifications = []
        notificationServer.newest = null
    }
    function applyConfig(raw: string): void {
        const parsed = JSON.parse(raw)
        const currentShell = shellController.config.shell
        const incomingShell = parsed.shell || {}
        shellController.config = {
            shell: Object.assign({}, currentShell, incomingShell, {
                widgets: Object.assign({}, currentShell.widgets, incomingShell.widgets || {})
            })
        }
    }
    function applyTheme(raw: string): void {
        shellTheme.colors = Object.assign({}, shellTheme.colors, JSON.parse(raw))
        shellTheme.generatedLoaded = true
    }

    Theme { id: shellTheme }
    ShellController { id: shellController }
    SystemService { controller: shellController }
    MediaService { controller: shellController }
    AppService { id: appService; controller: shellController }
    ClipboardService { id: clipboardService; controller: shellController }
    IpcHandler {
        target: "shell"
        function toggleControlCenter(): void { root.toggleTransient("control") }
        function toggleNetwork(): void { root.toggleTransient("network") }
        function togglePowerSaver(): void { shellController.togglePowerSaver() }
        function close(): void { shellController.close() }
        function themeChanged(image: string): void { shellController.showOsd("Tema", "Atualizado") }
        function reload(): void { Quickshell.reload(true) }
        function status(): string {
            return JSON.stringify({
                running: true,
                pid: Quickshell.processId,
                mode: shellController.mode,
                screenCount: Quickshell.screens.length,
                primaryScreen: root.focusedScreenName(),
                themeLoaded: true,
                themeSource: shellTheme.sourceName,
                islandLoaded: root.islandLoaded,
                widgetsLoaded: root.widgetsLoaded,
                notificationServer: root.notificationServerReady,
                systemService: shellController.systemServiceAvailable
            })
        }
    }
    IpcHandler { target: "app-launcher"; function toggle(): void { root.toggleTransient("launcher") } }
    IpcHandler { target: "wallpaper-picker"; function toggle(): void { root.toggleTransient("wallpaper") } }
    IpcHandler { target: "wallpaper"; function random(): void { shellController.run([shellController.rootDir + "/scripts/wallpaper", "random"]) } }
    IpcHandler { target: "clipboard"; function toggle(): void { root.toggleTransient("clipboard") } }
    IpcHandler {
        target: "window-switcher"
        function forward(): void { if (shellController.mode !== "switcher") root.prepareTransient(); shellController.switcher(1) }
        function backward(): void { if (shellController.mode !== "switcher") root.prepareTransient(); shellController.switcher(-1) }
        function commit(): void { shellController.commitSwitcher() }
    }
    IpcHandler { target: "notifications"; function toggle(): void { root.toggleTransient("control") } }
    IpcHandler { target: "power-menu"; function toggle(): void { root.toggleTransient("power") } }
    IpcHandler { target: "emoji-picker"; function toggle(): void { root.toggleTransient("emoji") } }
    IpcHandler {
        target: "osd"
        function volume(value: string): void { shellController.showOsd("Volume", value) }
        function brightness(value: string): void { shellController.showOsd("Brilho", value) }
        function microphone(value: string): void { shellController.showOsd("Microfone", value) }
        function screenshot(value: string): void { shellController.showOsd("Captura", value.split("/").pop()) }
        function color(value: string): void { shellController.showOsd("Cor", value) }
        function night(value: string): void { shellController.showOsd("Modo noturno", value) }
        function power(value: string): void { shellController.showOsd("Economia de energia", value) }
    }

    FileView {
        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/hyprism/user.json"
        blockLoading: true
        preload: true
        watchChanges: true
        printErrors: false
        onLoaded: {
            try { root.applyConfig(text()) }
            catch (error) { console.warn("hyprism config: using defaults:", error) }
        }
        onTextChanged: {
            try { root.applyConfig(text()) }
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
            try { root.applyTheme(text()) }
            catch (error) { console.warn("hyprism theme: using fallback:", error) }
        }
        onTextChanged: {
            try { root.applyTheme(text()) }
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
            root.notificationScreenName = root.focusedScreenName()
            root.popupNotifications = root.popupNotifications.concat([notification]).slice(-4)
            popupTimer.restart()
        }
        Component.onCompleted: root.notificationServerReady = true
    }
    Timer { id: popupTimer; interval: 6500; onTriggered: root.expirePopup() }

    Variants {
        model: Quickshell.screens

        Island {
            required property var modelData
            shellScreen: modelData
            controller: shellController
            theme: shellTheme
            Component.onCompleted: root.islandLoaded = true
        }
    }

    Variants {
        model: Quickshell.screens

        DesktopWidgets {
            required property var modelData
            shellScreen: modelData
            controller: shellController
            theme: shellTheme
            Component.onCompleted: root.widgetsLoaded = true
        }
    }

    Variants {
        model: Quickshell.screens

        MorphOverlay {
            required property var modelData
            shellScreen: modelData
            controller: shellController
            theme: shellTheme
            apps: appService
            clipboard: clipboardService
            notifications: notificationServer
        }
    }

    LazyLoader {
        active: root.notificationScreen !== null
        NotificationPopup {
            shellScreen: root.notificationScreen
            notifications: root.popupNotifications
            controller: shellController
            theme: shellTheme
            onDismissRequested: notification => root.removePopup(notification)
        }
    }
    LazyLoader {
        active: root.osdScreen !== null
        OsdWindow {
            shellScreen: root.osdScreen
            controller: shellController
            theme: shellTheme
        }
    }
}
