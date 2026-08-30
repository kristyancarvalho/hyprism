import QtQuick
import Quickshell.Io

Item {
    id: service
    visible: false
    required property var controller
    readonly property string rootDir: controller.rootDir
    readonly property var widgetConfig: controller.config.shell.widgets
    readonly property string configuration: JSON.stringify(widgetConfig)
    readonly property int configurationRevision: controller.configurationRevision
    readonly property bool needed: controller.widgetEnabled("storage") || controller.widgetEnabled("sensors") || controller.widgetEnabled("uptime") || controller.widgetEnabled("services") || controller.widgetEnabled("processes")

    function synchronize() {
        monitor.running = false
        restart.stop()
        if (needed) restart.start()
        else controller.resetMonitoring()
    }

    onConfigurationRevisionChanged: synchronize()
    onNeededChanged: synchronize()

    Process {
        id: monitor
        command: ["python3", service.rootDir + "/scripts/system/monitoring-daemon.py", service.configuration]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                try {
                    service.controller.updateMonitoring(JSON.parse(data))
                } catch (error) {
                    console.warn("monitoramento do sistema inválido", error)
                }
            }
        }
        onExited: {
            if (service.needed) restart.start()
        }
    }

    Timer {
        id: restart
        interval: 120
        onTriggered: monitor.running = service.needed
    }

    Component.onCompleted: synchronize()
}
