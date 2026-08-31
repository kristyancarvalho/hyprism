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
    property bool doNotDisturb: false
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
            appName: Design.safeText(notification.appName, I18n.tr("notifications.notification")),
            appIcon: Design.safeText(notification.appIcon, ""),
            desktopEntry: Design.safeText(notification.desktopEntry, ""),
            summary: Design.safeText(notification.summary, I18n.tr("notifications.notification")),
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
        if (notificationServer.doNotDisturb) return
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

    function setDoNotDisturb(enabled): void {
        const next = !!enabled
        if (doNotDisturb === next) return
        doNotDisturb = next
        dndStateFile.setText(JSON.stringify({ doNotDisturb: next }) + "\n")
        if (!next) return
        popupNotifications = []
        popupDeadlines = ({})
        popupOverflowCount = 0
        notificationServer.newest = null
    }

    function developmentNotification(identifier, index, summary, body): var {
        return {
            id: identifier,
            tracked: true,
            lastGeneration: true,
            expireTimeout: 10000,
            appName: index % 2 === 0 ? "Hyprism" : I18n.tr("development.testApplication"),
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
        if (doNotDisturb) {
            popupNotifications = []
            popupDeadlines = ({})
            popupOverflowCount = 0
            notificationServer.newest = null
            return
        }
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
    function scheduleMinute(value: string): int {
        const match = /^(\d{2}):(\d{2})$/.exec(Design.safeText(value, ""))
        if (!match) return -1
        const hour = Number(match[1])
        const minute = Number(match[2])
        return hour < 24 && minute < 60 ? hour * 60 + minute : -1
    }
    function nextThemeBoundary(schedule: var): int {
        const light = scheduleMinute(schedule.lightStart)
        const dark = scheduleMinute(schedule.darkStart)
        if (light < 0 || dark < 0 || light === dark) return 0
        const now = new Date()
        const current = now.getHours() * 60 + now.getMinutes() + now.getSeconds() / 60 + now.getMilliseconds() / 60000
        let lightDelay = (light - current + 1440) % 1440
        let darkDelay = (dark - current + 1440) % 1440
        if (lightDelay < .01) lightDelay += 1440
        if (darkDelay < .01) darkDelay += 1440
        return Math.max(1000, Math.round(Math.min(lightDelay, darkDelay) * 60000) + 250)
    }
    function updateThemeSchedule(): void {
        const appearance = shellController.config.appearance || {}
        const schedule = appearance.schedule || {}
        if (!schedule.enabled) {
            themeScheduleReconcile.stop()
            themeScheduleBoundary.stop()
            return
        }
        const delay = nextThemeBoundary(schedule)
        if (delay <= 0) {
            themeScheduleBoundary.stop()
            return
        }
        themeScheduleBoundary.interval = delay
        themeScheduleBoundary.restart()
        themeScheduleReconcile.restart()
    }
    function applyConfig(raw: string): void {
        const source = Design.safeText(raw, "")
        if (!source) return
        const parsed = JSON.parse(source)
        if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) throw new Error("the root must be a JSON object")
        I18n.locale = I18n.supportedLocales.indexOf(parsed.language) >= 0 ? parsed.language : "en"
        const incomingShell = parsed.shell || {}
        const incomingAppearance = parsed.appearance || {}
        const incomingSchedule = incomingAppearance.schedule || {}
        const incomingTemperature = incomingAppearance.whiteTemperature
        const defaultShell = shellController.defaultShellConfig()
        shellController.config = {
            paths: parsed.paths || {},
            appearance: {
                mode: incomingAppearance.mode === "light" ? "light" : "dark",
                whiteTemperature: Number.isInteger(incomingTemperature) && incomingTemperature >= 0 && incomingTemperature <= 3 ? incomingTemperature : incomingAppearance.warmWhite === true ? 2 : 0,
                schedule: {
                    enabled: incomingSchedule.enabled === true,
                    lightStart: Design.safeText(incomingSchedule.lightStart, "07:00"),
                    darkStart: Design.safeText(incomingSchedule.darkStart, "18:00")
                }
            },
            shell: Object.assign({}, defaultShell, incomingShell, {
                widgetLayout: Object.assign({}, defaultShell.widgetLayout, incomingShell.widgetLayout || {}),
                widgets: shellController.mergedWidgetConfig(incomingShell.widgets || {})
            })
        }
        shellController.configurationRevision += 1
        updateThemeSchedule()
        configError = ""
    }
    function applyTheme(raw: string): void {
        const source = Design.safeText(raw, "")
        if (!source) return
        const parsed = JSON.parse(source)
        if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) throw new Error("the root must be a JSON object")
        shellTheme.applyPalette(parsed)
        themeError = ""
    }
    function reloadConfig(): void {
        try { applyConfig(configFile.text()) }
        catch (error) {
            const message = String(error)
            if (message !== configError) console.warn("invalid Hyprism configuration; retaining the last valid state:", message)
            configError = message
        }
    }
    function reloadTheme(): void {
        try { applyTheme(themeFile.text()) }
        catch (error) {
            const message = String(error)
            if (message !== themeError) console.warn("invalid Hyprism theme; retaining the last valid state:", message)
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
        function toggleBluetooth(): void { shellController.toggleBluetoothPanel(root.focusedScreenName()) }
        function openThemeSchedule(): void { shellController.openThemeSchedule(root.focusedScreenName()) }
        function togglePowerMenu(): void { shellController.togglePowerMenu(root.focusedScreenName()) }
        function toggleEmojiPicker(): void { shellController.toggleEmojiPicker(root.focusedScreenName()) }
        function toggleRecording(): void { shellController.toggleRecording(root.focusedScreenName()) }
        function toggleDoNotDisturb(): void { root.setDoNotDisturb(!notificationServer.doNotDisturb) }
        function setDoNotDisturb(enabled: bool): void { root.setDoNotDisturb(enabled) }
        function launchApplication(desktopId: string): bool {
            for (let index = 0; index < shellController.appEntries.length; index++) {
                if (shellController.appEntries[index].id === desktopId) return shellController.launchApplication(shellController.appEntries[index])
            }
            return false
        }
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
        function refreshWeather(): void { shellController.refreshWeather() }
        function randomWallpaper(): void { shellController.run([shellController.rootDir + "/scripts/wallpaper", "random"]) }
        function close(): void { shellController.close() }
        function themeChanged(image: string): void { shellController.showOsd(I18n.tr("osd.theme"), I18n.tr("osd.updated")) }
        function reload(): void { Quickshell.reload(true) }
        function status(): string {
            return JSON.stringify({
                running: true,
                language: I18n.locale,
                appearanceMode: shellController.lightTheme ? "light" : "dark",
                whiteTemperature: shellController.whiteTemperature,
                appearanceSchedule: shellController.config.appearance.schedule,
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
                themeBackground: shellTheme.colors.background,
                islandWidth: shellController.config.shell.islandWidth,
                configError: root.configError,
                themeError: root.themeError,
                islandLoaded: root.islandLoaded,
                widgetsLoaded: root.widgetsLoaded,
                notificationServer: root.notificationServerReady,
                systemService: shellController.systemServiceAvailable,
                applicationCount: shellController.appEntries.length,
                applicationIds: shellController.appEntries.map(entry => entry.id),
                clipboardResultCount: shellController.clipboardResultCount,
                clipboardResultHeight: shellController.clipboardResultHeight,
                emojiResultCount: shellController.emojiResultCount,
                emojiColumnCount: shellController.emojiColumnCount,
                networkResultCount: shellController.networkResultCount,
                switcherCount: shellController.switcherWindows.count,
                switcherIndex: shellController.switcherIndex,
                switcherAddress: shellController.switcherIndex < shellController.switcherWindows.count ? shellController.switcherWindows.get(shellController.switcherIndex).address : "",
                wallpaperQuery: shellController.wallpaperQuery,
                wallpaperResultCount: shellController.wallpaperResultCount,
                wallpaperSelectedIndex: shellController.wallpaperSelectedIndex,
                wallpaperFocusTarget: shellController.wallpaperFocusTarget,
                popupCount: root.popupNotifications.length,
                popupOverflowCount: root.popupOverflowCount,
                notificationHistoryCount: root.notificationHistory.length,
                doNotDisturb: notificationServer.doNotDisturb,
                clipboardCount: shellController.clipboardEntries.length,
                switcherMetadata: Array.from({ length: shellController.switcherWindows.count }, (_, index) => shellController.switcherWindows.get(index)),
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
        function volume(value: string): void { shellController.showOsd(I18n.tr("hub.volume"), value === "muted" ? I18n.tr("common.muted") : value) }
        function brightness(value: string): void { shellController.showOsd(I18n.tr("hub.brightness"), value) }
        function microphone(value: string): void { shellController.showOsd(I18n.tr("hub.microphone"), value === "muted" ? I18n.tr("common.muted") : value) }
        function screenshot(value: string): void { shellController.showOsd(I18n.tr("osd.screenshot"), value.split("/").pop()) }
        function color(value: string): void { shellController.showOsd(I18n.tr("osd.color"), value) }
        function night(value: string): void { shellController.showOsd(I18n.tr("hub.nightMode"), value === "enabled" ? I18n.tr("common.enabled") : I18n.tr("common.disabled")) }
        function power(value: string): void { shellController.showOsd(I18n.tr("hub.powerSaver"), value === "power-saver" ? I18n.tr("profile.powerSaver") : I18n.tr("profile.balanced")) }
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
                    index === 1 ? I18n.tr("development.longNotification") : I18n.tr("development.notification", { count: index + 1 }),
                    index === 2 ? I18n.tr("development.longBody") : I18n.tr("development.notificationBody")
                )
                root.storeNotification(notification)
                root.showPopup(notification)
            }
        }
        function mockReplacement(): void {
            if (!root.developmentMode) return
            root.notificationScreenName = root.focusedScreenName()
            const identifier = Date.now()
            const first = root.developmentNotification(identifier, 0, I18n.tr("development.transfer"), I18n.tr("development.complete", { percent: 25 }))
            const replacement = root.developmentNotification(identifier, 0, I18n.tr("development.transfer"), I18n.tr("development.complete", { percent: 75 }))
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
                { id: "1", type: "text", text: I18n.tr("development.clipboardText"), searchText: I18n.tr("development.clipboardText"), mime: "text/plain;charset=utf-8", thumbnail: "", width: 0, height: 0 },
                { id: "2", type: "image", text: I18n.tr("development.image", { dimensions: "1920×1080" }), searchText: "image png 1920×1080", mime: "image/png", thumbnail: "file://" + shellController.rootDir + "/wallpapers/abyss.png", width: 1920, height: 1080 },
                { id: "3", type: "text", text: I18n.tr("development.clipboardOther"), searchText: I18n.tr("development.clipboardOther"), mime: "text/plain;charset=utf-8", thumbnail: "", width: 0, height: 0 },
                { id: "4", type: "image", text: I18n.tr("development.image", { dimensions: "1200×800" }), searchText: "image png 1200×800", mime: "image/png", thumbnail: "file://" + shellController.rootDir + "/wallpapers/ember.png", width: 1200, height: 800 }
            ]
        }
        function wallpaperSearch(query: string): void {
            if (!root.developmentMode) return
            shellController.wallpaperQuery = query
        }
        function mockTask(): void {
            if (!root.developmentMode) return
            shellController.upsertTask(JSON.stringify({ id: "development", title: I18n.tr("development.preparingTheme"), subtitle: I18n.tr("development.applyingPalette"), progress: 64, status: "running", eta: 45, source: "Hyprism" }))
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
    FileView {
        id: dndStateFile
        path: (Quickshell.env("HYPRISM_CACHE_DIR") || (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/hyprism") + "/state/shell.json"
        blockLoading: true
        preload: true
        printErrors: false
        onLoaded: {
            try {
                const state = JSON.parse(text())
                root.doNotDisturb = !!state.doNotDisturb
                if (root.doNotDisturb) root.syncTrackedPopups()
            } catch (error) {
                setText(JSON.stringify({ doNotDisturb: false }) + "\n")
            }
        }
        onLoadFailed: setText(JSON.stringify({ doNotDisturb: false }) + "\n")
    }
    Timer { id: configReload; interval: 90; onTriggered: root.reloadConfig() }
    Timer { id: themeReload; interval: 90; onTriggered: root.reloadTheme() }
    Timer { id: themeScheduleReconcile; interval: 120; onTriggered: shellController.run([shellController.rootDir + "/scripts/hyprism-shell", "_theme-reconcile"]) }
    Timer {
        id: themeScheduleBoundary
        repeat: false
        onTriggered: {
            shellController.run([shellController.rootDir + "/scripts/hyprism-shell", "_theme-reconcile"])
            themeScheduleRearm.restart()
        }
    }
    Timer { id: themeScheduleRearm; interval: 1500; onTriggered: root.updateThemeSchedule() }
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
        readonly property bool doNotDisturb: root.doNotDisturb
        function removeHistory(notification: var): void { root.removeHistoryNotification(notification) }
        function clearHistory(): void { root.clearNotificationHistory() }
        function toggleDoNotDisturb(): void { root.setDoNotDisturb(!doNotDisturb) }
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
            suppressed: shellController.mode === "control" || notificationServer.doNotDisturb
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
