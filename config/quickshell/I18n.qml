pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: i18n

    property string locale: "en"
    property var english: ({})
    property var portuguese: ({})
    property int revision: 0
    readonly property var supportedLocales: ["en", "pt-BR"]

    function lookup(source, key) {
        const segments = key.split(".")
        let value = source
        for (let index = 0; index < segments.length; index++) {
            if (!value || typeof value !== "object" || !(segments[index] in value)) return ""
            value = value[segments[index]]
        }
        return typeof value === "string" ? value : ""
    }

    function tr(key, values) {
        const generation = revision
        const active = locale === "pt-BR" ? portuguese : english
        let text = lookup(active, key) || lookup(english, key) || ""
        if (!text) {
            const segment = key.split(".").pop().replace(/([a-z])([A-Z])/g, "$1 $2").toLowerCase()
            text = segment.length ? segment.charAt(0).toUpperCase() + segment.slice(1) : "Unavailable"
        }
        if (values && typeof values === "object") {
            const names = Object.keys(values)
            for (let index = 0; index < names.length; index++) text = text.split("{" + names[index] + "}").join(String(values[names[index]]))
        }
        return text
    }

    function load(view, fallback) {
        try {
            const parsed = JSON.parse(view.text())
            return parsed && typeof parsed === "object" && !Array.isArray(parsed) ? parsed : fallback
        } catch (error) {
            return fallback
        }
    }

    property var englishFile: FileView {
        path: Quickshell.shellDir + "/i18n/en.json"
        blockLoading: true
        preload: true
        watchChanges: true
        printErrors: false
        onLoaded: { i18n.english = i18n.load(englishFile, i18n.english); i18n.revision++ }
        onTextChanged: { i18n.english = i18n.load(englishFile, i18n.english); i18n.revision++ }
        onFileChanged: reload()
    }

    property var portugueseFile: FileView {
        path: Quickshell.shellDir + "/i18n/pt-BR.json"
        blockLoading: true
        preload: true
        watchChanges: true
        printErrors: false
        onLoaded: { i18n.portuguese = i18n.load(portugueseFile, i18n.portuguese); i18n.revision++ }
        onTextChanged: { i18n.portuguese = i18n.load(portugueseFile, i18n.portuguese); i18n.revision++ }
        onFileChanged: reload()
    }
}
