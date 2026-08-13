import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: service
    visible: false
    required property var controller
    function refresh() { entries.running = true }
    function select(id) { controller.run(["sh", "-lc", "cliphist decode " + shellQuote(id) + " | wl-copy"]); controller.showOsd("Área de transferência", "Copiado"); controller.close() }
    function remove(id) { controller.run(["sh", "-lc", "cliphist delete " + shellQuote(id)]); refresh() }
    function clear() { controller.run(["sh", "-lc", "cliphist wipe"]); controller.clipboardEntries = [] }
    function shellQuote(value) { return "'" + String(value).replace(/'/g, "'\\\"'\\\"'") + "'" }
    Process {
        id: entries; command: ["sh", "-lc", "command -v cliphist >/dev/null 2>&1 && cliphist list"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                let separator = data.indexOf("\t")
                let item = { id: separator >= 0 ? data.slice(0, separator) : data, text: separator >= 0 ? data.slice(separator + 1) : data }
                let next = service.controller.clipboardEntries.slice(); next.push(item); service.controller.clipboardEntries = next
            }
        }
        onStarted: service.controller.clipboardEntries = []
    }
}
