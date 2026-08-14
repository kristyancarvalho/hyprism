import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: service
    visible: false
    required property var controller
    property bool refreshPending: false
    readonly property string eventPath: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/hyprism/state/clipboard-event"
    function refresh() {
        if (entries.running) {
            refreshPending = true
            return
        }
        entries.running = true
    }
    function select(item) {
        if (!item) return
        const mime = Design.safeText(item.mime, item.type === "image" ? "image/png" : "text/plain;charset=utf-8")
        controller.run([service.controller.rootDir + "/scripts/system/action", "clipboard-restore", String(item.id), mime])
        controller.showOsd("Área de transferência", item.type === "image" ? "Imagem copiada" : "Texto copiado")
        controller.close()
    }
    function remove(id) { controller.run([service.controller.rootDir + "/scripts/system/action", "clipboard-delete", String(id)]); refreshDelay.restart() }
    function clear() { controller.run([service.controller.rootDir + "/scripts/system/action", "clipboard-clear"]); controller.clipboardEntries = []; refreshDelay.restart() }
    Timer { id: refreshDelay; interval: 90; onTriggered: service.refresh() }
    FileView {
        id: clipboardEvent
        path: service.eventPath
        blockLoading: true
        preload: true
        watchChanges: true
        printErrors: false
        onLoaded: refreshDelay.restart()
        onTextChanged: refreshDelay.restart()
        onFileChanged: reload()
    }
    Process {
        id: entries
        command: ["python3", service.controller.rootDir + "/scripts/system/clipboard-history.py"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                try { service.controller.clipboardEntries = JSON.parse(data) }
                catch (error) { service.controller.clipboardEntries = [] }
            }
        }
        onExited: {
            if (service.refreshPending) {
                service.refreshPending = false
                refreshDelay.restart()
            }
        }
    }
}
