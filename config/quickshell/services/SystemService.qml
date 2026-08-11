import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: service
    visible: false
    required property var controller
    property string rootDir: Quickshell.env("HYPRISM_ROOT") || Quickshell.env("HOME") + "/.local/share/hyprism"
    Process {
        id: stream
        command: ["python3", service.rootDir + "/scripts/system/state-daemon.py"]
        running: true
        stdout: SplitParser { splitMarker: "\n"; onRead: data => { try { service.controller.system = JSON.parse(data) } catch (error) { console.warn("hyprism state parse", error) } } }
        onExited: restart.start()
    }
    Timer { id: restart; interval: 2500; onTriggered: stream.running = true }
    Process {
        id: weather
        command: ["python3", service.rootDir + "/scripts/system/weather.py"]
        stdout: SplitParser { splitMarker: "\n"; onRead: data => { try { service.controller.weather = JSON.parse(data) } catch (error) {} } }
    }
    Timer { interval: 1800000; running: true; repeat: true; triggeredOnStart: true; onTriggered: weather.running = true }
}
