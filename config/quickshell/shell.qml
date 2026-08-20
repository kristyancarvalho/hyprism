//@ pragma ShellId hyprism
//@ pragma DefaultEnv QT_QUICK_BACKEND = software
//@ pragma IconTheme Hyprism-Papirus
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
    readonly property bool developmentMode: Quickshell.env("HYPRISM_DEVELOPMENT") === "1"
    property string notificationScreenName: ""
    property var popupNotifications: []
    property var popupDeadlines: ({})
    property var notificationHistory: []
    property int popupOverflowCount: 0
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
        const deadlines = Object.assign({}, popupDeadlines)
        delete deadlines[notificationKey(notification)]
        popupDeadlines = deadlines
        if (!popupNotifications.length) popupOverflowCount = 0
        notificationServer.newest = popupNotifications.length ? popupNotifications[popupNotifications.length - 1] : null
    }

    function dismissPopup(notification): void {
        removePopup(notification)
        if (!notification) return
        if (notification.dismiss) notification.dismiss()
        if (notification.tracked !== undefined) notification.tracked = false
    }

    function expirePopup(notification): void {
        removePopup(notification)
        if (notification && notification.expire) notification.expire()
    }

    function notificationKey(notification): string {
        return notification ? String(notification.id) : ""
    }

    function storeNotification(notification): void {
        if (!notification) return
        const key = notificationKey(notification)
        const next = notificationHistory.filter(item => item && notificationKey(item) !== key)
        notificationHistory = [{
            id: notification.id,
            appName: Design.safeText(notification.appName, "Notificação"),
            appIcon: Design.safeText(notification.appIcon, ""),
            desktopEntry: Design.safeText(notification.desktopEntry, ""),
            summary: Design.safeText(notification.summary, "Notificação"),
            body: Design.safeText(notification.body, ""),
            urgency: Design.safeNumber(notification.urgency, 1),
            receivedAt: Date.now(),
            source: notification
        }].concat(next).slice(0, Design.notificationHistoryLimit)
    }

    function removeHistoryNotification(notification): void {
        if (!notification) return
        const key = notificationKey(notification)
        notificationHistory = notificationHistory.filter(item => item && notificationKey(item) !== key)
        const source = notification.source
        if (source) removePopup(source)
        if (source && source.dismiss && source.tracked && source.lastGeneration !== false) source.dismiss()
        if (source && source.tracked !== undefined) source.tracked = false
    }

    function clearNotificationHistory(): void {
        const current = notificationHistory.slice()
        notificationHistory = []
        const sources = current.map(notification => notification ? notification.source : null)
        popupNotifications = popupNotifications.filter(notification => sources.indexOf(notification) < 0)
        popupDeadlines = ({})
        popupOverflowCount = 0
        notificationServer.newest = null
        for (let index = 0; index < current.length; index++) {
            const notification = current[index]
            if (!notification) continue
            const source = notification.source
            if (source && source.dismiss && source.tracked && source.lastGeneration !== false) source.dismiss()
            if (source && source.tracked !== undefined) source.tracked = false
        }
    }

    function popupLimit(): int {
        return notificationScreen && notificationScreen.height < 700 ? 3 : 4
    }

    function popupDuration(notification): int {
        const requested = notification ? Design.safeNumber(notification.expireTimeout, 0) : 0
        return requested > 0 ? Math.round(Design.clamp(requested, 3000, 10000)) : 6500
    }

    function showPopup(notification): void {
        const existing = popupNotifications.filter(item => item && item.id !== notification.id && item.lastGeneration !== false)
        const next = existing.concat([notification])
        const limit = popupLimit()
        if (next.length > limit) popupOverflowCount += next.length - limit
        popupNotifications = next.slice(-limit)
        const previousDeadlines = popupDeadlines
        const deadlines = {}
        const now = Date.now()
        for (let index = 0; index < popupNotifications.length; index++) {
            const item = popupNotifications[index]
            const key = notificationKey(item)
            deadlines[key] = item === notification ? now + popupDuration(item) : Design.safeNumber(previousDeadlines[key], now + popupDuration(item))
        }
        popupDeadlines = deadlines
        notificationServer.newest = notification
    }

    function expireDuePopups(): void {
        const now = Date.now()
        const current = popupNotifications.slice()
        for (let index = 0; index < current.length; index++) {
            const notification = current[index]
            if (now >= Design.safeNumber(popupDeadlines[notificationKey(notification)], now + popupDuration(notification))) expirePopup(notification)
        }
    }

    function developmentNotification(identifier, index, summary, body): var {
        return {
            id: identifier,
            tracked: true,
            lastGeneration: true,
            expireTimeout: 10000,
            appName: index % 2 === 0 ? "Hyprism" : "Aplicativo de teste",
            appIcon: "",
            desktopEntry: "",
            summary: summary,
            body: body,
            urgency: index === 3 ? 2 : 1,
            actions: [],
            dismiss: function() { this.tracked = false },
            expire: function() {}
        }
    }

    function syncTrackedPopups(): void {
        popupNotifications = popupNotifications.filter(notification => notification && notification.tracked && notification.lastGeneration !== false)
        const deadlines = {}
        const now = Date.now()
        for (let index = 0; index < popupNotifications.length; index++) {
            const notification = popupNotifications[index]
            const key = notificationKey(notification)
            deadlines[key] = Design.safeNumber(popupDeadlines[key], now + popupDuration(notification))
        }
        popupDeadlines = deadlines
        if (!popupNotifications.length) popupOverflowCount = 0
        notificationServer.newest = popupNotifications.length ? popupNotifications[popupNotifications.length - 1] : null
    }
    function applyConfig(raw: string): void {
        const source = Design.safeText(raw, "")
        if (!source) return
        const parsed = JSON.parse(source)
        if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) throw new Error("a raiz deve ser um objeto JSON")
        const incomingShell = parsed.shell || {}
        const defaultShell = shellController.defaultShellConfig()
        shellController.config = {
            shell: Object.assign({}, defaultShell, incomingShell, {
                widgetLayout: Object.assign({}, defaultShell.widgetLayout, incomingShell.widgetLayout || {}),
                widgets: shellController.mergedWidgetConfig(incomingShell.widgets || {})
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
    function widgetStatus(): var {
        const result = {}
        const names = Object.keys(shellController.widgetDefaults)
        for (let index = 0; index < names.length; index++) result[names[index]] = shellController.widgetEnabled(names[index])
        return result
    }

    Theme { id: shellTheme }
    ShellController { id: shellController }
    SystemService { controller: shellController }
    MonitoringService { controller: shellController }
    MediaService { controller: shellController }
    AppService { id: appService; controller: shellController }
    ClipboardService { id: clipboardService; controller: shellController }
    RecordingService { id: recordingService; controller: shellController }
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
        function toggleRecording(): void { shellController.toggleRecording(root.focusedScreenName()) }
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
                systemService: shellController.systemServiceAvailable,
                switcherCount: shellController.switcherWindows.length,
                switcherIndex: shellController.switcherIndex,
                switcherAddress: shellController.switcherWindows[shellController.switcherIndex] ? shellController.switcherWindows[shellController.switcherIndex].address : "",
                wallpaperQuery: shellController.wallpaperQuery,
                wallpaperResultCount: shellController.wallpaperResultCount,
                wallpaperSelectedIndex: shellController.wallpaperSelectedIndex,
                wallpaperFocusTarget: shellController.wallpaperFocusTarget,
                popupCount: root.popupNotifications.length,
                popupOverflowCount: root.popupOverflowCount,
                notificationHistoryCount: root.notificationHistory.length,
                clipboardCount: shellController.clipboardEntries.length,
                switcherMetadata: shellController.switcherWindows.map(item => ({ address: item.address, appId: item.appId, initialClass: item.initialClass, icon: item.icon, applicationName: item.applicationName, title: item.title })),
                widgets: root.widgetStatus(),
                widgetLayoutPosition: shellController.widgetLayoutPosition(),
                monitoring: shellController.monitoring,
                taskCount: shellController.tasks.length,
                recording: shellController.recording,
                recordingPending: shellController.recordingPending,
                recordingSelecting: shellController.recordingSelecting,
                recordingMode: shellController.recordingMode,
                recordingElapsed: shellController.recordingElapsed,
                recordingOutputPath: shellController.recordingOutputPath,
                recordingProcessId: shellController.recordingProcessId
            })
        }
    }
    IpcHandler {
        target: "tasks"
        function add(payload: string): string { return shellController.upsertTask(payload) }
        function update(identifier: string, payload: string): void { shellController.updateTask(identifier, payload) }
        function finish(identifier: string): void { shellController.finishTask(identifier, false) }
        function fail(identifier: string): void { shellController.finishTask(identifier, true) }
        function remove(identifier: string): void { shellController.removeTask(identifier) }
        function list(): string { return JSON.stringify(shellController.tasks) }
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
    IpcHandler {
        target: "development"
        function mockNotifications(count: int): void {
            if (!root.developmentMode) return
            root.notificationScreenName = root.focusedScreenName()
            const total = Math.max(1, Math.min(8, count))
            for (let index = 0; index < total; index++) {
                const sequence = Date.now() + index
                const notification = root.developmentNotification(
                    sequence,
                    index,
                    index === 1 ? "Uma notificação com título longo para validar a elipse" : "Notificação " + (index + 1),
                    index === 2 ? "Este texto ocupa mais de uma linha para validar altura, espaçamento e limite do conteúdo sem cobrir os outros cartões." : "Conteúdo de teste seguro"
                )
                root.storeNotification(notification)
                root.showPopup(notification)
            }
        }
        function mockReplacement(): void {
            if (!root.developmentMode) return
            root.notificationScreenName = root.focusedScreenName()
            const identifier = Date.now()
            const first = root.developmentNotification(identifier, 0, "Transferência em andamento", "25% concluído")
            const replacement = root.developmentNotification(identifier, 0, "Transferência em andamento", "75% concluído")
            root.storeNotification(first)
            root.showPopup(first)
            root.storeNotification(replacement)
            root.showPopup(replacement)
        }
        function clearNotifications(): void {
            if (!root.developmentMode) return
            root.popupNotifications = []
            root.popupDeadlines = ({})
            root.popupOverflowCount = 0
            root.notificationHistory = []
            notificationServer.newest = null
        }
        function dismissNewestToast(): void {
            if (!root.developmentMode || !root.popupNotifications.length) return
            root.dismissPopup(root.popupNotifications[root.popupNotifications.length - 1])
        }
        function clearNotificationHistory(): void {
            if (!root.developmentMode) return
            root.clearNotificationHistory()
        }
        function mockClipboard(): void {
            if (!root.developmentMode) return
            shellController.clipboardEntries = [
                { id: "1", type: "text", text: "Trecho de texto copiado para validar a lista", searchText: "trecho texto", mime: "text/plain;charset=utf-8", thumbnail: "", width: 0, height: 0 },
                { id: "2", type: "image", text: "Imagem · 1920×1080", searchText: "imagem png 1920×1080", mime: "image/png", thumbnail: "file://" + shellController.rootDir + "/wallpapers/abyss.png", width: 1920, height: 1080 },
                { id: "3", type: "text", text: "Outro item de texto", searchText: "outro item texto", mime: "text/plain;charset=utf-8", thumbnail: "", width: 0, height: 0 },
                { id: "4", type: "image", text: "Imagem · 1200×800", searchText: "imagem png 1200×800", mime: "image/png", thumbnail: "file://" + shellController.rootDir + "/wallpapers/ember.png", width: 1200, height: 800 }
            ]
        }
        function wallpaperSearch(query: string): void {
            if (!root.developmentMode) return
            shellController.wallpaperQuery = query
        }
        function mockTask(): void {
            if (!root.developmentMode) return
            shellController.upsertTask(JSON.stringify({ id: "development", title: "Preparando tema", subtitle: "Aplicando nova paleta", progress: 64, status: "running", eta: 45, source: "Hyprism" }))
        }
        function openRecordingSelector(): void {
            if (!root.developmentMode) return
            shellController.openRecording(root.focusedScreenName())
        }
        function selectRecordingRegion(): void {
            if (!root.developmentMode) return
            shellController.startRegionRecording()
        }
        function mockRecording(mode: string): void {
            if (!root.developmentMode) return
            recordingService.startDevelopment(mode)
        }
        function stopMockRecording(): void {
            if (!root.developmentMode) return
            recordingService.stop()
        }
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
    Timer { interval: 250; repeat: true; running: root.popupNotifications.length > 0; onTriggered: root.expireDuePopups() }

    NotificationServer {
        id: notificationServer
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
        property var newest: null
        property var historyNotifications: root.notificationHistory
        function removeHistory(notification: var): void { root.removeHistoryNotification(notification) }
        function clearHistory(): void { root.clearNotificationHistory() }
        onNotification: notification => {
            notification.tracked = true
            root.notificationScreenName = root.focusedScreenName()
            root.storeNotification(notification)
            root.showPopup(notification)
        }
        onTrackedNotificationsChanged: root.syncTrackedPopups()
        Component.onCompleted: root.notificationServerReady = true
    }

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
            overflowCount: root.popupOverflowCount
            suppressed: shellController.mode === "control"
            controller: shellController
            theme: shellTheme
            onDismissRequested: notification => root.dismissPopup(notification)
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
