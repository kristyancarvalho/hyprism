import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: service
    visible: false
    required property var controller
    readonly property string rootDir: controller.rootDir
    function refreshApps() { apps.running = true }
    function refreshWallpapers() {
        wallpapers.running = false
        currentWallpaper.running = true
    }
    Process {
        id: apps; command: ["python3", service.rootDir + "/scripts/system/desktop-index.py"]
        stdout: SplitParser { splitMarker: "\n"; onRead: data => { try { service.controller.setApplicationEntries(JSON.parse(data)) } catch (error) { console.warn("índice de aplicativos inválido", error) } } }
    }
    Process {
        id: wallpapers; command: [service.rootDir + "/scripts/wallpaper", "list"]
        stdout: SplitParser { splitMarker: "\n"; onRead: data => { if (data.length) { let next = service.controller.wallpaperEntries.slice(); next.push(data); service.controller.wallpaperEntries = next } } }
        onStarted: service.controller.wallpaperEntries = []
    }
    Process {
        id: currentWallpaper; command: [service.rootDir + "/scripts/wallpaper", "current"]
        stdout: SplitParser { splitMarker: "\n"; onRead: data => service.controller.wallpaperCurrent = data }
        onStarted: service.controller.wallpaperCurrent = ""
        onExited: wallpapers.running = true
    }
    Component.onCompleted: refreshApps()
}
