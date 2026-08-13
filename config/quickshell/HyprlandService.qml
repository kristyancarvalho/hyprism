pragma Singleton

import QtQuick
import Quickshell.Hyprland

QtObject {
    function workspaceFor(workspaceId) {
        const workspaces = Hyprland.workspaces && Hyprland.workspaces.values ? Hyprland.workspaces.values : []
        for (let index = 0; index < workspaces.length; index++) {
            if (workspaces[index] && workspaces[index].id === workspaceId) return workspaces[index]
        }
        return null
    }

    function switchWorkspace(workspaceId) {
        const id = Math.max(1, Math.floor(Design.safeNumber(workspaceId, 1)))
        const workspace = workspaceFor(id)
        if (workspace) {
            workspace.activate()
            return
        }
        Hyprland.dispatch("hl.dsp.focus({ workspace = " + id + " })")
    }

    function moveWindowToWorkspace(workspaceId) {
        const id = Math.max(1, Math.floor(Design.safeNumber(workspaceId, 1)))
        Hyprland.dispatch("hl.dsp.window.move({ workspace = " + id + " })")
    }

    function focusWindow(window) {
        if (window) window.activate()
    }

    function monitorFor(screen) {
        return screen ? Hyprland.monitorFor(screen) : null
    }

    function monitorHasFullscreen(screen) {
        const monitor = monitorFor(screen)
        return !!(monitor && monitor.activeWorkspace && monitor.activeWorkspace.hasFullscreen)
    }
}
