import QtQuick
import ".."

Row {
    id: strip
    required property var shellScreen
    required property var theme
    property int workspaceCount: 10
    readonly property var shellMonitor: HyprlandService.monitorFor(shellScreen)
    readonly property var activeWorkspace: shellMonitor ? shellMonitor.activeWorkspace : null
    spacing: Design.workspaceCellSpacing

    function workspaceFor(workspaceId) {
        return HyprlandService.workspaceFor(workspaceId)
    }

    function hasWindows(workspace) {
        if (!workspace) return false
        if (workspace.toplevels && workspace.toplevels.values) return workspace.toplevels.values.length > 0
        return Design.safeNumber(workspace.lastIpcObject ? workspace.lastIpcObject.windows : 0, 0) > 0
    }

    function isUrgent(workspace) {
        if (!workspace) return false
        if (workspace.urgent === true) return true
        const values = workspace.toplevels && workspace.toplevels.values ? workspace.toplevels.values : []
        for (let i = 0; i < values.length; i++) {
            if (values[i] && values[i].urgent === true) return true
        }
        return false
    }

    function visibleWorkspaceIds() {
        const activeId = activeWorkspace ? Design.clamp(activeWorkspace.id, 1, workspaceCount) : 1
        const selected = []
        const add = workspaceId => {
            if (workspaceId >= 1 && workspaceId <= workspaceCount && selected.indexOf(workspaceId) < 0 && selected.length < 5) selected.push(workspaceId)
        }
        add(activeId)
        add(activeId - 1)
        add(activeId + 1)
        for (let workspaceId = 1; workspaceId <= workspaceCount; workspaceId++) {
            const workspace = workspaceFor(workspaceId)
            if (isUrgent(workspace)) add(workspaceId)
        }
        for (let workspaceId = 1; workspaceId <= workspaceCount; workspaceId++) {
            if (hasWindows(workspaceFor(workspaceId))) add(workspaceId)
        }
        return selected.sort((left, right) => left - right)
    }

    Repeater {
        model: strip.visibleWorkspaceIds()

        Rectangle {
            id: cell
            required property int modelData
            readonly property var workspace: strip.workspaceFor(modelData)
            readonly property bool active: strip.activeWorkspace && strip.activeWorkspace.id === modelData
            readonly property bool occupied: strip.hasWindows(workspace)
            readonly property bool urgent: strip.isUrgent(workspace)
            width: Design.workspaceCellSize
            height: Design.workspaceCellSize
            radius: Design.radiusDefault
            color: urgent ? strip.theme.colors.error : active ? strip.theme.colors.accent : occupied ? strip.theme.colors.surfaceElevated : "transparent"
            border.width: activeFocus ? 2 : active || urgent ? 0 : Design.outlineWidth
            border.color: activeFocus ? strip.theme.colors.borderFocused : occupied ? strip.theme.colors.borderNormal : strip.theme.colors.borderSubtle
            opacity: active || urgent || occupied ? 1 : .5
            activeFocusOnTab: true

            Text {
                anchors.fill: parent
                text: cell.modelData
                color: cell.active ? strip.theme.colors.background : cell.urgent || cell.occupied ? strip.theme.colors.foreground : strip.theme.colors.mutedForeground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeXs
                font.weight: cell.active ? Design.fontWeightSemibold : Design.fontWeightMedium
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                    HyprlandService.switchWorkspace(cell.modelData)
                    event.accepted = true
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    cell.forceActiveFocus()
                    HyprlandService.switchWorkspace(cell.modelData)
                }
            }
        }
    }
}
