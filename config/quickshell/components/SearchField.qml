import QtQuick
import ".."

FocusScope {
    id: control
    required property var theme
    property alias text: input.text
    property string placeholderText: ""
    property string iconName: "search"
    property bool clearButtonEnabled: true
    property color focusedSurfaceColor: theme.colors.surfaceVariant
    property bool focusIndicatorEnabled: true
    property color focusIndicatorColor: theme.colors.accent
    property Item tabTarget: null
    property Item backtabTarget: null
    readonly property bool inputActiveFocus: input.activeFocus
    readonly property bool clearVisible: clearButton.visible
    readonly property Item clearButtonItem: clearButton
    property alias echoMode: input.echoMode
    signal keyPressed(var event)
    signal inputFocusChanged(bool active)
    signal clearRequested()

    implicitHeight: 42
    activeFocusOnTab: true

    function forceInputFocus(reason) {
        input.forceActiveFocus(reason === undefined ? Qt.OtherFocusReason : reason)
    }

    Rectangle {
        anchors.fill: parent
        radius: Design.radiusSm
        color: input.activeFocus ? control.focusedSurfaceColor : control.theme.colors.surfaceVariant
        border.width: 0

        Behavior on color {
            ColorAnimation { duration: Design.animationFast; easing.type: Design.easingMorph }
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: Design.spacingMd
                rightMargin: Design.spacingMd
            }
            height: 1
            radius: .5
            color: control.focusIndicatorColor
            opacity: control.focusIndicatorEnabled && input.activeFocus ? .7 : 0

            Behavior on opacity { NumberAnimation { duration: Design.animationFast; easing.type: Design.easingMorph } }
        }

        StatusIcon {
            id: searchIcon
            anchors.left: parent.left
            anchors.leftMargin: Design.spacingMd
            anchors.verticalCenter: parent.verticalCenter
            name: control.iconName
            iconSize: Design.iconSm
            color: control.theme.colors.mutedForeground
        }

        TextInput {
            id: input
            anchors {
                left: searchIcon.right
                right: clearButton.left
                top: parent.top
                bottom: parent.bottom
                leftMargin: Design.spacingSm
                rightMargin: Design.spacingSm
            }
            focus: true
            color: control.theme.colors.foreground
            selectionColor: control.theme.colors.accent
            selectedTextColor: control.theme.colors.background
            font.family: Design.fontFamily
            font.pixelSize: Design.fontSizeSm
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: event => control.keyPressed(event)
            KeyNavigation.tab: clearButton.visible ? clearButton : control.tabTarget
            KeyNavigation.backtab: control.backtabTarget
            onActiveFocusChanged: control.inputFocusChanged(activeFocus)
        }

        Text {
            anchors {
                left: input.left
                right: input.right
                verticalCenter: parent.verticalCenter
            }
            visible: input.text.length === 0
            text: control.placeholderText
            color: control.theme.colors.mutedForeground
            font.family: Design.fontFamily
            font.pixelSize: Design.fontSizeSm
            elide: Text.ElideRight
        }

        ShellButton {
            id: clearButton
            anchors.right: parent.right
            anchors.rightMargin: Design.spacingXs
            anchors.verticalCenter: parent.verticalCenter
            visible: control.clearButtonEnabled && input.text.length > 0
            width: visible ? 34 : 0
            theme: control.theme
            iconName: "close"
            compact: true
            onClicked: {
                control.clearRequested()
                input.forceActiveFocus(Qt.MouseFocusReason)
            }
            KeyNavigation.tab: control.tabTarget
            KeyNavigation.backtab: input
        }
    }
}
