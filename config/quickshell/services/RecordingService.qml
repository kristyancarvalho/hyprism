import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: service
    visible: false
    required property var controller
    property bool recording: false
    property bool pending: false
    property bool selecting: false
    property bool awaitingSurfaceRelease: false
    property bool stopRequested: false
    property bool saved: false
    property bool developmentRecording: false
    property string mode: ""
    property double startedAt: 0
    property int elapsed: 0
    property string outputPath: ""
    property string lastError: ""
    readonly property string recordingsDir: Quickshell.env("HOME") + "/Vídeos/gravacoes"
    readonly property var ownedProcessId: recorder.processId

    function timestamp() {
        return Qt.formatDateTime(new Date(), "yyyyMMdd_HHmmss_zzz")
    }

    function pathFor(modeName) {
        return recordingsDir + "/" + timestamp() + "_" + modeName + ".mp4"
    }

    function displayPath(path) {
        const home = Design.safeText(Quickshell.env("HOME"), "")
        return home && path.indexOf(home + "/") === 0 ? "~" + path.slice(home.length) : path
    }

    function resetRuntime() {
        recording = false
        pending = false
        selecting = false
        awaitingSurfaceRelease = false
        stopRequested = false
        developmentRecording = false
        startedAt = 0
        elapsed = 0
    }

    function fail(message) {
        const detail = Design.safeText(message, I18n.tr("recording.startError"))
        resetRuntime()
        controller.showOsd(I18n.tr("recording.failed"), detail)
    }

    function launch(modeName, target) {
        if (recorder.running || recording || pending) return
        mode = modeName
        outputPath = pathFor(modeName)
        lastError = ""
        saved = false
        stopRequested = false
        pending = true
        recorder.command = [controller.rootDir + "/scripts/system/recording-backend", modeName, outputPath, target]
        recorder.running = true
    }

    function startRegion() {
        if (recorder.running || recording || pending || selecting) return
        mode = "regiao"
        outputPath = ""
        lastError = ""
        selecting = true
        awaitingSurfaceRelease = true
        controller.close()
        surfaceReleaseFallback.restart()
    }

    function confirmSurfaceReleased() {
        if (!selecting || !awaitingSurfaceRelease || recorder.running) return
        awaitingSurfaceRelease = false
        surfaceReleaseFallback.stop()
        regionLaunch.restart()
    }

    function startMonitor(monitorName) {
        if (recorder.running || recording || pending || selecting) return
        const monitor = Design.safeText(monitorName, "")
        controller.close()
        if (!monitor) {
            fail(I18n.tr("recording.monitorError"))
            return
        }
        launch("tela", monitor)
    }

    function stop() {
        if (developmentRecording) {
            saved = true
            controller.showOsd(I18n.tr("recording.saved"), displayPath(outputPath))
            resetRuntime()
            return
        }
        if (selecting && recorder.running) {
            stopRequested = true
            recorder.signal(15)
            stopTimeout.restart()
            return
        }
        if (selecting) {
            resetRuntime()
            return
        }
        if (!recorder.running) {
            resetRuntime()
            return
        }
        stopRequested = true
        recorder.signal(2)
        stopTimeout.restart()
    }

    function startDevelopment(modeName) {
        if (!controller.developmentMode || recording) return
        controller.close()
        mode = modeName === "regiao" ? "regiao" : "tela"
        outputPath = pathFor(mode)
        startedAt = Date.now()
        elapsed = 0
        saved = false
        pending = false
        selecting = false
        stopRequested = false
        developmentRecording = true
        recording = true
    }

    function launchRegion() {
        if (!selecting || recorder.running || recording || pending) return
        outputPath = pathFor("regiao")
        lastError = ""
        saved = false
        stopRequested = false
        pending = true
        recorder.command = [controller.rootDir + "/scripts/system/recording-backend", "regiao", outputPath, ""]
        recorder.running = true
    }

    Timer {
        id: regionLaunch
        interval: Design.animationMorph
        onTriggered: service.launchRegion()
    }

    Timer {
        id: surfaceReleaseFallback
        interval: 320
        onTriggered: service.confirmSurfaceReleased()
    }

    Timer {
        interval: 1000
        repeat: true
        running: service.recording
        onTriggered: service.elapsed = Math.max(0, Math.floor((Date.now() - service.startedAt) / 1000))
    }

    Timer {
        id: stopTimeout
        interval: 5000
        onTriggered: if (recorder.running) recorder.signal(15)
    }

    Process {
        id: recorder
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (data === "STARTED") {
                    service.selecting = false
                    service.pending = false
                    service.recording = true
                    service.startedAt = Date.now()
                    service.elapsed = 0
                } else if (data === "CANCELED") {
                    service.selecting = false
                    service.pending = false
                } else if (data.indexOf("SAVED:") === 0) {
                    service.saved = true
                    service.outputPath = Design.safeText(data.slice(6), service.outputPath)
                }
            }
        }
        stderr: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                const detail = Design.safeText(data, "")
                if (detail) service.lastError = detail
            }
        }
        onExited: (exitCode, exitStatus) => {
            stopTimeout.stop()
            const completed = service.saved
            const path = service.outputPath
            const hadStarted = service.recording
            service.resetRuntime()
            if (completed) service.controller.showOsd(I18n.tr("recording.saved"), service.displayPath(path))
            else if (hadStarted || exitCode !== 0) service.controller.showOsd(I18n.tr("recording.failed"), I18n.tr("recording.exitError"))
        }
    }

    Component.onCompleted: controller.recordingService = service
}
