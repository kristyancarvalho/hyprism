import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Item {
    id: controller
    visible: false
    property string mode: "compact"
    property string previousMode: "compact"
    property string osdKind: ""
    property string osdValue: ""
    property int switcherIndex: 0
    property var switcherWindows: []
    property bool nightMode: false
    property bool powerSaver: false
    property var appEntries: []
    property var wallpaperEntries: []
    property var clipboardEntries: []
    property var weather: ({ city: "Weather unavailable", temperature: null, apparentTemperature: null, weatherCode: -1 })
    property var system: ({ audio: { available: false, percent: 0, muted: false }, microphone: { available: false, percent: 0, muted: false }, network: { kind: "disconnected", name: "Offline" }, bluetooth: { available: false, powered: false, connected: false }, battery: { available: false }, brightness: { available: false }, memory: { percent: 0 }, cpu: { percent: 0 }, gpu: { available: false, percent: 0 }, media: { available: false } })
    property var config: ({ shell: { islandWidth: 520, compactHeight: 42, topMargin: 18, surfaceOpacity: .88, radiusSmall: 14, radiusMedium: 22, radiusLarge: 30, spacingSmall: 8, spacingMedium: 14, spacingLarge: 22, animationFast: 130, animationNormal: 210, widgets: { clock: true, weather: true, media: true, system: true } }, programs: { terminal: "kitty", fileManager: "thunar", browser: "firefox", chromium: "chromium" } })
    property string rootDir: Quickshell.env("HYPRISM_ROOT") || Quickshell.env("HOME") + "/.local/share/hyprism"

    function open(next) {
        if (mode !== next) previousMode = mode
        mode = next
    }
    function toggle(next) { mode === next ? close() : open(next) }
    function close() { mode = "compact" }
    function returnToPrevious() { mode === "compact" ? close() : (mode = previousMode === "compact" ? "compact" : previousMode) }
    function showOsd(kind, value) { osdKind = kind; osdValue = value; osdTimer.restart() }
    function run(command) { commandRunner.exec(command) }
    function toggleNightMode() { nightMode = !nightMode; run(["sh", "-lc", "~/.local/share/hyprism/scripts/system/action night-mode " + (nightMode ? "on" : "off")]); showOsd("Night mode", nightMode ? "On" : "Off") }
    function togglePowerSaver() { powerSaver = !powerSaver; run(["sh", "-lc", "~/.local/share/hyprism/scripts/system/action power-save " + (powerSaver ? "power-saver" : "balanced")]); showOsd("Power saver", powerSaver ? "On" : "Off") }
    function switcher(step) {
        switcherWindows = []
        for (let i = 0; i < Hyprland.toplevels.count; i++) switcherWindows.push(Hyprland.toplevels.get(i))
        if (!switcherWindows.length) return
        if (mode !== "switcher") { previousMode = mode; mode = "switcher"; switcherIndex = 0 }
        else switcherIndex = (switcherIndex + step + switcherWindows.length) % switcherWindows.length
    }
    function commitSwitcher() {
        if (mode !== "switcher") return
        let window = switcherWindows[switcherIndex]
        if (window) Hyprland.dispatch("focuswindow address:" + window.address)
        close()
    }
    function weatherIcon(code) {
        if (code === 0 || code === 1) return "☀"
        if (code === 2 || code === 3) return "☁"
        if (code >= 51 && code <= 82) return "☂"
        if (code >= 95) return "ϟ"
        return "◌"
    }
    function networkIcon() { return system.network.kind === "wifi" ? "◔" : system.network.kind === "ethernet" ? "↔" : "×" }
    function bluetoothIcon() { return !system.bluetooth.available ? "—" : !system.bluetooth.powered ? "◌" : system.bluetooth.connected ? "◉" : "○" }
    function batteryText() { return system.battery.available ? system.battery.percent + "%" : "" }

    Process { id: commandRunner }
    Timer { id: osdTimer; interval: 1600; onTriggered: { controller.osdKind = ""; controller.osdValue = "" } }
}
