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
    readonly property int visualIndex: previewValue
    readonly property real visualPosition: maximum > 0 ? previewValue / maximum : 0
    readonly property bool hovered: pointer.containsMouse
    signal changed(int value)

    implicitHeight: 76
    activeFocusOnTab: true
    radius: Design.radiusSm
    color: theme.colors.surfaceVariant

    function bounded(next) {
        return Math.round(Design.clamp(next, 0, maximum))
    }

    function valueFromPosition(next) {
        const position = Design.clamp(next, track.stopInset, track.width - track.stopInset)
        const visual = maximum > 0 ? Math.round((position - track.stopInset) / Math.max(1, track.stopRange) * maximum) : 0
        return bounded(visual)
    }

    function setFromPosition(next) {
        previewValue = valueFromPosition(next)
    }

    function commit() {
        const next = bounded(previewValue)
        previewValue = next
        if (next !== value) changed(next)
    }

    onValueChanged: if (!pointer.pressed) previewValue = bounded(value)

    Rectangle {
        anchors.fill: parent
        color: pill.theme.colors.surfaceHover
        opacity: pill.hovered || pointer.pressed ? .13 : 0

        Behavior on opacity { NumberAnimation { duration: Design.animationFast; easing.type: Design.easingMorph } }
    }

    StatusIcon {
        anchors {
            left: parent.left
            leftMargin: Design.spacingMd
            top: parent.top
            topMargin: Design.spacingSm
        }
        name: pill.iconName
        iconSize: Design.iconSm
        color: pill.theme.colors.foreground
    }

    Text {
        anchors {
            left: parent.left
            leftMargin: 40
            right: activeValue.left
            rightMargin: Design.spacingSm
            top: parent.top
            topMargin: Design.spacingSm
        }
        text: pill.label
        color: pill.theme.colors.foreground
        elide: Text.ElideRight
        font.family: Design.fontFamily
        font.pixelSize: Design.fontSizeSm
        font.weight: Design.fontWeightMedium
    }

    Text {
        id: activeValue
        anchors {
            right: parent.right
            rightMargin: Design.spacingMd
            top: parent.top
            topMargin: Design.spacingSm
        }
        text: pill.options[pill.previewValue] || ""
        color: pill.theme.colors.foreground
        font.family: Design.fontFamily
        font.pixelSize: Design.fontSizeSm
        font.weight: Design.fontWeightSemibold
    }

    Rectangle {
        id: track
        readonly property real stopInset: 5
        readonly property real stopRange: width - stopInset * 2
        readonly property real thumbCenter: stopInset + stopRange * pill.visualPosition

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: Design.spacingMd
            rightMargin: Design.spacingMd
            topMargin: 33
        }
        height: 14
        radius: height / 2
        color: pill.theme.colors.surfaceElevated
        clip: true

        RoundedSurfaceSlice {
            width: pill.previewValue === pill.maximum ? track.width : track.thumbCenter
            height: parent.height
            surfaceWidth: track.width
            cornerRadius: track.radius
            color: pill.theme.colors.accentDim

            Behavior on width {
                enabled: !pointer.pressed
                NumberAnimation { duration: Design.animationFast; easing.type: Design.easingMorph }
            }
        }

        Repeater {
            model: pill.maximum

            Rectangle {
                required property int index
                x: track.stopInset + track.stopRange * (index + .5) / pill.maximum - width / 2
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: parent.height - 4
                radius: .5
                color: pill.theme.colors.foreground
                opacity: .18
            }
        }

        Repeater {
            model: pill.options.length

            Rectangle {
                required property int index
                x: track.stopInset + track.stopRange * index / Math.max(1, pill.maximum) - width / 2
                anchors.verticalCenter: parent.verticalCenter
                width: 4
                height: width
                radius: width / 2
                color: pill.theme.colors.mutedForeground
                opacity: .58
            }
        }

        Rectangle {
            x: track.thumbCenter - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: pill.activeFocus ? 10 : 9
            height: width
            radius: width / 2
            color: pill.theme.colors.foreground
            opacity: .9

            Behavior on x {
                enabled: !pointer.pressed
                NumberAnimation { duration: Design.animationFast; easing.type: Design.easingMorph }
            }
            Behavior on width { NumberAnimation { duration: Design.animationFast; easing.type: Design.easingMorph } }
        }
    }

    Item {
        id: labels
        anchors {
            left: track.left
            right: track.right
            top: track.bottom
            topMargin: 4
        }
        height: 15

        Repeater {
            model: pill.options.length

            Text {
                required property int index
                readonly property real stopCenter: track.stopInset + track.stopRange * index / Math.max(1, pill.maximum)
                x: Math.max(0, Math.min(labels.width - width, stopCenter - width / 2))
                text: pill.options[index] || ""
                color: pill.theme.colors.mutedForeground
                font.family: Design.fontFamily
                font.pixelSize: Design.fontSizeXs
                font.weight: Design.fontWeightMedium
            }
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
            left: track.left
            right: track.right
            top: track.top
            bottom: parent.bottom
        }
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        onPressed: mouse => {
            pill.forceActiveFocus(Qt.MouseFocusReason)
            pill.setFromPosition(mouse.x)
        }
        onPositionChanged: mouse => {
            if (pressed) pill.setFromPosition(mouse.x)
        }
        onReleased: mouse => {
            pill.setFromPosition(mouse.x)
            pill.commit()
        }
        onCanceled: pill.previewValue = pill.bounded(pill.value)
    }
}
