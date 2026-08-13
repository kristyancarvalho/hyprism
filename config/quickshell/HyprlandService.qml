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

    function normalizedAddress(address) {
        const raw = Design.safeText(address, "")
        if (/^0x[0-9a-f]+$/i.test(raw)) return raw
        if (/^[0-9a-f]+$/i.test(raw)) return "0x" + raw
        return ""
    }

    function focusWindow(address) {
        const normalized = normalizedAddress(address)
        if (!normalized) return false
        Hyprland.dispatch("hl.dsp.focus({ window = \"address:" + normalized + "\" })")
        return true
    }

    function monitorFor(screen) {
        return screen ? Hyprland.monitorFor(screen) : null
    }

    function monitorHasFullscreen(screen) {
        const monitor = monitorFor(screen)
        return !!(monitor && monitor.activeWorkspace && monitor.activeWorkspace.hasFullscreen)
    }
}
