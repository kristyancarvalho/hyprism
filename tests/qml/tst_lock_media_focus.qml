import QtQuick
import QtTest
import "harness"

TestCase {
    id: test
    name: "LockMediaFocus"
    width: 400
    height: 200
    visible: true
    when: windowShown

    property int submits: 0
    property int previous: 0
    property int toggles: 0
    property int next: 0
    property var theme: ({ colors: new Proxy({}, { get: () => "#222222" }) })

    Item {
        id: root
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) test.submits++
            event.accepted = true
        }

        Row {
            ShellButton { id: prev; theme: test.theme; compact: true; keyboardFocusable: false; onClicked: test.previous++ }
            ShellButton { id: toggle; theme: test.theme; compact: true; keyboardFocusable: false; onClicked: test.toggles++ }
            ShellButton { id: nxt; theme: test.theme; compact: true; keyboardFocusable: false; onClicked: test.next++ }
        }
    }

    function init() {
        submits = 0; previous = 0; toggles = 0; next = 0
        root.forceActiveFocus()
    }

    function clickThenSubmit(button, key) {
        mouseClick(button)
        verify(!button.activeFocus)
        verify(root.activeFocus)
        keyClick(Qt.Key_A)
        keyClick(Qt.Key_Space)
        keyClick(Qt.Key_Return)
        keyClick(Qt.Key_Enter)
        compare(submits, 2)
    }

    function test_previous() {
        clickThenSubmit(prev)
        compare(previous, 1); compare(toggles, 0); compare(next, 0)
    }

    function test_toggle() {
        clickThenSubmit(toggle)
        compare(previous, 0); compare(toggles, 1); compare(next, 0)
    }

    function test_next() {
        clickThenSubmit(nxt)
        compare(previous, 0); compare(toggles, 0); compare(next, 1)
    }

    function test_sequence() {
        mouseClick(prev); mouseClick(nxt); mouseClick(toggle); mouseClick(nxt)
        verify(root.activeFocus)
        keyClick(Qt.Key_Return)
        compare(previous, 1); compare(toggles, 1); compare(next, 2); compare(submits, 1)
    }
}
