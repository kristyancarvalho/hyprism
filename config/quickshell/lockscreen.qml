//@ pragma ShellId hyprism-lock
//@ pragma DefaultEnv QT_QUICK_BACKEND = software
//@ pragma IconTheme Hyprism-Papirus
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "services"
import "lockscreen"

ShellRoot {
    id: root
    settings.watchFiles: false

    readonly property string stateFilePath: Quickshell.env("HYPRISM_LOCK_STATE") || (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/hyprism/lockscreen.state"
    readonly property string background: Quickshell.env("HYPRISM_LOCK_BACKGROUND") || ""
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config"
    readonly property string phase: !lock.locked ? "released" : lock.secure ? "secure" : surfaceCount >= Quickshell.screens.length && surfaceCount > 0 ? "confirming" : "covering"
    property int surfaceCount: 0
    property bool unlocked: false
    property bool releasing: false
    property var lockDefaults: ({})
    property var lockPreferences: ({})
    readonly property bool weatherEnabled: widgetVisible("weather")
    readonly property bool mediaEnabled: widgetVisible("media")

    function widgetVisible(name: string): bool {
        const chosen = lockPreferences[name]
        return typeof chosen === "boolean" ? chosen : lockDefaults[name] === true
    }

    function writeState(value: string): void {
        stateFile.setText(value + "\n")
    }

    function applyConfig(raw: string): void {
        const source = Design.safeText(raw, "")
        if (!source) return
        const parsed = JSON.parse(source)
        if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) throw new Error("the root must be a JSON object")
        I18n.locale = I18n.supportedLocales.indexOf(parsed.language) >= 0 ? parsed.language : "en"
        const incoming = parsed.shell || {}
        const defaults = controller.defaultShellConfig()
        const opacity = Number(incoming.surfaceOpacity)
        const radius = incoming.cornerRadiusPreset
        const lockscreen = parsed.lockscreen
        lockPreferences = lockscreen && typeof lockscreen === "object" && lockscreen.widgets && typeof lockscreen.widgets === "object" ? lockscreen.widgets : {}
        controller.config = Object.assign({}, controller.config, {
            shell: Object.assign({}, defaults, incoming, {
                surfaceOpacity: Number.isFinite(opacity) && opacity >= .5 && opacity <= 1 ? opacity : defaults.surfaceOpacity,
                cornerRadiusPreset: Number.isInteger(radius) && radius >= 0 && radius <= 3 ? radius : defaults.cornerRadiusPreset,
                widgets: controller.mergedWidgetConfig(incoming.widgets || {})
            })
        })
        Design.shellSurfaceOpacity = controller.config.shell.surfaceOpacity
        Design.cornerRadiusPreset = controller.config.shell.cornerRadiusPreset
    }

    function applyTheme(raw: string): void {
        const source = Design.safeText(raw, "")
        if (!source) return
        const parsed = JSON.parse(source)
        if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) throw new Error("the root must be a JSON object")
        theme.applyPalette(parsed)
    }

    function applyPresets(raw: string): void {
        const parsed = JSON.parse(raw)
        if (!parsed || !Array.isArray(parsed.cornerRadius)) throw new Error("invalid theme presets")
        Design.radiusScales = parsed.cornerRadius.map(preset => preset.scale)
    }

    function applyCatalog(raw: string): void {
        const parsed = JSON.parse(raw)
        if (!parsed || !parsed.defaults || typeof parsed.defaults !== "object") throw new Error("invalid lock screen widget defaults")
        lockDefaults = parsed.defaults
    }

    function refresh(): void {
        const steps = [
            ["lock screen widget defaults", () => applyCatalog(catalogFile.text())],
            ["theme presets", () => applyPresets(presetFile.text())],
            ["configuration", () => applyConfig(configFile.text())],
            ["theme", () => applyTheme(themeFile.text())]
        ]
        for (const step of steps) {
            try { step[1]() } catch (error) { console.warn("invalid " + step[0] + ":", String(error)) }
        }
    }

    function beginRelease(): void {
        if (releasing) return
        releasing = true
        morphAnimation.start()
        releaseGuard.start()
    }

    function releaseLock(): void {
        if (unlocked || !releasing) return
        unlocked = true
        lock.locked = false
        writeState("unlocked")
        quitTimer.start()
    }

    Theme { id: theme }
    ShellController { id: controller }
    SystemService { controller: controller }
    MediaService { controller: controller }

    LockSession {
        id: session
        secure: lock.secure
        onUnlockGranted: root.beginRelease()
    }

    WlSessionLock {
        id: lock
        locked: true

        onSecureChanged: if (secure) root.writeState("locked")
        onLockedChanged: {
            if (!locked && !root.unlocked) {
                console.warn("session lock was not granted or was revoked by the compositor")
                root.writeState("unlocked")
                Qt.exit(2)
            }
        }

        LockSurface {
            lock: lock
            session: session
            controller: controller
            theme: theme
            background: root.background
            weatherEnabled: root.weatherEnabled
            mediaEnabled: root.mediaEnabled
            onSurfaceReady: root.surfaceCount = Quickshell.screens.length
        }
    }

    NumberAnimation {
        id: morphAnimation
        target: session
        property: "morphProgress"
        from: 0
        to: 1
        duration: 380
        easing.type: Design.easingMorph
        onFinished: handoff.start()
    }

    Timer {
        id: handoff
        interval: 90
        onTriggered: root.releaseLock()
    }

    Timer {
        id: releaseGuard
        interval: 1600
        onTriggered: root.releaseLock()
    }

    Timer {
        id: quitTimer
        interval: 300
        onTriggered: Qt.quit()
    }

    FileView {
        id: stateFile
        path: root.stateFilePath
        blockWrites: true
        printErrors: false
    }

    IpcHandler {
        target: "lockscreen"
        function status(): string { return root.phase }
    }

    FileView {
        id: catalogFile
        path: (Quickshell.env("HYPRISM_ROOT") || Quickshell.shellDir + "/../..") + "/config/lockscreen/widgets.json"
        blockLoading: true
        preload: true
        printErrors: false
        onLoaded: root.refresh()
    }

    FileView {
        id: presetFile
        path: (Quickshell.env("HYPRISM_ROOT") || Quickshell.shellDir + "/../..") + "/config/theme/presets.json"
        blockLoading: true
        preload: true
        printErrors: false
        onLoaded: root.refresh()
    }

    FileView {
        id: configFile
        path: root.configHome + "/hyprism/user.json"
        blockLoading: true
        preload: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoadFailed: configFileRetry.restart()
        onLoaded: root.refresh()
        onTextChanged: root.refresh()
    }
    Timer { id: configFileRetry; interval: 250; onTriggered: configFile.reload() }

    FileView {
        id: themeFile
        path: theme.cacheDir + "/theme/theme.json"
        blockLoading: true
        preload: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoadFailed: themeFileRetry.restart()
        onLoaded: root.refresh()
        onTextChanged: root.refresh()
    }
    Timer { id: themeFileRetry; interval: 250; onTriggered: themeFile.reload() }

    Component.onCompleted: {
        writeState("locking")
        refresh()
    }
}
