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
    property string configError: ""
    property string themeError: ""
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
        const source = Design.safeText(raw, "")
        if (!source) return
        const parsed = JSON.parse(source)
        if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) throw new Error("a raiz deve ser um objeto JSON")
        const currentShell = shellController.config.shell
        const incomingShell = parsed.shell || {}
        shellController.config = {
            shell: Object.assign({}, currentShell, incomingShell, {
                widgets: Object.assign({}, currentShell.widgets, incomingShell.widgets || {})
            })
        }
        configError = ""
    }
    function applyTheme(raw: string): void {
        const source = Design.safeText(raw, "")
        if (!source) return
        const parsed = JSON.parse(source)
        if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) throw new Error("a raiz deve ser um objeto JSON")
        shellTheme.colors = Object.assign({}, shellTheme.colors, parsed)
        shellTheme.generatedLoaded = true
        themeError = ""
    }
    function reloadConfig(): void {
        try { applyConfig(configFile.text()) }
        catch (error) {
            const message = String(error)
            if (message !== configError) console.warn("hyprism config inválida; mantendo o último estado válido:", message)
            configError = message
        }
    }
    function reloadTheme(): void {
        try { applyTheme(themeFile.text()) }
        catch (error) {
            const message = String(error)
            if (message !== themeError) console.warn("hyprism theme inválido; mantendo o último estado válido:", message)
            themeError = message
        }
    }
    function fullscreenScreens(): var {
        const names = []
        const screens = Quickshell.screens || []
        for (let index = 0; index < screens.length; index++) {
            if (HyprlandService.monitorHasFullscreen(screens[index])) names.push(screens[index].name)
        }
        return names
    }

    Theme { id: shellTheme }
    ShellController { id: shellController }
    SystemService { controller: shellController }
    MediaService { controller: shellController }
    AppService { id: appService; controller: shellController }
    ClipboardService { id: clipboardService; controller: shellController }
    IpcHandler {
        target: "shell"
        function openHub(): void { shellController.openHub(root.focusedScreenName()) }
        function toggleHub(): void { shellController.toggleHub(root.focusedScreenName()) }
        function toggleLauncher(): void { shellController.toggleLauncher(root.focusedScreenName()) }
        function toggleClipboard(): void { shellController.toggleClipboard(root.focusedScreenName()) }
        function toggleWallpaperPicker(): void { shellController.toggleWallpaperPicker(root.focusedScreenName()) }
        function toggleNetwork(): void { shellController.toggleNetwork(root.focusedScreenName()) }
        function togglePowerMenu(): void { shellController.togglePowerMenu(root.focusedScreenName()) }
        function toggleEmojiPicker(): void { shellController.toggleEmojiPicker(root.focusedScreenName()) }
        function switcherForward(): void {
            if (shellController.mode !== "switcher") shellController.targetScreenName = root.focusedScreenName()
            shellController.switcher(1)
        }
        function switcherBackward(): void {
            if (shellController.mode !== "switcher") shellController.targetScreenName = root.focusedScreenName()
            shellController.switcher(-1)
        }
        function switcherCommit(): void { shellController.commitSwitcher() }
        function togglePowerSaver(): void { shellController.togglePowerSaver() }
        function randomWallpaper(): void { shellController.run([shellController.rootDir + "/scripts/wallpaper", "random"]) }
        function close(): void { shellController.close() }
        function themeChanged(image: string): void { shellController.showOsd("Tema", "Atualizado") }
        function reload(): void { Quickshell.reload(true) }
        function status(): string {
            return JSON.stringify({
                running: true,
                pid: Quickshell.processId,
                mode: shellController.mode,
                targetScreen: shellController.targetScreenName,
                panelFocusReady: shellController.panelFocusReady,
                fullscreenScreens: root.fullscreenScreens(),
                screenCount: Quickshell.screens.length,
                primaryScreen: root.focusedScreenName(),
                themeLoaded: true,
                themeSource: shellTheme.sourceName,
                themeAccent: shellTheme.colors.accent,
                islandWidth: shellController.config.shell.islandWidth,
                configError: root.configError,
                themeError: root.themeError,
                islandLoaded: root.islandLoaded,
                widgetsLoaded: root.widgetsLoaded,
                notificationServer: root.notificationServerReady,
                systemService: shellController.systemServiceAvailable
            })
        }
    }
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
        id: configFile
        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/hyprism/user.json"
        blockLoading: true
        preload: true
        watchChanges: true
        printErrors: false
        onLoaded: configReload.restart()
        onTextChanged: configReload.restart()
        onFileChanged: reload()
    }
    FileView {
        id: themeFile
        path: shellTheme.cacheDir + "/theme/theme.json"
        blockLoading: true
        preload: true
        watchChanges: true
        printErrors: false
        onLoaded: themeReload.restart()
        onTextChanged: themeReload.restart()
        onFileChanged: reload()
    }
    Timer { id: configReload; interval: 90; onTriggered: root.reloadConfig() }
    Timer { id: themeReload; interval: 90; onTriggered: root.reloadTheme() }

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
