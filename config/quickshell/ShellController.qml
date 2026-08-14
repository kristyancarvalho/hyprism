import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

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
    property bool panelFocusReady: false
    property var recordingService: null
    readonly property bool recording: recordingService ? recordingService.recording : false
    readonly property bool recordingPending: recordingService ? recordingService.pending : false
    readonly property bool recordingSelecting: recordingService ? recordingService.selecting : false
    readonly property string recordingMode: recordingService ? Design.safeText(recordingService.mode, "") : ""
    readonly property int recordingElapsed: recordingService ? Math.max(0, Design.safeNumber(recordingService.elapsed, 0)) : 0
    readonly property string recordingOutputPath: recordingService ? Design.safeText(recordingService.outputPath, "") : ""
    readonly property string recordingProcessId: recordingService && recordingService.ownedProcessId ? String(recordingService.ownedProcessId) : ""
    readonly property bool nightMode: system.nightMode.available && system.nightMode.enabled
    readonly property bool powerSaver: system.powerProfile.available && system.powerProfile.mode === "power-saver"
    readonly property date currentTime: systemClock.date
    property var appEntries: []
    property var applicationIndex: ({})
    property var wallpaperEntries: []
    property string wallpaperCurrent: ""
    property string wallpaperQuery: ""
    property int wallpaperResultCount: 0
    property int wallpaperSelectedIndex: 0
    property string wallpaperFocusTarget: ""
    property var clipboardEntries: []
    property var cpuHistory: []
    property var memoryHistory: []
    property var gpuHistory: []
    property var temperatureHistory: []
    property var networkHistory: []
    property var downloadHistory: []
    property var uploadHistory: []
    property var tasks: []
    property var weather: ({ city: "São Paulo", condition: "Indisponível", temperature: null, apparentTemperature: null, minimum: null, maximum: null, weatherCode: -1 })
    property var system: ({ audio: { available: false, percent: 0, muted: false }, microphone: { available: false, percent: 0, muted: false }, network: { available: false, kind: "disconnected", name: "Desconectado", enabled: false, signal: 0, receiveKib: 0, transmitKib: 0, wifiAvailable: false, wifiEnabled: false, virtualized: false }, bluetooth: { available: false, powered: false, connected: false, devices: [] }, battery: { available: false, percent: 0, status: "" }, brightness: { available: false, percent: 0 }, nightMode: { available: false, enabled: false }, powerProfile: { available: false, mode: "" }, memory: { percent: 0, used: 0, total: 0 }, cpu: { percent: 0 }, gpu: { available: false, percent: 0 }, temperature: { available: false, celsius: 0 } })
    property var monitoring: ({ storage: { available: false, mounts: [] }, sensors: { available: false, items: [] }, uptime: { available: false, uptimeSeconds: 0, load1: 0, load5: 0, load15: 0, cores: 1, processCount: 0, kernel: "" }, services: { available: false, healthy: false, items: [] }, processes: { available: false, cpu: [], memory: [], limit: 3 } })
    readonly property var widgetDefaults: ({
        clock: { enabled: true },
        weather: { enabled: true },
        media: { enabled: true },
        system: { enabled: true },
        network: { enabled: true, historySamples: 60, interface: "auto" },
        storage: { enabled: true, mounts: ["/", "/home"] },
        sensors: { enabled: true },
        uptime: { enabled: true },
        services: { enabled: true, problemOnly: false, items: [
            { name: "Rede", unit: "NetworkManager.service", scope: "system" },
            { name: "Bluetooth", unit: "bluetooth.service", scope: "system" },
            { name: "PipeWire", unit: "pipewire.service", scope: "user" }
        ] },
        tasks: { enabled: true, limit: 3 },
        processes: { enabled: true, limit: 3 }
    })
    property var config: ({ shell: { primaryMonitor: "", islandWidth: 560, compactHeight: Design.compactBarHeight, topMargin: Design.shellTopMargin, reserveGap: Design.compactBottomGap, surfaceOpacity: .9, animationFast: Design.animationFast, animationNormal: Design.animationMorph, widgetLayout: { side: "right", position: "legacy" }, widgets: widgetDefaults } })
    property string rootDir: Quickshell.env("HYPRISM_ROOT") || Quickshell.shellDir + "/../.."
    readonly property bool developmentMode: Quickshell.env("HYPRISM_DEVELOPMENT") === "1"
    readonly property var panelModes: ["launcher", "wallpaper", "clipboard", "control", "network", "bluetooth", "power", "emoji", "switcher", "recordingSelector"]

    function defaultShellConfig() {
        return {
            primaryMonitor: "",
            islandWidth: 560,
            compactHeight: Design.compactBarHeight,
            topMargin: Design.shellTopMargin,
            reserveGap: Design.compactBottomGap,
            surfaceOpacity: .9,
            animationFast: Design.animationFast,
            animationNormal: Design.animationMorph,
            widgetLayout: { side: "right", position: "legacy" },
            widgets: mergedWidgetConfig({})
        }
    }

    function mergedWidgetConfig(incoming) {
        const source = incoming && typeof incoming === "object" ? incoming : {}
        const merged = {}
        const names = Object.keys(widgetDefaults)
        for (let index = 0; index < names.length; index++) {
            const name = names[index]
            const value = source[name]
            if (typeof value === "boolean") merged[name] = Object.assign({}, widgetDefaults[name], { enabled: value })
            else merged[name] = Object.assign({}, widgetDefaults[name], value && typeof value === "object" ? value : {})
        }
        return merged
    }

    function widgetConfig(name) {
        const widgets = config && config.shell && config.shell.widgets ? config.shell.widgets : {}
        const value = widgets[name]
        if (typeof value === "boolean") return { enabled: value }
        return value && typeof value === "object" ? value : (widgetDefaults[name] || { enabled: false })
    }

    function widgetEnabled(name) {
        const value = widgetConfig(name)
        return value.enabled === undefined ? !!(widgetDefaults[name] && widgetDefaults[name].enabled) : !!value.enabled
    }

    function widgetNumber(name, option, fallback, minimum, maximum) {
        const value = Design.safeNumber(widgetConfig(name)[option], fallback)
        return Math.max(minimum, Math.min(maximum, Math.round(value)))
    }

    function widgetLayoutPosition() {
        const layout = config && config.shell && config.shell.widgetLayout ? config.shell.widgetLayout : {}
        const position = Design.safeText(layout.position, "legacy")
        if (["center", "top-left", "top-right", "bottom-left", "bottom-right"].indexOf(position) >= 0) return position
        return Design.safeText(layout.side, "right") === "left" ? "top-left" : "top-right"
    }

    function openMode(next) {
        if (panelModes.indexOf(next) < 0 && next !== "hover") return
        panelFocusReady = false
        if (mode !== next) previousMode = mode
        mode = next
    }

    function openPanel(next, screenName) {
        const safeName = Design.safeText(screenName, "")
        if (safeName) targetScreenName = safeName
        openMode(next)
    }

    function togglePanel(next, screenName) {
        if (mode === next) {
            close()
            return
        }
        openPanel(next, screenName)
    }

    function openHub(screenName) { openPanel("control", screenName) }
    function openLauncher(screenName) { openPanel("launcher", screenName) }
    function openClipboard(screenName) { openPanel("clipboard", screenName) }
    function openWallpaperPicker(screenName) {
        wallpaperQuery = ""
        wallpaperSelectedIndex = 0
        wallpaperFocusTarget = "grid"
        openPanel("wallpaper", screenName)
    }
    function openNetwork(screenName) { openPanel("network", screenName) }
    function openBluetooth(screenName) { openPanel("bluetooth", screenName) }
    function openPowerMenu(screenName) { openPanel("power", screenName) }
    function openEmojiPicker(screenName) { openPanel("emoji", screenName) }
    function openRecording(screenName) { openPanel("recordingSelector", screenName) }
    function toggleHub(screenName) { togglePanel("control", screenName) }
    function toggleLauncher(screenName) { togglePanel("launcher", screenName) }
    function toggleClipboard(screenName) { togglePanel("clipboard", screenName) }
    function toggleWallpaperPicker(screenName) {
        if (mode === "wallpaper") close()
        else openWallpaperPicker(screenName)
    }
    function toggleNetwork(screenName) { togglePanel("network", screenName) }
    function togglePowerMenu(screenName) { togglePanel("power", screenName) }
    function toggleEmojiPicker(screenName) { togglePanel("emoji", screenName) }

    function toggleRecording(screenName) {
        if (recording || recordingPending || recordingSelecting) {
            stopRecording()
            return
        }
        togglePanel("recordingSelector", screenName)
    }

    function startRegionRecording() {
        if (recordingService) recordingService.startRegion()
    }

    function startMonitorRecording() {
        if (recordingService) recordingService.startMonitor(targetScreenName)
    }

    function stopRecording() {
        if (recordingService) recordingService.stop()
    }

    function recordingElapsedText() {
        return Design.formatRecordingDuration(recordingElapsed)
    }

    function close() {
        if (mode === "compact") {
            return
        }
        mode = "compact"
        panelFocusReady = false
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

    function appendSample(history, value, limit) {
        const next = Array.isArray(history) ? history.slice(-Math.max(1, limit) + 1) : []
        next.push(Math.max(0, Design.safeNumber(value, 0)))
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
        if (widgetEnabled("network")) {
            const samples = widgetNumber("network", "historySamples", Design.historyLimit, 15, 180)
            downloadHistory = appendSample(downloadHistory, system.network.receiveKib, samples)
            uploadHistory = appendSample(uploadHistory, system.network.transmitKib, samples)
        }
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

    function resetMonitoring() {
        monitoring = { storage: { available: false, mounts: [] }, sensors: { available: false, items: [] }, uptime: { available: false, uptimeSeconds: 0, load1: 0, load5: 0, load15: 0, cores: 1, processCount: 0, kernel: "" }, services: { available: false, healthy: false, items: [] }, processes: { available: false, cpu: [], memory: [], limit: 3 } }
    }

    function updateMonitoring(incoming) {
        const next = incoming || {}
        monitoring = {
            storage: Object.assign({}, monitoring.storage, next.storage || {}),
            sensors: Object.assign({}, monitoring.sensors, next.sensors || {}),
            uptime: Object.assign({}, monitoring.uptime, next.uptime || {}),
            services: Object.assign({}, monitoring.services, next.services || {}),
            processes: Object.assign({}, monitoring.processes, next.processes || {})
        }
    }

    function taskFromPayload(payload) {
        const value = typeof payload === "string" ? JSON.parse(payload) : payload
        if (!value || typeof value !== "object") throw new Error("tarefa inválida")
        const id = Design.safeText(value.id, "")
        if (!id) throw new Error("identificador de tarefa ausente")
        return {
            id: id,
            title: Design.safeText(value.title, "Tarefa"),
            subtitle: Design.safeText(value.subtitle, ""),
            progress: Design.clamp(value.progress, 0, 100),
            indeterminate: !!value.indeterminate,
            status: Design.safeText(value.status, "running"),
            startedAt: Math.max(0, Design.safeNumber(value.startedAt, Date.now())),
            eta: Math.max(0, Design.safeNumber(value.eta, 0)),
            source: Design.safeText(value.source, "Hyprism"),
            removeAt: Math.max(0, Design.safeNumber(value.removeAt, 0))
        }
    }

    function upsertTask(payload) {
        const incoming = taskFromPayload(payload)
        const next = []
        let replaced = false
        for (let index = 0; index < tasks.length; index++) {
            if (tasks[index].id === incoming.id) {
                next.push(Object.assign({}, tasks[index], incoming))
                replaced = true
            } else next.push(tasks[index])
        }
        if (!replaced) next.push(incoming)
        tasks = next
        return incoming.id
    }

    function updateTask(identifier, payload) {
        const id = Design.safeText(identifier, "")
        const changes = typeof payload === "string" ? JSON.parse(payload) : payload
        const next = []
        for (let index = 0; index < tasks.length; index++) {
            const item = tasks[index]
            if (item.id === id) next.push(taskFromPayload(Object.assign({}, item, changes || {}, { id: id })))
            else next.push(item)
        }
        tasks = next
    }

    function removeTask(identifier) {
        const id = Design.safeText(identifier, "")
        tasks = tasks.filter(item => item.id !== id)
    }

    function finishTask(identifier, failed) {
        updateTask(identifier, { status: failed ? "failed" : "finished", progress: failed ? 0 : 100, indeterminate: false, removeAt: Date.now() + (failed ? 5000 : 1800) })
    }

    function cleanupTasks() {
        const now = Date.now()
        tasks = tasks.filter(item => !item.removeAt || item.removeAt > now)
    }

    function formatBytes(bytes) {
        const value = Math.max(0, Design.safeNumber(bytes, 0))
        const units = ["B", "KiB", "MiB", "GiB", "TiB"]
        let size = value
        let index = 0
        while (size >= 1024 && index < units.length - 1) {
            size /= 1024
            index++
        }
        const digits = size >= 100 || index === 0 ? 0 : size >= 10 ? 1 : 2
        return size.toFixed(digits).replace(".", ",") + " " + units[index]
    }

    function formatRate(kib) {
        return formatBytes(Math.max(0, Design.safeNumber(kib, 0)) * 1024) + "/s"
    }

    function formatUptime(seconds) {
        const value = Math.max(0, Math.floor(Design.safeNumber(seconds, 0)))
        const days = Math.floor(value / 86400)
        const hours = Math.floor(value % 86400 / 3600)
        const minutes = Math.floor(value % 3600 / 60)
        if (days > 0) return days + " d " + hours + " h"
        if (hours > 0) return hours + " h " + minutes + " min"
        return minutes + " min"
    }

    function serviceStateText(state) {
        if (state === "running") return "ativo"
        if (state === "stopped") return "parado"
        if (state === "failed") return "falhou"
        if (state === "unavailable") return "indisponível"
        return "desconhecido"
    }

    function rememberWindow(window) {
        if (!window) return
        const available = Hyprland.toplevels.values || []
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
        const available = Hyprland.toplevels.values || []
        const ordered = []
        for (let i = 0; i < mruWindows.length; i++) {
            if (mruWindows[i] && available.indexOf(mruWindows[i]) >= 0 && ordered.indexOf(mruWindows[i]) < 0) ordered.push(mruWindows[i])
        }
        for (let j = 0; j < available.length; j++) {
            if (available[j] && ordered.indexOf(available[j]) < 0) ordered.push(available[j])
        }
        return ordered
    }

    function switcherEntry(window) {
        if (!window) return null
        const address = HyprlandService.normalizedAddress(window.address)
        if (!address) return null
        const ipc = window.lastIpcObject || {}
        const candidates = [ipc.class, ipc.initialClass, window.appId]
        const application = applicationEntry(candidates)
        return {
            window: window,
            address: address,
            appId: Design.safeText(ipc.class, Design.safeText(ipc.initialClass, "")),
            initialClass: Design.safeText(ipc.initialClass, ""),
            icon: application ? Design.safeText(application.icon, "application-x-executable") : "application-x-executable",
            applicationName: application ? Design.safeText(application.name, "Janela") : applicationName(candidates),
            title: Design.safeText(window.title, "Sem título"),
            minimized: false
        }
    }

    function switcherEntries() {
        const windows = orderedWindows()
        const entries = []
        for (let index = 0; index < windows.length; index++) {
            const entry = switcherEntry(windows[index])
            if (entry) entries.push(entry)
        }
        return entries
    }

    function switcher(step) {
        if (mode !== "switcher") {
            rememberWindow(Hyprland.activeToplevel)
            switcherWindows = switcherEntries()
            if (!switcherWindows.length) return
            previousMode = mode
            openMode("switcher")
            switcherIndex = step < 0 ? switcherWindows.length - 1 : Math.min(1, switcherWindows.length - 1)
            return
        }
        switcherIndex = (switcherIndex + step + switcherWindows.length) % switcherWindows.length
    }

    function commitSwitcher() {
        if (mode !== "switcher") return
        const selected = switcherWindows[switcherIndex]
        if (selected) {
            HyprlandService.focusWindow(selected.address)
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
        if (system.network.kind !== "wifi") return system.network.kind === "ethernet" ? "ethernet" : "wifiDisconnected"
        if (!system.network.enabled) return "wifiDisconnected"
        return wifiIconForSignal(system.network.signal)
    }

    function wifiIconForSignal(value) {
        const signal = Design.clamp(value, 0, 100)
        if (signal <= 0) return "wifiOutline"
        if (signal < 34) return "wifiWeak"
        if (signal < 67) return "wifiMedium"
        return "wifiStrong"
    }

    function networkLabel() {
        if (system.network.kind === "ethernet") return system.network.virtualized ? "Rede" : "Ethernet"
        return system.network.kind === "wifi" ? Design.safeText(system.network.name, "Wi-Fi") : "Sem rede"
    }

    function bluetoothIconName() {
        if (!system.bluetooth.available) return "bluetoothOff"
        if (!system.bluetooth.powered) return "bluetoothOff"
        return system.bluetooth.connected ? "bluetoothConnected" : "bluetooth"
    }

    function bluetoothExpandedText() {
        if (!system.bluetooth.available) return "Indisponível"
        if (!system.bluetooth.powered) return "Desligado"
        const devices = Array.isArray(system.bluetooth.devices) ? system.bluetooth.devices.filter(device => device && device.connected) : []
        if (!devices.length) return "Ligado · Desconectado"
        const first = Design.safeText(devices[0].name, "Dispositivo conectado")
        return devices.length === 1 ? first + " · Conectado" : first + " · +" + (devices.length - 1)
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

    function batteryExpandedText() {
        if (!system.battery.available) return ""
        const percentage = batteryText()
        return batteryCharging() ? percentage + " · Carregando" : percentage
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

    function normalizedApplicationKey(value) {
        return Design.safeText(value, "").toLowerCase().replace(/\.desktop$/, "").replace(/[^a-z0-9]/g, "")
    }

    function setApplicationEntries(entries) {
        const safeEntries = Array.isArray(entries) ? entries : []
        const index = {}
        for (let entryIndex = 0; entryIndex < safeEntries.length; entryIndex++) {
            const entry = safeEntries[entryIndex]
            const aliases = Array.isArray(entry.aliases) ? entry.aliases.slice() : []
            aliases.push(entry.id, entry.startupClass, entry.executable, entry.name)
            for (let aliasIndex = 0; aliasIndex < aliases.length; aliasIndex++) {
                const key = normalizedApplicationKey(aliases[aliasIndex])
                if (key && !index[key]) index[key] = entry
            }
        }
        appEntries = safeEntries
        applicationIndex = index
    }

    function applicationEntry(candidates) {
        const values = Array.isArray(candidates) ? candidates : [candidates]
        const keys = []
        for (let index = 0; index < values.length; index++) {
            const raw = Design.safeText(values[index], "")
            const key = normalizedApplicationKey(raw)
            if (key && keys.indexOf(key) < 0) keys.push(key)
            const parts = raw.toLowerCase().replace(/\.desktop$/, "").split(/[^a-z0-9]+/)
            for (let partIndex = 0; partIndex < parts.length; partIndex++) {
                const part = normalizedApplicationKey(parts[partIndex])
                if (part.length >= 3 && keys.indexOf(part) < 0) keys.push(part)
            }
        }
        for (let exactIndex = 0; exactIndex < keys.length; exactIndex++) {
            if (applicationIndex[keys[exactIndex]]) return applicationIndex[keys[exactIndex]]
        }
        const indexedKeys = Object.keys(applicationIndex)
        for (let candidateIndex = 0; candidateIndex < keys.length; candidateIndex++) {
            const requested = keys[candidateIndex]
            if (requested.length < 4) continue
            for (let indexedIndex = 0; indexedIndex < indexedKeys.length; indexedIndex++) {
                const indexed = indexedKeys[indexedIndex]
                if (indexed.endsWith(requested) || requested.endsWith(indexed)) return applicationIndex[indexed]
            }
        }
        return null
    }

    function applicationIcon(candidates) {
        const entry = applicationEntry(candidates)
        return entry ? Design.safeText(entry.icon, "application-x-executable") : "application-x-executable"
    }

    function applicationName(candidates) {
        const entry = applicationEntry(candidates)
        if (entry) return Design.safeText(entry.name, "Janela")
        const values = Array.isArray(candidates) ? candidates : [candidates]
        const raw = Design.safeText(values[0], Design.safeText(values[1], "Janela"))
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
        id: taskCleanup
        interval: 500
        repeat: true
        running: controller.tasks.some(item => Design.safeNumber(item.removeAt, 0) > 0)
        onTriggered: controller.cleanupTasks()
    }
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
        target: Hyprland
        function onActiveToplevelChanged() {
            controller.rememberWindow(Hyprland.activeToplevel)
        }
    }
    Component.onCompleted: rememberWindow(Hyprland.activeToplevel)
}
