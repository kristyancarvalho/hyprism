import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: service
    visible: false
    required property var controller
    function refresh() { entries.running = true }
    function select(item) {
        if (!item) return
        const mime = Design.safeText(item.mime, item.type === "image" ? "image/png" : "text/plain;charset=utf-8")
        controller.run(["sh", "-lc", "cliphist decode " + shellQuote(item.id) + " | wl-copy --type " + shellQuote(mime)])
        controller.showOsd("Área de transferência", item.type === "image" ? "Imagem copiada" : "Texto copiado")
        controller.close()
    }
    function remove(id) { controller.run(["sh", "-lc", "printf '%s\\n' " + shellQuote(id) + " | cliphist delete"]); refreshDelay.restart() }
    function clear() { controller.run(["sh", "-lc", "cliphist wipe"]); controller.clipboardEntries = [] }
    function shellQuote(value) { return "'" + String(value).replace(/'/g, "'\\\"'\\\"'") + "'" }
    Timer { id: refreshDelay; interval: 120; onTriggered: service.refresh() }
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
    }
}
