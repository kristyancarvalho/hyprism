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
    property string targetScreenName: ""
    property string osdKind: ""
    property string osdValue: ""
    property int switcherIndex: 0
    property var switcherWindows: []
    property var mruWindows: []
    property var mediaPlayer: null
    property int launcherResultCount: 0
    property bool pendingNightMode: false
    property bool pendingPowerSaver: false
    property bool pendingWifi: false
    property bool pendingBluetooth: false
    property bool desiredNightMode: false
    property bool desiredPowerSaver: false
    property bool desiredWifi: false
    property bool desiredBluetooth: false
    property bool systemServiceAvailable: false
    readonly property bool nightMode: system.nightMode.available && system.nightMode.enabled
    readonly property bool powerSaver: system.powerProfile.available && system.powerProfile.mode === "power-saver"
    readonly property date currentTime: systemClock.date
    property var appEntries: []
    property var wallpaperEntries: []
    property var clipboardEntries: []
    property var cpuHistory: []
    property var memoryHistory: []
    property var gpuHistory: []
    property var temperatureHistory: []
    property var networkHistory: []
    property var weather: ({ city: "São Paulo", condition: "Indisponível", temperature: null, apparentTemperature: null, minimum: null, maximum: null, weatherCode: -1 })
    property var system: ({ audio: { available: false, percent: 0, muted: false }, microphone: { available: false, percent: 0, muted: false }, network: { available: false, kind: "disconnected", name: "Desconectado", enabled: false, signal: 0, receiveKib: 0, transmitKib: 0, wifiAvailable: false, wifiEnabled: false, virtualized: false }, bluetooth: { available: false, powered: false, connected: false, devices: [] }, battery: { available: false, percent: 0, status: "" }, brightness: { available: false, percent: 0 }, nightMode: { available: false, enabled: false }, powerProfile: { available: false, mode: "" }, memory: { percent: 0, used: 0, total: 0 }, cpu: { percent: 0 }, gpu: { available: false, percent: 0 }, temperature: { available: false, celsius: 0 } })
    property var config: ({ shell: { primaryMonitor: "", islandWidth: 560, compactHeight: Design.compactBarHeight, topMargin: Design.shellTopMargin, reserveGap: Design.compactBottomGap, surfaceOpacity: .9, animationFast: Design.animationFast, animationNormal: Design.animationMorph, widgets: { clock: true, weather: true, media: true, system: true } } })
    property string rootDir: Quickshell.env("HYPRISM_ROOT") || Quickshell.env("HOME") + "/.local/share/hyprism"

    function open(next) {
        if (mode !== next) previousMode = mode
        mode = next
    }

    function openOnScreen(next, screenName) {
        const safeName = Design.safeText(screenName, "")
        if (safeName) targetScreenName = safeName
        open(next)
    }

    function toggle(next) {
        mode === next ? close() : open(next)
    }

    function close() {
        if (mode === "compact") {
            return
        }
        mode = "compact"
    }

    function returnToPrevious() {
        mode === "compact" ? close() : (mode = previousMode === "compact" ? "compact" : previousMode)
    }

    function showOsd(kind, value) {
        osdKind = Design.safeText(kind, "Sistema")
        osdValue = Design.safeText(value, "Indisponível")
        osdTimer.restart()
    }

    function run(command) {
        commandRunner.exec(command)
    }

    function toggleNightMode() {
        if (!system.nightMode.available) { showOsd("Modo noturno", "Indisponível"); return }
        if (pendingNightMode) return
        desiredNightMode = !nightMode
        pendingNightMode = true
        run([rootDir + "/scripts/system/action", "night-mode", desiredNightMode ? "on" : "off"])
        stateRequestTimeout.restart()
    }

    function togglePowerSaver() {
        if (!system.powerProfile.available) { showOsd("Economia de energia", "Indisponível"); return }
        if (pendingPowerSaver) return
        desiredPowerSaver = !powerSaver
        pendingPowerSaver = true
        run([rootDir + "/scripts/system/action", "power-save", desiredPowerSaver ? "power-saver" : "balanced"])
        stateRequestTimeout.restart()
    }

    function toggleWifi() {
        if (!system.network.wifiAvailable) { showOsd("Wi-Fi", "Indisponível"); return }
        if (pendingWifi) return
        desiredWifi = !system.network.wifiEnabled
        pendingWifi = true
        run(["python3", rootDir + "/scripts/system/network.py", "toggle", desiredWifi ? "on" : "off"])
        stateRequestTimeout.restart()
    }

    function toggleBluetooth() {
        if (!system.bluetooth.available) { showOsd("Bluetooth", "Indisponível"); return }
        if (pendingBluetooth) return
        desiredBluetooth = !system.bluetooth.powered
        pendingBluetooth = true
        run(["python3", rootDir + "/scripts/system/bluetooth.py", "power", desiredBluetooth ? "on" : "off"])
        stateRequestTimeout.restart()
    }

    function appendHistory(history, value) {
        const next = Array.isArray(history) ? history.slice(-Design.historyLimit + 1) : []
        next.push(Design.clamp(value, 0, 100))
        return next
    }

    function updateSystem(incoming) {
        const next = incoming || {}
        system = {
            audio: Object.assign({}, system.audio, next.audio || {}),
            microphone: Object.assign({}, system.microphone, next.microphone || {}),
            network: Object.assign({}, system.network, next.network || {}),
            bluetooth: Object.assign({}, system.bluetooth, next.bluetooth || {}),
            battery: Object.assign({}, system.battery, next.battery || {}),
            brightness: Object.assign({}, system.brightness, next.brightness || {}),
            nightMode: Object.assign({}, system.nightMode, next.nightMode || {}),
            powerProfile: Object.assign({}, system.powerProfile, next.powerProfile || {}),
            memory: Object.assign({}, system.memory, next.memory || {}),
            cpu: Object.assign({}, system.cpu, next.cpu || {}),
            gpu: Object.assign({}, system.gpu, next.gpu || {}),
            temperature: Object.assign({}, system.temperature, next.temperature || {})
        }
        cpuHistory = appendHistory(cpuHistory, system.cpu.percent)
        memoryHistory = appendHistory(memoryHistory, system.memory.percent)
        if (system.gpu.available) gpuHistory = appendHistory(gpuHistory, system.gpu.percent)
        if (system.temperature.available) temperatureHistory = appendHistory(temperatureHistory, system.temperature.celsius)
        networkHistory = appendHistory(networkHistory, Math.min(100, Math.log2(1 + Design.safeNumber(system.network.receiveKib, 0) + Design.safeNumber(system.network.transmitKib, 0)) * 8))
        if (pendingNightMode && system.nightMode.available && system.nightMode.enabled === desiredNightMode) {
            pendingNightMode = false
            showOsd("Modo noturno", desiredNightMode ? "Ativado" : "Desativado")
        }
        if (pendingPowerSaver && system.powerProfile.available && powerSaver === desiredPowerSaver) {
            pendingPowerSaver = false
            showOsd("Economia de energia", desiredPowerSaver ? "Ativada" : "Desativada")
        }
        if (pendingWifi && system.network.wifiAvailable && system.network.wifiEnabled === desiredWifi) {
            pendingWifi = false
            showOsd("Wi-Fi", desiredWifi ? "Ativado" : "Desativado")
        }
        if (pendingBluetooth && system.bluetooth.available && system.bluetooth.powered === desiredBluetooth) {
            pendingBluetooth = false
            showOsd("Bluetooth", desiredBluetooth ? "Ativado" : "Desativado")
        }
    }

    function rememberWindow(window) {
        if (!window) return
        const available = ToplevelManager.toplevels.values || []
        const next = [window]
        for (let i = 0; i < mruWindows.length; i++) {
            const candidate = mruWindows[i]
            if (candidate && candidate !== window && available.indexOf(candidate) >= 0) next.push(candidate)
        }
        for (let j = 0; j < available.length; j++) {
            if (available[j] && next.indexOf(available[j]) < 0) next.push(available[j])
        }
        mruWindows = next
    }

    function orderedWindows() {
        const available = ToplevelManager.toplevels.values || []
        const ordered = []
        for (let i = 0; i < mruWindows.length; i++) {
            if (mruWindows[i] && available.indexOf(mruWindows[i]) >= 0 && ordered.indexOf(mruWindows[i]) < 0) ordered.push(mruWindows[i])
        }
        for (let j = 0; j < available.length; j++) {
            if (available[j] && ordered.indexOf(available[j]) < 0) ordered.push(available[j])
        }
        return ordered
    }

    function switcher(step) {
        if (mode !== "switcher") {
            rememberWindow(ToplevelManager.activeToplevel)
            switcherWindows = orderedWindows()
            if (!switcherWindows.length) return
            previousMode = mode
            mode = "switcher"
            switcherIndex = step < 0 ? switcherWindows.length - 1 : Math.min(1, switcherWindows.length - 1)
            return
        }
        switcherIndex = (switcherIndex + step + switcherWindows.length) % switcherWindows.length
    }

    function commitSwitcher() {
        if (mode !== "switcher") return
        const window = switcherWindows[switcherIndex]
        if (window) {
            if (window.minimized) window.minimized = false
            window.activate()
        }
        close()
    }

    function weatherIconName(code) {
        if (code === 0) return "weatherClear"
        if (code === 1 || code === 2) return "weatherPartlyCloudy"
        if (code === 3) return "weatherCloudy"
        if (code === 45 || code === 48) return "weatherFog"
        if (code >= 51 && code <= 67) return "weatherRain"
        if (code >= 71 && code <= 77) return "weatherSnow"
        if (code >= 80 && code <= 82) return "weatherRain"
        if (code >= 95) return "weatherStorm"
        return "weatherCloudy"
    }

    function weatherCondition(code) {
        if (code === 0) return "Céu limpo"
        if (code === 1 || code === 2) return "Parcialmente nublado"
        if (code === 3) return "Nublado"
        if (code === 45 || code === 48) return "Neblina"
        if (code >= 51 && code <= 67) return "Chuva"
        if (code >= 71 && code <= 77) return "Neve"
        if (code >= 80 && code <= 82) return "Pancadas de chuva"
        if (code >= 95) return "Tempestade"
        return "Tempo indisponível"
    }

    function networkIconName() {
        return system.network.kind === "wifi" ? "wifi" : system.network.kind === "ethernet" ? "ethernet" : "networkOff"
    }

    function networkLabel() {
        if (system.network.kind === "ethernet") return system.network.virtualized ? "Rede" : "Ethernet"
        return system.network.kind === "wifi" ? Design.safeText(system.network.name, "Wi-Fi") : "Sem rede"
    }

    function bluetoothIconName() {
        if (!system.bluetooth.powered) return "bluetoothOff"
        return system.bluetooth.connected ? "bluetoothConnected" : "bluetooth"
    }

    function batteryIconName() {
        if (!system.battery.available) return "batteryMissing"
        const percentage = Design.clamp(system.battery.percent, 0, 100)
        if (percentage <= 10) return "battery0"
        if (percentage <= 30) return "battery1"
        if (percentage <= 55) return "battery2"
        if (percentage <= 80) return "battery3"
        return "battery4"
    }

    function batteryCharging() {
        return system.battery.available && Design.safeText(system.battery.status, "").toLowerCase() === "charging"
    }

    function volumeIconName() {
        if (system.audio.muted) return "volumeMuted"
        return Design.safeNumber(system.audio.percent, 0) < 35 ? "volumeLow" : "volume"
    }

    function microphoneIconName() {
        return system.microphone.muted ? "microphoneMuted" : "microphone"
    }

    function batteryText() {
        return system.battery.available ? Math.round(Design.safeNumber(system.battery.percent, 0)) + "%" : ""
    }

    function batteryStatus() {
        if (system.battery.status === "Charging") return "Carregando"
        if (system.battery.status === "Discharging") return "Descarregando"
        if (system.battery.status === "Full") return "Carregada"
        if (system.battery.status === "Not charging") return "Sem carregar"
        return "Indisponível"
    }

    function mediaAvailable() {
        return mediaPlayer !== null && Design.safeText(mediaPlayer.trackTitle, "").length > 0
    }

    function mediaTitle() {
        return mediaAvailable() ? Design.safeText(mediaPlayer.trackTitle, "Faixa sem título") : ""
    }

    function mediaArtist() {
        return mediaAvailable() ? Design.safeText(mediaPlayer.trackArtist, Design.safeText(mediaPlayer.identity, "Artista desconhecido")) : ""
    }

    function mediaArtUrl() {
        return mediaAvailable() ? Design.safeText(mediaPlayer.trackArtUrl, "") : ""
    }

    function mediaProgress() {
        if (!mediaAvailable() || !mediaPlayer.lengthSupported || mediaPlayer.length <= 0) return 0
        return Design.clamp(mediaPlayer.position / mediaPlayer.length, 0, 1)
    }

    function mediaToggle() {
        if (mediaPlayer && mediaPlayer.canTogglePlaying) mediaPlayer.togglePlaying()
    }

    function mediaPrevious() {
        if (mediaPlayer && mediaPlayer.canGoPrevious) mediaPlayer.previous()
    }

    function mediaNext() {
        if (mediaPlayer && mediaPlayer.canGoNext) mediaPlayer.next()
    }

    function applicationEntry(appId) {
        const requested = Design.safeText(appId, "").toLowerCase().replace(/\.desktop$/, "")
        if (!requested) return null
        for (let i = 0; i < appEntries.length; i++) {
            const entryId = Design.safeText(appEntries[i].id, "").toLowerCase().replace(/\.desktop$/, "")
            if (entryId === requested || entryId.endsWith("." + requested) || requested.endsWith("." + entryId)) return appEntries[i]
        }
        return null
    }

    function applicationIcon(appId) {
        const entry = applicationEntry(appId)
        return entry ? Design.safeText(entry.icon, "application-x-executable") : Design.safeText(appId, "application-x-executable")
    }

    function applicationName(appId) {
        const entry = applicationEntry(appId)
        if (entry) return Design.safeText(entry.name, "Janela")
        const raw = Design.safeText(appId, "Janela")
        const tail = raw.split(".").pop().replace(/[-_]/g, " ")
        return tail.length ? tail.charAt(0).toUpperCase() + tail.slice(1) : "Janela"
    }

    function formattedDate(format) {
        return Qt.locale("pt_BR").toString(currentTime, format)
    }

    Process { id: commandRunner }
    SystemClock { id: systemClock; precision: SystemClock.Seconds }
    Timer { id: osdTimer; interval: 1600; onTriggered: { controller.osdKind = ""; controller.osdValue = "" } }
    Timer {
        id: stateRequestTimeout
        interval: 4500
        onTriggered: {
            const failed = pendingNightMode || pendingPowerSaver || pendingWifi || pendingBluetooth
            pendingNightMode = false
            pendingPowerSaver = false
            pendingWifi = false
            pendingBluetooth = false
            if (failed) showOsd("Sistema", "Não foi possível alterar o estado")
        }
    }
    Connections {
        target: ToplevelManager
        function onActiveToplevelChanged() {
            controller.rememberWindow(ToplevelManager.activeToplevel)
        }
    }
    Component.onCompleted: rememberWindow(ToplevelManager.activeToplevel)
}
