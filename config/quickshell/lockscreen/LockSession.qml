import QtQuick
import Quickshell.Services.Pam
import ".."

Item {
    id: session
    visible: false

    required property bool secure
    property bool echo: pam.responseRequired && pam.responseVisible && !authenticating

    property string authState: "idle"
    property string pamMessage: ""
    property bool promptVisible: false
    property string secret: ""
    readonly property int secretLength: Array.from(secret).length
    readonly property bool authenticating: authState === "authenticating"
    readonly property int emptyHideDelay: 4000

    property bool attemptInFlight: false
    property string pendingResponse: ""
    property bool answering: false

    property bool unlocking: false
    property real morphProgress: 0

    signal unlockGranted()
    signal failureShown()

    function appendText(text: string): void {
        let accepted = ""
        for (const character of text) {
            const code = character.codePointAt(0)
            if (code < 0x20 || code === 0x7f || (code >= 0x80 && code < 0xa0)) continue
            accepted += character
        }
        if (!accepted.length) return
        if (authState !== "idle") authState = "idle"
        secret += accepted
        revealPrompt()
    }

    function removeLast(): void {
        const characters = Array.from(secret)
        characters.pop()
        secret = characters.join("")
        afterEdit()
    }

    function clearSecret(): void {
        secret = ""
        afterEdit()
    }

    function afterEdit(): void {
        if (authState !== "idle" && !authenticating) authState = "idle"
        if (secret.length === 0) restartEmptyTimer()
        else emptyTimer.stop()
    }

    function revealPrompt(): void {
        promptVisible = true
        emptyTimer.stop()
    }

    function restartEmptyTimer(): void {
        if (promptVisible && !authenticating && secret.length === 0) emptyTimer.restart()
    }

    function handleKey(event): void {
        event.accepted = true
        if (!secure || authenticating || unlocking) return
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            submit()
        } else if (event.key === Qt.Key_Escape) {
            clearSecret()
        } else if (event.key === Qt.Key_Backspace) {
            if ((event.modifiers & Qt.ControlModifier) !== 0) clearSecret()
            else if (secret.length > 0) removeLast()
            else restartEmptyTimer()
        } else if (event.key === Qt.Key_U && (event.modifiers & Qt.ControlModifier) !== 0) {
            clearSecret()
        } else if (event.text.length > 0) {
            appendText(event.text)
        }
    }

    function submit(): void {
        if (!secure || authenticating || unlocking || secret.length === 0) return
        const response = secret
        secret = ""
        authState = "authenticating"
        pamMessage = ""
        emptyTimer.stop()
        if (pam.active && pam.responseRequired) {
            answering = true
            pam.respond(response)
            return
        }
        if (pam.active) pam.abort()
        pendingResponse = response
        attemptInFlight = true
        if (!pam.start()) {
            pendingResponse = ""
            attemptInFlight = false
            fail("error")
        }
    }

    function fail(kind: string): void {
        pendingResponse = ""
        answering = false
        secret = ""
        attemptInFlight = false
        authState = kind
        pamMessage = ""
        promptVisible = true
        failureShown()
        restartEmptyTimer()
    }

    function conversation(): void {
        if (!pam.responseRequired || !attemptInFlight || answering) return
        if (pendingResponse.length > 0) {
            const response = pendingResponse
            pendingResponse = ""
            answering = true
            pam.respond(response)
        } else {
            authState = "idle"
            pamMessage = pam.message
            revealPrompt()
        }
    }

    PamContext {
        id: pam
        config: "hyprism-lock"
        configDirectory: "/etc/pam.d"

        onPamMessage: session.conversation()
        onResponseRequiredChanged: {
            if (!pam.responseRequired) session.answering = false
            session.conversation()
        }

        onCompleted: result => {
            const expected = session.attemptInFlight
            session.pendingResponse = ""
            session.answering = false
            if (result === PamResult.Success && expected) {
                session.attemptInFlight = false
                session.secret = ""
                session.authState = "idle"
                session.unlocking = true
                session.unlockGranted()
            } else if (result === PamResult.MaxTries) {
                session.fail("maxTries")
            } else if (result === PamResult.Failed) {
                session.fail("failed")
            } else {
                session.fail("error")
            }
        }

        onError: error => {
            if (session.attemptInFlight) session.fail("error")
        }
    }

    Timer {
        id: emptyTimer
        interval: session.emptyHideDelay
        onTriggered: {
            if (session.secret.length === 0 && !session.authenticating) {
                session.promptVisible = false
                session.authState = "idle"
                session.pamMessage = ""
            }
        }
    }

    Component.onDestruction: {
        secret = ""
        pendingResponse = ""
    }
}
