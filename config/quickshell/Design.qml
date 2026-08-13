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
    readonly property int spacingXs: 4
    readonly property int spacingSm: 8
    readonly property int spacingMd: 12
    readonly property int spacingLg: 18
    readonly property int shellTopMargin: 8
    readonly property int compactBarHeight: 44
    readonly property int compactBottomGap: 4
    readonly property int compactWidthMin: 580
    readonly property int compactWidthMax: 680
    readonly property int compactItemHeight: 30
    readonly property int compactIconSize: 16
    readonly property int compactTextSize: 12
    readonly property int compactHorizontalPadding: 16
    readonly property int compactPillPadding: 10
    readonly property int compactPlainPadding: 4
    readonly property int compactItemSpacing: spacingSm
    readonly property int compactGroupSpacing: spacingMd
    readonly property int compactSeparatorHeight: 16
    readonly property int compactSeparatorWidth: 1
    readonly property int radiusSmall: 6
    readonly property int radiusDefault: 9
    readonly property int radiusLarge: 12
    readonly property int radiusXs: radiusSmall
    readonly property int radiusSm: radiusDefault
    readonly property int radiusMd: radiusDefault
    readonly property int radiusLg: radiusLarge
    readonly property int radiusIslandCompact: radiusDefault
    readonly property int radiusIslandExpanded: radiusDefault
    readonly property int compactRadius: radiusDefault
    readonly property int animationInstant: 80
    readonly property int animationFast: 110
    readonly property int animationMorph: 150
    readonly property int workspaceCellSize: 24
    readonly property int workspaceCellSpacing: 4
    readonly property int morphSurfaceMaxWidth: 920
    readonly property int morphSurfaceMaxHeight: 700
    readonly property int launcherMaximumVisibleResults: 6
    readonly property int launcherResultRowHeight: 54
    readonly property int launcherResultSpacing: 5
    readonly property int launcherBaseHeight: 136
    readonly property int widgetHeaderHeight: 20
    readonly property int widgetIconSize: 16
    readonly property int widgetInnerPadding: 10
    readonly property int barHeight: compactBarHeight
    readonly property int barPillHeight: compactItemHeight
    readonly property int barPaddingHorizontal: compactHorizontalPadding
    readonly property int barPillPadding: compactPillPadding
    readonly property int barItemGap: compactItemSpacing
    readonly property int barIconSize: compactIconSize
    readonly property int barFontSize: compactTextSize
    readonly property int separatorHeight: compactSeparatorHeight
    readonly property int separatorWidth: compactSeparatorWidth
    readonly property int outlineWidth: 1
    readonly property int historyLimit: 60
    readonly property var icons: ({
        application: "󰀻",
        search: "󰍉",
        refresh: "󰑐",
        close: "󰅖",
        clear: "󰆴",
        clipboard: "󰅌",
        image: "󰋩",
        wifiDisconnected: "󰤮",
        wifiOutline: "󰤯",
        wifiWeak: "󰤟",
        wifiMedium: "󰤢",
        wifiStrong: "󰤨",
        ethernet: "󰈀",
        networkOff: "󰤭",
        lock: "󰌾",
        bluetooth: "󰂯",
        bluetoothConnected: "󰂱",
        bluetoothOff: "󰂲",
        battery0: "",
        battery1: "",
        battery2: "",
        battery3: "",
        battery4: "",
        charging: "",
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
        networkDownload: "󰇚",
        networkUpload: "󰕒",
        storage: "󰋊",
        uptime: "󰔚",
        services: "󰒋",
        tasks: "󰄬",
        processes: "󰧑",
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

    function compactTopMargin(shellConfig) {
        return Math.max(0, Math.round(safeNumber(shellConfig ? shellConfig.topMargin : shellTopMargin, shellTopMargin)))
    }

    function compactHeight(shellConfig) {
        return Math.max(compactBarHeight, Math.round(safeNumber(shellConfig ? shellConfig.compactHeight : compactBarHeight, compactBarHeight)))
    }

    function compactGap(shellConfig) {
        return Math.max(0, Math.round(safeNumber(shellConfig ? shellConfig.reserveGap : compactBottomGap, compactBottomGap)))
    }

    function compactRadiusFor(shellConfig) {
        return radiusDefault
    }

    function compactReservedHeight(shellConfig) {
        return compactTopMargin(shellConfig) + compactHeight(shellConfig) + compactGap(shellConfig)
    }

    function compactWidth(shellConfig, availableWidth) {
        const maximum = Math.max(320, safeNumber(availableWidth, compactWidthMax) - 32)
        const requested = safeNumber(shellConfig ? shellConfig.islandWidth : compactWidthMin, compactWidthMin)
        return Math.min(maximum, Math.max(compactWidthMin, Math.min(compactWidthMax, requested)))
    }

    function launcherHeight(resultCount) {
        const visibleRows = Math.max(1, Math.min(launcherMaximumVisibleResults, Math.floor(safeNumber(resultCount, 0))))
        return launcherBaseHeight + visibleRows * launcherResultRowHeight + Math.max(0, visibleRows - 1) * launcherResultSpacing
    }
}
