import QtQuick
import Quickshell

QtObject {
    id: theme
    property bool generatedLoaded: false
    readonly property string sourceName: generatedLoaded ? "generated" : "fallback"
    property var colors: ({ background: "#091015", surface: "#131b21", surfaceVariant: "#202b33", surfaceElevated: "#26333c", surfaceHover: "#2e3d47", surfaceActive: "#395363", foreground: "#e0e8ee", mutedForeground: "#9aa8b2", primary: "#82b1d3", secondary: "#a7c5dc", accent: "#82b1d3", accentDim: "#395363", outline: "#426172", border: "#426172", borderSubtle: "#2d414e", borderNormal: "#426172", borderFocused: "#82b1d3", error: "#e4777f", warning: "#df6852", success: "#82b1d3" })
    property var sourceColors: colors
    property var targetColors: colors
    property real transitionProgress: 1
    property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/hyprism"
    property NumberAnimation paletteTransition: NumberAnimation {
        target: theme
        property: "transitionProgress"
        from: 0
        to: 1
        duration: 240
        easing.type: Easing.InOutCubic
    }

    function channels(value) {
        if (value && value.r !== undefined && value.g !== undefined && value.b !== undefined)
            return [value.r, value.g, value.b, value.a === undefined ? 1 : value.a]
        const match = /^#([0-9a-fA-F]{6})$/.exec(String(value))
        if (!match) return null
        const hex = match[1]
        return [
            parseInt(hex.slice(0, 2), 16) / 255,
            parseInt(hex.slice(2, 4), 16) / 255,
            parseInt(hex.slice(4, 6), 16) / 255,
            1
        ]
    }

    function blendedPalette(progress) {
        const result = Object.assign({}, targetColors)
        const keys = Object.keys(targetColors)
        for (let index = 0; index < keys.length; index++) {
            const key = keys[index]
            const from = channels(sourceColors[key])
            const to = channels(targetColors[key])
            if (!from || !to) continue
            result[key] = Qt.rgba(
                from[0] + (to[0] - from[0]) * progress,
                from[1] + (to[1] - from[1]) * progress,
                from[2] + (to[2] - from[2]) * progress,
                from[3] + (to[3] - from[3]) * progress
            )
        }
        return result
    }

    function applyPalette(palette) {
        const next = Object.assign({}, targetColors, palette)
        if (!generatedLoaded) {
            paletteTransition.stop()
            sourceColors = next
            targetColors = next
            colors = next
            transitionProgress = 1
            generatedLoaded = true
            return
        }
        paletteTransition.stop()
        sourceColors = Object.assign({}, colors)
        targetColors = next
        transitionProgress = 0
        paletteTransition.start()
    }

    onTransitionProgressChanged: {
        if (!generatedLoaded) return
        colors = transitionProgress >= 1 ? Object.assign({}, targetColors) : blendedPalette(transitionProgress)
    }
}
