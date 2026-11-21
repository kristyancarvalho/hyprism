//@ pragma ShellId hyprism-lock
//@ pragma DefaultEnv QT_QUICK_BACKEND = software
//@ pragma IconTheme Hyprism-Papirus
pragma ComponentBehavior: Bound

// Dedicated Quickshell entrypoint for the Hyprism lock screen.
//
// It runs as its own process, separate from the desktop shell, so reloading or
// restarting the desktop can never destroy the session-lock object. Live
// reload is disabled for the same reason. There is deliberately no IPC
// operation, timer, shortcut or click handler that can release the lock: the
// single release path is LockSession.unlockGranted, emitted only after PAM
// reports success.
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
    // "requested" -> "covering" -> "secure" -> "released"
    readonly property string phase: !lock.locked ? "released" : lock.secure ? "secure" : surfaceCount >= Quickshell.screens.length && surfaceCount > 0 ? "confirming" : "covering"
    property int surfaceCount: 0
    property bool unlocked: false
    property var lockCatalog: ({})
    property var lockPreferences: ({})
    readonly property var enabledWidgets: {
        const result = {}
        const names = Object.keys(lockCatalog)
        for (let index = 0; index < names.length; index++) {
            const entry = lockCatalog[names[index]]
            if (!entry || entry.supported !== true) continue
            const chosen = lockPreferences[names[index]]
            result[names[index]] = typeof chosen === "boolean" ? chosen : entry.default === true
        }
        return result
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
        controller.config = Object.assign({}, controller.config, {
            shell: Object.assign({}, defaults, incoming, {
                surfaceOpacity: Number.isFinite(opacity) && opacity >= .5 && opacity <= 1 ? opacity : defaults.surfaceOpacity,
                cornerRadiusPreset: Number.isInteger(radius) && radius >= 0 && radius <= 3 ? radius : defaults.cornerRadiusPreset,
                widgets: controller.mergedWidgetConfig(incoming.widgets || {})
            })
        })
        Design.shellSurfaceOpacity = controller.config.shell.surfaceOpacity
        Design.cornerRadiusPreset = controller.config.shell.cornerRadiusPreset
        const lockscreen = parsed.lockscreen
        lockPreferences = lockscreen && typeof lockscreen === "object" && lockscreen.widgets && typeof lockscreen.widgets === "object" ? lockscreen.widgets : {}
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
        if (!parsed || typeof parsed.widgets !== "object") throw new Error("invalid lock screen widget catalog")
        lockCatalog = parsed.widgets
    }

    // The single place where the session lock is released. It runs only after
    // PAM reported success for an attempt started by LockSession.submit().
    function releaseLock(): void {
        if (unlocked) return
        unlocked = true
        lock.locked = false
        writeState("unlocked")
        quitTimer.start()
    }

    Theme { id: theme }
    ShellController { id: controller }
    SystemService { controller: controller }

    LockSession {
        id: session
        secure: lock.secure
        onUnlockGranted: root.releaseLock()
    }

    WlSessionLock {
        id: lock
        locked: true

        onSecureChanged: if (secure) root.writeState("locked")
        onLockedChanged: {
            // The compositor ended the lock without authentication (for
            // example because another client holds it). Never keep a prompt
            // around: exit, leaving any real lock to the compositor.
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
            enabledWidgets: root.enabledWidgets
            background: root.background
            onSurfaceReady: root.surfaceCount = Quickshell.screens.length
        }
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

    // Read-only status; no operation here can unlock the session.
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
        onLoaded: { try { root.applyCatalog(text()) } catch (error) { console.warn("invalid lock screen widget catalog:", String(error)) } }
    }

    FileView {
        id: presetFile
        path: (Quickshell.env("HYPRISM_ROOT") || Quickshell.shellDir + "/../..") + "/config/theme/presets.json"
        blockLoading: true
        preload: true
        printErrors: false
        onLoaded: { try { root.applyPresets(text()) } catch (error) { console.warn("invalid theme presets:", String(error)) } }
    }

    FileView {
        id: configFile
        path: root.configHome + "/hyprism/user.json"
        blockLoading: true
        preload: true
        printErrors: false
        onLoaded: { try { root.applyConfig(text()) } catch (error) { console.warn("invalid Hyprism configuration:", String(error)) } }
    }

    FileView {
        id: themeFile
        path: theme.cacheDir + "/theme/theme.json"
        blockLoading: true
        preload: true
        printErrors: false
        onLoaded: { try { root.applyTheme(text()) } catch (error) { console.warn("invalid Hyprism theme:", String(error)) } }
    }

    Component.onCompleted: writeState("locking")
}
