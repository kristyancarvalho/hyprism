import QtQuick
import Quickshell

QtObject {
    property bool generatedLoaded: false
    readonly property string sourceName: generatedLoaded ? "generated" : "fallback"
    property var colors: ({ background: "#091015", surface: "#131b21", surfaceVariant: "#202b33", surfaceElevated: "#26333c", surfaceHover: "#2e3d47", surfaceActive: "#395363", foreground: "#e0e8ee", mutedForeground: "#9aa8b2", primary: "#82b1d3", secondary: "#a7c5dc", accent: "#82b1d3", accentDim: "#395363", outline: "#426172", border: "#426172", borderSubtle: "#2d414e", borderNormal: "#426172", borderFocused: "#82b1d3", error: "#e4777f", warning: "#df6852", success: "#82b1d3" })
    property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/hyprism"
}
