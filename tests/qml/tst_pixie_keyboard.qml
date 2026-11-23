import QtQuick
import QtQuick.Controls
import QtQuick.VirtualKeyboard
import QtQuick.VirtualKeyboard.Settings
import QtTest
import HyprismPixie

Item {
    id: root
    width: 1920
    height: 1080

    Rectangle { anchors.fill: parent; color: "#1c2030" }
    Component.onCompleted: {
        VirtualKeyboardSettings.styleName = "hyprism"
        KeyboardPalette.background = "#1e2030"
    }

    TextField {
        id: password
        x: 600
        y: 200
        width: 500
        height: 50
        echoMode: TextInput.Password
        inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase | Qt.ImhPreferLowercase
        focus: true
    }

    InputPanel {
        id: panel
        width: Math.min(root.width - 32, root.height * .33 * 3.2)
        x: (root.width - width) / 2
        y: root.height - height - 24
        visible: active
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

    function key(character) {
        return find(panel, item => item.hasOwnProperty("displayText") && item.hasOwnProperty("pressed") && item.displayText === character && item.width > 0)
    }

    TestCase {
        name: "PixieKeyboard"
        when: windowShown

        function init() {
            password.text = ""
            password.forceActiveFocus()
        }

        function test_style_is_hyprism() {
            compare(VirtualKeyboardSettings.styleName, "hyprism")
        }

        function test_input_panel_activates_and_is_compact() {
            Qt.inputMethod.show()
            tryVerify(() => panel.active, 3000)
            verify(panel.height > 0)
            verify(panel.height <= root.height * .36, "keyboard height " + panel.height)
            verify(panel.height >= root.height * .26, "keyboard height " + panel.height)
        }

        function test_password_field_does_not_start_uppercase() {
            Qt.inputMethod.show()
            tryVerify(() => panel.active, 3000)
            wait(300)
            compare(InputContext.uppercase, false)
        }

        function test_virtual_keys_insert_text() {
            Qt.inputMethod.show()
            tryVerify(() => panel.active, 3000)
            wait(300)
            const letters = ["h", "y", "p", "r"]
            for (let i = 0; i < letters.length; i++) {
                const target = key(letters[i])
                verify(target !== null, "missing key " + letters[i])
                const point = target.mapToItem(root, target.width / 2, target.height / 2)
                mouseClick(root, point.x, point.y)
                wait(60)
            }
            compare(password.text, "hypr")
        }

        function test_backspace_removes_text() {
            Qt.inputMethod.show()
            tryVerify(() => panel.active, 3000)
            wait(300)
            const q = key("q")
            const p = q.mapToItem(root, q.width / 2, q.height / 2)
            mouseClick(root, p.x, p.y)
            wait(60)
            compare(password.text, "q")
            const back = find(panel, item => item.hasOwnProperty("pressed") && item.hasOwnProperty("repeat") && item.key === Qt.Key_Backspace)
            verify(back !== null)
            const b = back.mapToItem(root, back.width / 2, back.height / 2)
            mouseClick(root, b.x, b.y)
            wait(60)
            compare(password.text, "")
        }
    }
}
