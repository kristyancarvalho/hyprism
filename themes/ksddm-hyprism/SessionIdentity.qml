import QtQuick

QtObject {
    function profile(name) {
        const normalized = String(name || "").toLowerCase().replace(/[^a-z0-9]+/g, "")
        const profiles = [
            { key: "hyprland", glyph: "", matches: ["hyprland"] },
            { key: "dwm", glyph: "", matches: ["dwm"] },
            { key: "plasma", glyph: "", matches: ["plasma", "kde"] },
            { key: "gnome", glyph: "", matches: ["gnome"] },
            { key: "xfce", glyph: "", matches: ["xfce"] },
            { key: "sway", glyph: "", matches: ["sway"] },
            { key: "i3", glyph: "", matches: ["i3"] },
            { key: "qtile", glyph: "", matches: ["qtile"] },
            { key: "awesome", glyph: "", matches: ["awesome"] },
            { key: "bspwm", glyph: "", matches: ["bspwm"] },
            { key: "cinnamon", glyph: "", matches: ["cinnamon"] },
            { key: "mate", glyph: "", matches: ["mate"] },
            { key: "lxde", glyph: "", matches: ["lxde"] },
            { key: "lxqt", glyph: "", matches: ["lxqt"] },
            { key: "dwl", glyph: "󰖯", matches: ["dwl"] }
        ]
        for (let index = 0; index < profiles.length; index++) {
            const entry = profiles[index]
            for (let match = 0; match < entry.matches.length; match++) {
                if (normalized.indexOf(entry.matches[match]) >= 0) return entry
            }
        }
        return { key: "generic", glyph: "󰖯", matches: [] }
    }
}
