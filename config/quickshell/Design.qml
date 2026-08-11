pragma Singleton

import QtQuick

QtObject {
    readonly property string fontFamily: "Google Sans Flex"
    readonly property string fontFamilyIcons: "Symbols Nerd Font Mono"
    readonly property int fontSizeXs: 10
    readonly property int fontSizeSm: 12
    readonly property int fontSizeMd: 14
    readonly property int fontSizeLg: 18
    readonly property int fontSizeXl: 28
    readonly property int fontWeightNormal: Font.Normal
    readonly property int fontWeightMedium: Font.Medium
    readonly property int fontWeightSemibold: Font.DemiBold
    readonly property int iconXs: 14
    readonly property int iconSm: 17
    readonly property int iconMd: 21
    readonly property int iconLg: 30
    readonly property int barHeight: 50
    readonly property int barPillHeight: 32
    readonly property int barPaddingHorizontal: 14
    readonly property int barPillPadding: 11
    readonly property int barItemGap: 8
    readonly property int barIconSize: 16
    readonly property int barFontSize: 12
    readonly property int separatorHeight: 18
    readonly property int separatorWidth: 1
    readonly property int radiusSm: 12
    readonly property int radiusMd: 18
    readonly property int radiusLg: 26
    readonly property int outlineWidth: 1
    readonly property int historyLimit: 60
    readonly property var icons: ({
        application: "󰀻",
        workspace: "󰍹",
        search: "󰍉",
        refresh: "󰑐",
        close: "󰅖",
        clear: "󰆴",
        clipboard: "󰅌",
        wifi: "󰖩",
        wifiOff: "󰖪",
        ethernet: "󰈀",
        networkOff: "󰤭",
        lock: "󰌾",
        bluetooth: "󰂯",
        bluetoothConnected: "󰂱",
        bluetoothOff: "󰂲",
        battery: "󰁹",
        batteryLow: "󰁻",
        batteryCritical: "󰂃",
        batteryCharging: "󰂄",
        batteryMissing: "󰂑",
        weatherClear: "󰖙",
        weatherPartlyCloudy: "󰖕",
        weatherCloudy: "󰖐",
        weatherFog: "󰖑",
        weatherRain: "󰖗",
        weatherSnow: "󰖘",
        weatherStorm: "󰙾",
        media: "󰝚",
        previous: "󰒮",
        play: "󰐊",
        pause: "󰏤",
        next: "󰒭",
        volume: "󰕾",
        volumeLow: "󰕿",
        volumeMuted: "󰝟",
        microphone: "󰍬",
        microphoneMuted: "󰍭",
        brightness: "󰃠",
        notification: "󰂚",
        power: "󰐥",
        reboot: "󰜉",
        suspend: "󰒲",
        logout: "󰍃",
        night: "󰖔",
        powerSaver: "󰌪",
        screenshot: "󰹑",
        colorPicker: "󰏘",
        settings: "󰒓",
        chevronRight: "󰅂",
        secure: "󰌾",
        temperature: "󰔏",
        memory: "󰍛",
        cpu: "󰻠",
        gpu: "󰢮",
        networkSpeed: "󰓅",
        calendar: "󰃭"
    })

    function icon(name) {
        return icons[name] || icons.application
    }

    function safeText(value, fallback) {
        if (value === undefined || value === null) return fallback || ""
        const text = String(value).trim()
        if (!text || text === "undefined" || text === "null" || text === "NaN") return fallback || ""
        return text
    }

    function safeNumber(value, fallback) {
        const number = Number(value)
        return Number.isFinite(number) ? number : (fallback || 0)
    }

    function clamp(value, minimum, maximum) {
        return Math.max(minimum, Math.min(maximum, safeNumber(value, minimum)))
    }

    function formatDuration(seconds) {
        const value = Math.max(0, Math.floor(safeNumber(seconds, 0)))
        const minutes = Math.floor(value / 60)
        return minutes + ":" + String(value % 60).padStart(2, "0")
    }

    function notificationCount(count) {
        const value = Math.max(0, Math.floor(safeNumber(count, 0)))
        if (value === 0) return "Nenhuma notificação salva"
        return value === 1 ? "1 notificação salva" : value + " notificações salvas"
    }
}
