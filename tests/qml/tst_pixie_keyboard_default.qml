import QtQuick
import QtTest

Item {
    id: host
    width: 1920
    height: 1080

    QtObject {
        id: config
        property string language: "en"
        property string background: ""
        property string accentColor: "#d79921"
        property string accentForegroundColor: "#282828"
        property string backgroundColor: "#282828"
        property string surfaceColor: "#3c3836"
        property string surfaceVariantColor: "#504945"
        property string textColor: "#ebdbb2"
        property string mutedColor: "#bdae93"
        property string errorColor: "#fb4934"
        property string fontFamily: ""
        property bool use24HourClock: false
    }

    ListModel {
        id: userModel
        property int lastIndex: 0
        ListElement { name: "demo"; realName: "Demo" }
    }

    ListModel {
        id: sessionModel
        property int lastIndex: 0
        ListElement { name: "Hyprland" }
    }

    QtObject {
        id: sddm
        property string lastUser: "demo"
        property string currentUser: "demo"
        property bool canSuspend: true
        property bool canReboot: true
        property bool canPowerOff: true
        property var logins: []
        signal loginFailed()
        signal loginSucceeded()
        function login(user, password, session) { logins = logins.concat([[user, password, session]]) }
        function suspend() {}
        function reboot() {}
        function powerOff() {}
    }

    Loader {
        id: loader
        anchors.fill: parent
        source: Qt.resolvedUrl("../../themes/hyprism-pixie/Main.qml")
    }

    function find(item, predicate) {
        if (predicate(item)) return item
        const children = item.children
        for (let i = 0; i < children.length; i++) {
            const found = find(children[i], predicate)
            if (found) return found
        }
        return null
    }

    TestCase {
        name: "PixieKeyboardDefault"
        when: windowShown && loader.status === Loader.Ready

        property var greeter: loader.item

        function field() { return host.find(greeter, item => item.hasOwnProperty("echoMode") && item.hasOwnProperty("inputMethodHints")) }
        function toggle() { return host.find(greeter, item => item.hasOwnProperty("clicked") && item.hasOwnProperty("down") && item.Accessible && item.Accessible.name === "Virtual keyboard") }
        function panel() { return host.find(greeter, item => item.hasOwnProperty("keyboard") && item.hasOwnProperty("active")) }
        function clickToggle() {
            const button = toggle()
            verify(button !== null, "keyboard toggle")
            const point = button.mapToItem(host, button.width / 2, button.height / 2)
            mouseClick(host, point.x, point.y)
            wait(50)
        }
        function key(character) {
            return host.find(panel(), item => item.hasOwnProperty("displayText") && item.hasOwnProperty("pressed") && item.displayText === character && item.width > 0)
        }
        function visibleBottom() { return panel().visible ? panel().y : host.height }

        function init() {
            greeter.hideLogin()
            wait(350)
        }

        function test_keyboard_hidden_on_start_and_after_reveal() {
            compare(greeter.keyboardRequested, false)
            compare(panel().visible, false)
            greeter.revealLogin()
            wait(600)
            verify(field().activeFocus, "password field focused")
            compare(greeter.keyboardRequested, false)
            compare(greeter.keyboardVisible, false)
            compare(panel().visible, false)
            compare(Qt.inputMethod.visible, false)
        }

        function test_physical_typing_and_submit_keep_keyboard_hidden() {
            greeter.revealLogin()
            wait(600)
            keyClick("s"); keyClick("e"); keyClick("c")
            compare(field().text, "sec")
            keyClick(Qt.Key_Return)
            wait(100)
            compare(sddm.logins.length > 0, true)
            compare(sddm.logins[sddm.logins.length - 1][1], "sec")
            compare(panel().visible, false)
            sddm.loginFailed()
            wait(500)
            compare(greeter.keyboardRequested, false)
            compare(panel().visible, false)
        }

        function test_mouse_toggle_opens_types_and_closes() {
            greeter.revealLogin()
            wait(600)
            clickToggle()
            compare(greeter.keyboardRequested, true)
            tryVerify(() => panel().active && panel().visible, 3000)
            wait(500)
            const letters = ["h", "y", "p"]
            for (let i = 0; i < letters.length; i++) {
                const target = key(letters[i])
                verify(target !== null, "missing key " + letters[i])
                const point = target.mapToItem(host, target.width / 2, target.height / 2)
                mouseClick(host, point.x, point.y)
                wait(60)
            }
            compare(field().text, "hyp")
            clickToggle()
            compare(greeter.keyboardRequested, false)
            tryVerify(() => !panel().visible, 3000)
        }

        function test_keyboard_resets_when_login_hides() {
            greeter.revealLogin()
            wait(600)
            clickToggle()
            tryVerify(() => panel().visible, 3000)
            greeter.hideLogin()
            compare(greeter.keyboardRequested, false)
            wait(400)
            greeter.revealLogin()
            wait(600)
            compare(greeter.keyboardRequested, false)
            compare(panel().visible, false)
        }
    }
}
