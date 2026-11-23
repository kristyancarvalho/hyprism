import QtQuick
import QtTest
import "../../themes/hyprism-pixie/components"

Item {
    id: root
    width: 600
    height: 200

    QtObject {
        id: power
        property bool canSuspend: true
        property bool canReboot: true
        property bool canPowerOff: false
        property var calls: []
        function suspend() { calls = calls.concat("suspend") }
        function reboot() { calls = calls.concat("reboot") }
        function powerOff() { calls = calls.concat("powerOff") }
    }

    PowerBar {
        id: bar
        power: power
        x: 20
        y: 20
        suspendText: "Suspend"
        restartText: "Restart"
        shutdownText: "Shut down"
    }

    function visibleButtons() {
        const buttons = []
        for (let i = 0; i < bar.children.length; i++) {
            const child = bar.children[i]
            if (child.hasOwnProperty("clicked") && child.visible && child.hasOwnProperty("down")) buttons.push(child)
        }
        return buttons
    }

    TestCase {
        name: "PixiePowerBar"
        when: windowShown

        function init() { power.calls = []; power.canSuspend = true; power.canReboot = true; power.canPowerOff = false }

        function test_only_supported_actions_are_offered() {
            compare(root.visibleButtons().length, 2)
            power.canPowerOff = true
            compare(root.visibleButtons().length, 3)
            power.canSuspend = false
            power.canReboot = false
            compare(root.visibleButtons().length, 1)
        }

        function test_buttons_invoke_the_matching_power_action_without_real_power_operations() {
            power.canPowerOff = true
            wait(50)
            const buttons = root.visibleButtons()
            compare(buttons.length, 3)
            const byAction = {}
            for (let i = 0; i < buttons.length; i++) byAction[buttons[i].modelData.action] = buttons[i]
            compare(Object.keys(byAction).sort(), ["powerOff", "reboot", "suspend"])
            const expected = ["suspend", "reboot", "powerOff"]
            for (let i = 0; i < expected.length; i++) {
                mouseClick(byAction[expected[i]])
                compare(power.calls.length, i + 1)
                compare(power.calls[i], expected[i])
            }
        }

        function test_missing_power_backend_hides_every_action() {
            bar.power = null
            compare(root.visibleButtons().length, 0)
            bar.power = power
        }
    }
}
