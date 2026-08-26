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
    readonly property int compactConnectivityIconSize: 13
    readonly property int compactConnectivityTextSize: 11
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
    readonly property int radiusLarge: 16
    readonly property int radiusXs: radiusSmall
    readonly property int radiusSm: radiusDefault
    readonly property int radiusMd: radiusLarge
    readonly property int radiusLg: radiusLarge
    readonly property int radiusIslandCompact: radiusDefault
    readonly property int radiusIslandExpanded: radiusLarge
    readonly property int compactRadius: radiusDefault
    readonly property int animationInstant: 80
    readonly property int animationFast: 110
    readonly property int animationMorph: 150
    readonly property int easingEnter: Easing.OutQuart
    readonly property int easingExit: Easing.InCubic
    readonly property int easingMorph: Easing.OutQuart
    readonly property int easingPanelMorph: Easing.OutBack
    readonly property int easingMove: Easing.InOutCubic
    readonly property real panelMorphOvershoot: .8
    readonly property int recordingDotCompactSize: 11
    readonly property int workspaceCellSize: 24
    readonly property int workspaceCellSpacing: 4
    readonly property int morphSurfaceMaxWidth: 920
    readonly property int morphSurfaceMaxHeight: 700
    readonly property int morphOvershootMargin: 16
    readonly property int launcherMaximumVisibleResults: 6
    readonly property int launcherResultRowHeight: 54
    readonly property int launcherResultSpacing: 5
    readonly property int launcherBaseHeight: 136
    readonly property int emojiColumnCount: 8
    readonly property int emojiButtonSize: 50
    readonly property int emojiCellSpacing: spacingSm
    readonly property int emojiCellSize: emojiButtonSize + emojiCellSpacing
    readonly property int emojiGridWidth: emojiColumnCount * emojiCellSize
    readonly property int emojiPickerWidth: emojiGridWidth + 2 * spacingLg
    readonly property int widgetHeaderHeight: 20
    readonly property int widgetIconSize: 16
    readonly property int widgetInnerPadding: 10
    readonly property int widgetDataRowHeight: 28
    readonly property real widgetScale: 1.18
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
    readonly property int notificationHistoryLimit: 80
    readonly property int notificationCardMinimumHeight: 76
    readonly property int notificationHistoryRowHeight: 68
    readonly property int notificationSpacing: 7
    readonly property int notificationPaddingY: 9
    readonly property int hubPillSectionSpacing: spacingXs
    readonly property int hubNotificationSectionSpacing: spacingSm
    readonly property var icons: ({
        application: "󰀻",
        search: "󰍉",
        refresh: "󰑐",
        close: "󰅖",
        check: "󰄬",
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
        notificationOff: "󰂛",
        power: "󰐥",
        reboot: "󰜉",
        suspend: "󰒲",
        logout: "󰍃",
        night: "󰖔",
        lightTheme: "󰖨",
        whiteTemperature: "󰔏",
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
        calendar: "󰃭",
        recordRegion: "󰩭",
        recordMonitor: "󰍹"
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

    function desaturate(color, amount) {
        const strength = clamp(amount, 0, 1)
        const gray = color.r * .2126 + color.g * .7152 + color.b * .0722
        return Qt.rgba(
            color.r + (gray - color.r) * strength,
            color.g + (gray - color.g) * strength,
            color.b + (gray - color.b) * strength,
            color.a
        )
    }

    function formatDuration(seconds) {
        const value = Math.max(0, Math.floor(safeNumber(seconds, 0)))
        const minutes = Math.floor(value / 60)
        return minutes + ":" + String(value % 60).padStart(2, "0")
    }

    function formatRecordingDuration(seconds) {
        const value = Math.max(0, Math.floor(safeNumber(seconds, 0)))
        const hours = Math.floor(value / 3600)
        const minutes = Math.floor(value % 3600 / 60)
        const remaining = String(value % 60).padStart(2, "0")
        if (hours > 0) return String(hours).padStart(2, "0") + ":" + String(minutes).padStart(2, "0") + ":" + remaining
        return String(minutes).padStart(2, "0") + ":" + remaining
    }

    function notificationCount(count) {
        const value = Math.max(0, Math.floor(safeNumber(count, 0)))
        if (value === 0) return I18n.tr("notifications.savedNone")
        return value === 1 ? I18n.tr("notifications.savedOne") : I18n.tr("notifications.savedMany", { count: value })
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

    function listContentHeight(count, rowHeight, spacing, emptyHeight) {
        const rows = Math.max(0, Math.floor(safeNumber(count, 0)))
        if (!rows) return Math.max(0, safeNumber(emptyHeight, rowHeight))
        return rows * Math.max(0, safeNumber(rowHeight, 0)) + Math.max(0, rows - 1) * Math.max(0, safeNumber(spacing, 0))
    }

    function variableListContentHeight(itemHeight, count, spacing, emptyHeight) {
        const rows = Math.max(0, Math.floor(safeNumber(count, 0)))
        if (!rows) return Math.max(0, safeNumber(emptyHeight, 0))
        return Math.max(0, safeNumber(itemHeight, 0)) + Math.max(0, rows - 1) * Math.max(0, safeNumber(spacing, 0))
    }

    function gridContentHeight(count, columns, cellHeight, emptyHeight) {
        const cells = Math.max(0, Math.floor(safeNumber(count, 0)))
        const columnCount = Math.max(1, Math.floor(safeNumber(columns, 1)))
        const rows = Math.ceil(cells / columnCount)
        return rows ? rows * Math.max(0, safeNumber(cellHeight, 0)) : Math.max(0, safeNumber(emptyHeight, cellHeight))
    }

    function gridColumnCount(width, cellWidth) {
        return Math.max(1, Math.floor(Math.max(0, safeNumber(width, 0)) / Math.max(1, safeNumber(cellWidth, 1))))
    }
}
