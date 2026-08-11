import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: service
    visible: false
    required property var controller
    property string rootDir: Quickshell.env("HYPRISM_ROOT") || Quickshell.env("HOME") + "/.local/share/hyprism"
    function refreshApps() { apps.running = true }
    function refreshWallpapers() { wallpapers.running = true }
    Process {
        id: apps; command: ["python3", service.rootDir + "/scripts/system/desktop-index.py"]
        stdout: SplitParser { splitMarker: "\n"; onRead: data => { try { service.controller.appEntries = JSON.parse(data) } catch (error) { console.warn("app index", error) } } }
    }
    Process {
        id: wallpapers; command: ["sh", "-lc", service.rootDir + "/scripts/wallpaper list"]
        stdout: SplitParser { splitMarker: "\n"; onRead: data => { if (data.length) { let next = service.controller.wallpaperEntries.slice(); next.push(data); service.controller.wallpaperEntries = next } } }
        onStarted: service.controller.wallpaperEntries = []
    }
    Component.onCompleted: refreshApps()
}
