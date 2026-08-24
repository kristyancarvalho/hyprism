import QtQuick
import ".."

Rectangle {
    id: pill
    required property var theme
    property string label: ""
    property string iconName: "settings"
    property int value: 0
    property bool available: true
    property bool muted: false
    property bool muteable: false
    property int previewValue: Design.clamp(value, 0, 100)
    readonly property bool controlFocused: activeFocus
    readonly property bool hovered: pointer.containsMouse
    signal changed(int value)
    signal muteClicked()
    signal focusEntered()

    implicitHeight: 52
    visible: available
    activeFocusOnTab: available
    radius: Design.radiusSm
    color: theme.colors.surfaceVariant
    opacity: available ? 1 : .5

    function setPreview(next) {
        previewValue = Math.round(Design.clamp(next, 0, 100))
        changed(previewValue)
    }

    function setFromPosition(position) {
        setPreview(position / Math.max(1, width) * 100)
    }

    function takeFocus() {
        forceActiveFocus(Qt.TabFocusReason)
    }

    onValueChanged: if (!pointer.pressed) previewValue = Design.clamp(value, 0, 100)
    onActiveFocusChanged: if (activeFocus) focusEntered()

    RoundedSurfaceSlice {
        width: pill.width * Design.clamp(pill.previewValue, 0, 100) / 100
        height: parent.height
        surfaceWidth: pill.width
        cornerRadius: pill.radius
        color: pill.muted ? pill.theme.colors.surfaceElevated : pill.theme.colors.accentDim

        Behavior on width {
            enabled: !pointer.pressed
            NumberAnimation { duration: Design.animationFast; easing.type: Design.easingMorph }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: pill.theme.colors.surfaceHover
        opacity: pill.hovered || pointer.pressed ? .16 : 0

        Behavior on opacity { NumberAnimation { duration: Design.animationFast; easing.type: Design.easingMorph } }
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: Design.spacingSm
        anchors.rightMargin: Design.spacingSm
        spacing: Design.spacingSm

        Item {
            id: muteArea
            anchors.verticalCenter: parent.verticalCenter
            width: 32
            height: 32

            Rectangle {
                anchors.fill: parent
                radius: Design.radiusDefault
                color: mutePointer.containsMouse || muteArea.activeFocus ? pill.theme.colors.surfaceHover : "transparent"

                Behavior on color { ColorAnimation { duration: Design.animationFast; easing.type: Design.easingMorph } }

                StatusIcon {
                    anchors.centerIn: parent
                    name: pill.iconName
                    iconSize: Design.iconSm
                    color: pill.muted ? pill.theme.colors.error : pill.theme.colors.foreground
                }
            }

            activeFocusOnTab: pill.muteable
            Keys.onPressed: event => {
                if (pill.muteable && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)) {
                    pill.muteClicked()
                    event.accepted = true
                }
            }

            MouseArea {
                id: mutePointer
                anchors.fill: parent
                enabled: pill.muteable
                hoverEnabled: true
                cursorShape: pill.muteable ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: pill.muteClicked()
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - muteArea.width - parent.spacing
            spacing: 0

            Text {
                width: parent.width
                text: pill.label
                color: pill.muted ? pill.theme.colors.mutedForeground : pill.theme.colors.foreground
                elide: Text.ElideRight
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeXs
                font.weight: Design.fontWeightMedium
            }

            Text {
                width: parent.width
                text: pill.muted ? "Mudo" : Math.round(pill.previewValue) + "%"
                color: pill.muted ? pill.theme.colors.error : pill.theme.colors.foreground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeSm
                font.weight: Design.fontWeightSemibold
            }
        }
    }

    Rectangle {
        visible: pill.hovered || pointer.pressed || pill.activeFocus
        x: Math.max(4, Math.min(parent.width - width - 4, parent.width * Design.clamp(pill.previewValue, 0, 100) / 100 - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        width: 4
        height: parent.height - 12
        radius: 2
        color: pill.theme.colors.foreground
        opacity: .72

        Behavior on x {
            enabled: !pointer.pressed
            NumberAnimation { duration: Design.animationFast; easing.type: Design.easingMorph }
        }
        Behavior on opacity { NumberAnimation { duration: Design.animationFast } }
    }

    Keys.onPressed: event => {
        const increment = event.modifiers & Qt.ShiftModifier ? 10 : 2
        if (event.key === Qt.Key_Left) {
            setPreview(previewValue - increment)
            event.accepted = true
        } else if (event.key === Qt.Key_Right) {
            setPreview(previewValue + increment)
            event.accepted = true
        } else if (event.key === Qt.Key_Home) {
            setPreview(0)
            event.accepted = true
        } else if (event.key === Qt.Key_End) {
            setPreview(100)
            event.accepted = true
        } else if (muteable && event.key === Qt.Key_Space) {
            muteClicked()
            event.accepted = true
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        anchors.leftMargin: muteArea.width + Design.spacingSm * 2
        enabled: pill.available
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        onPressed: mouse => {
            pill.forceActiveFocus(Qt.MouseFocusReason)
            pill.setFromPosition(mouse.x + x)
        }
        onPositionChanged: mouse => {
            if (pressed) pill.setFromPosition(mouse.x + x)
        }
        onWheel: wheel => {
            pill.setPreview(pill.previewValue + (wheel.angleDelta.y > 0 ? 2 : -2))
            wheel.accepted = true
        }
    }
}
