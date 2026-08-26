import QtQuick
import ".."

Rectangle {
    id: pill
    required property var theme
    property string label: ""
    property string iconName: "settings"
    property var options: []
    property int value: 0
    property int previewValue: bounded(value)
    readonly property int maximum: Math.max(0, options.length - 1)
    readonly property real position: maximum > 0 ? previewValue / maximum : 0
    readonly property bool hovered: pointer.containsMouse
    signal changed(int value)

    implicitHeight: 52
    activeFocusOnTab: true
    radius: Design.radiusSm
    color: theme.colors.surfaceVariant

    function bounded(next) {
        return Math.round(Design.clamp(next, 0, maximum))
    }

    function setFromPosition(next) {
        previewValue = bounded(next / Math.max(1, width) * maximum)
    }

    function commit() {
        const next = bounded(previewValue)
        previewValue = next
        if (next !== value) changed(next)
    }

    onValueChanged: if (!pointer.pressed) previewValue = bounded(value)

    RoundedSurfaceSlice {
        width: pill.width * pill.position
        height: parent.height
        surfaceWidth: pill.width
        cornerRadius: pill.radius
        color: pill.theme.colors.accentDim

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
            anchors.verticalCenter: parent.verticalCenter
            width: 32
            height: 32

            StatusIcon {
                anchors.centerIn: parent
                name: pill.iconName
                iconSize: Design.iconSm
                color: pill.theme.colors.foreground
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 40

            Text {
                width: parent.width
                text: pill.label
                color: pill.theme.colors.foreground
                elide: Text.ElideRight
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeXs
                font.weight: Design.fontWeightMedium
            }

            Text {
                width: parent.width
                text: pill.options[pill.previewValue] || ""
                color: pill.theme.colors.foreground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeSm
                font.weight: Design.fontWeightSemibold
            }
        }
    }

    Item {
        id: markers
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: 4
            rightMargin: 4
            bottomMargin: 6
        }
        height: 4

        Repeater {
            model: pill.options.length

            Rectangle {
                required property int index
                x: pill.maximum > 0 ? index * (markers.width - width) / pill.maximum : 0
                width: index === pill.previewValue ? 5 : 3
                height: width
                radius: width / 2
                color: pill.theme.colors.foreground
                opacity: index === pill.previewValue ? .82 : .28

                Behavior on width { NumberAnimation { duration: Design.animationFast; easing.type: Design.easingMorph } }
                Behavior on opacity { NumberAnimation { duration: Design.animationFast } }
            }
        }
    }

    Rectangle {
        visible: pill.hovered || pointer.pressed || pill.activeFocus
        x: Math.max(4, Math.min(parent.width - width - 4, parent.width * pill.position - width / 2))
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
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Left) {
            previewValue = bounded(previewValue - 1)
            commit()
            event.accepted = true
        } else if (event.key === Qt.Key_Right) {
            previewValue = bounded(previewValue + 1)
            commit()
            event.accepted = true
        } else if (event.key === Qt.Key_Home) {
            previewValue = 0
            commit()
            event.accepted = true
        } else if (event.key === Qt.Key_End) {
            previewValue = maximum
            commit()
            event.accepted = true
        }
    }

    MouseArea {
        id: pointer
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            leftMargin: 52
            rightMargin: 12
        }
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
        onReleased: mouse => {
            pill.setFromPosition(mouse.x + x)
            pill.commit()
        }
        onCanceled: pill.previewValue = pill.bounded(pill.value)
    }
}
