import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: service
    visible: false
    required property var controller
    readonly property string rootDir: controller.rootDir
    readonly property string networkInterface: Design.safeText(controller.widgetConfig("network").interface, "auto")
    function synchronize() {
        stream.running = false
        restart.restart()
    }
    onNetworkInterfaceChanged: synchronize()
    Process {
        id: stream
        command: ["python3", service.rootDir + "/scripts/system/state-daemon.py", service.networkInterface]
        stdout: SplitParser { splitMarker: "\n"; onRead: data => { try { service.controller.updateSystem(JSON.parse(data)); service.controller.systemServiceAvailable = true } catch (error) { console.warn("hyprism state parse", error) } } }
        onExited: { service.controller.systemServiceAvailable = false; restart.start() }
    }
    Timer { id: restart; interval: 2500; onTriggered: stream.running = true }
    Process {
        id: weather
        command: ["python3", service.rootDir + "/scripts/system/weather.py"]
        stdout: SplitParser { splitMarker: "\n"; onRead: data => { try { service.controller.weather = Object.assign({}, service.controller.weather, JSON.parse(data)) } catch (error) {} } }
    }
    Timer { interval: 1800000; running: true; repeat: true; triggeredOnStart: true; onTriggered: weather.running = true }
    Component.onCompleted: restart.start()
}
