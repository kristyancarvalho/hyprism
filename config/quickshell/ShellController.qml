import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

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
    property bool systemServiceAvailable: false
    readonly property date currentTime: systemClock.date
    property var appEntries: []
    property var wallpaperEntries: []
    property var clipboardEntries: []
    property var weather: ({ city: "São Paulo", temperature: null, apparentTemperature: null, weatherCode: -1 })
    property var system: ({ audio: { available: false, percent: 0, muted: false }, microphone: { available: false, percent: 0, muted: false }, network: { kind: "disconnected", name: "Desconectado", enabled: false, signal: 0 }, bluetooth: { available: false, powered: false, connected: false, devices: [] }, battery: { available: false, percent: 0, status: "" }, brightness: { available: false, percent: 0 }, memory: { percent: 0, used: 0, total: 0 }, cpu: { percent: 0 }, gpu: { available: false, percent: 0 }, media: { available: false, status: "", artist: "", title: "", artUrl: "" } })
    property var config: ({ shell: { primaryMonitor: "", islandWidth: 520, compactHeight: 50, topMargin: 14, surfaceOpacity: .9, radiusSmall: 14, radiusMedium: 22, radiusLarge: 30, spacingSmall: 8, spacingMedium: 14, spacingLarge: 22, animationFast: 130, animationNormal: 210, widgets: { clock: true, weather: true, media: true, system: true } } })
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
    function toggleNightMode() { nightMode = !nightMode; run([rootDir + "/scripts/system/action", "night-mode", nightMode ? "on" : "off"]); showOsd("Modo noturno", nightMode ? "Ativado" : "Desativado") }
    function togglePowerSaver() { powerSaver = !powerSaver; run([rootDir + "/scripts/system/action", "power-save", powerSaver ? "power-saver" : "balanced"]); showOsd("Economia de energia", powerSaver ? "Ativada" : "Desativada") }
    function switcher(step) {
        switcherWindows = []
        for (let i = 0; i < ToplevelManager.toplevels.count; i++) switcherWindows.push(ToplevelManager.toplevels.get(i))
        if (!switcherWindows.length) return
        if (mode !== "switcher") { previousMode = mode; mode = "switcher"; switcherIndex = 0 }
        else switcherIndex = (switcherIndex + step + switcherWindows.length) % switcherWindows.length
    }
    function commitSwitcher() {
        if (mode !== "switcher") return
        let window = switcherWindows[switcherIndex]
        if (window) window.activate()
        close()
    }
    function weatherIconName(code) {
        if (code === 0) return "weather-clear"
        if (code === 1 || code === 2) return "weather-few-clouds"
        if (code === 3) return "weather-overcast"
        if (code === 45 || code === 48) return "weather-fog"
        if (code >= 51 && code <= 67) return "weather-showers-scattered"
        if (code >= 71 && code <= 77) return "weather-snow"
        if (code >= 80 && code <= 82) return "weather-showers"
        if (code >= 95) return "weather-storm"
        return "weather-overcast"
    }
    function networkIconName() { return system.network.kind === "wifi" ? "network-wireless" : system.network.kind === "ethernet" ? "network-wired" : "network-offline" }
    function networkLabel() { return system.network.kind === "ethernet" ? "Cabo" : system.network.kind === "wifi" ? system.network.name : "Sem rede" }
    function bluetoothIconName() { return "bluetooth" }
    function batteryIconName() {
        if (!system.battery.available) return "battery-missing"
        if (system.battery.percent <= 10) return "battery-empty"
        if (system.battery.percent <= 25) return "battery-caution"
        if (system.battery.percent <= 50) return "battery-low"
        if (system.battery.percent <= 80) return "battery-good"
        return "battery-full"
    }
    function volumeIconName() { return system.audio.muted ? "audio-volume-muted" : system.audio.percent < 35 ? "audio-volume-low" : system.audio.percent < 70 ? "audio-volume-medium" : "audio-volume-high" }
    function microphoneIconName() { return "audio-input-microphone" }
    function batteryText() { return system.battery.available ? system.battery.percent + "%" : "" }
    function batteryStatus() {
        if (system.battery.status === "Charging") return "Carregando"
        if (system.battery.status === "Discharging") return "Descarregando"
        if (system.battery.status === "Full") return "Carregada"
        if (system.battery.status === "Not charging") return "Sem carregar"
        return "Indisponível"
    }
    function formattedDate(format) { return Qt.locale("pt_BR").toString(currentTime, format) }

    Process { id: commandRunner }
    SystemClock { id: systemClock; precision: SystemClock.Minutes }
    Timer { id: osdTimer; interval: 1600; onTriggered: { controller.osdKind = ""; controller.osdValue = "" } }
}
