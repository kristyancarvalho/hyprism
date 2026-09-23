import QtQuick
import ".."

Rectangle {
    id: choice
    required property var theme
    property string label: ""
    property string iconName: "settings"
    property var options: []
    property int value: 0
    property bool selectionReady: false
    signal changed(int value)

    implicitHeight: 76
    activeFocusOnTab: true
    radius: Design.radiusSm
    color: theme.colors.surfaceVariant
    Component.onCompleted: Qt.callLater(() => choice.selectionReady = true)

    Keys.onPressed: event => {
        let next = value
        if (event.key === Qt.Key_Left) next = Math.max(0, value - 1)
        else if (event.key === Qt.Key_Right) next = Math.min(options.length - 1, value + 1)
        else if (event.key === Qt.Key_Home) next = 0
        else if (event.key === Qt.Key_End) next = options.length - 1
        else return
        if (next !== value) changed(next)
        event.accepted = true
    }

    StatusIcon {
        anchors {
            left: parent.left
            leftMargin: Design.spacingMd
            top: parent.top
            topMargin: Design.spacingSm
        }
        name: choice.iconName
        iconSize: Design.iconSm
        color: choice.theme.colors.foreground
    }

    Text {
        anchors {
            left: parent.left
            leftMargin: 40
            top: parent.top
            topMargin: Design.spacingSm
        }
        text: choice.label
        color: choice.theme.colors.foreground
        font.family: Design.fontFamily
        font.pixelSize: Design.fontSizeSm
        font.weight: Design.fontWeightMedium
    }

    Rectangle {
        id: group
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: Design.spacingSm
        }
        height: 34
        radius: Design.radiusSmall
        color: choice.theme.colors.surfaceElevated
        clip: true
        border.width: choice.activeFocus ? 1 : 0
        border.color: choice.theme.colors.outline

        Item {
            id: segmentsArea
            anchors.fill: parent
            anchors.margins: Design.spacingXs

            Rectangle {
                id: selection
                x: width * choice.value
                width: segmentsArea.width / Math.max(1, choice.options.length)
                height: segmentsArea.height
                radius: Design.radiusXs
                color: choice.theme.colors.accentDim
                z: 0

                Behavior on x {
                    enabled: choice.selectionReady
                    NumberAnimation { duration: Design.animationMorph; easing.type: Design.easingMove }
                }
                Behavior on width {
                    enabled: choice.selectionReady
                    NumberAnimation { duration: Design.animationFast; easing.type: Design.easingMorph }
                }
            }

            Row {
                anchors.fill: parent

                Repeater {
                    id: segments
                    model: choice.options.length

                    Item {
                        id: segment
                        required property int index
                        width: segmentsArea.width / choice.options.length
                        height: segmentsArea.height

                        Rectangle {
                            anchors.fill: parent
                            radius: Design.radiusXs
                            color: choice.theme.colors.foreground
                            opacity: pointer.pressed ? .09 : pointer.containsMouse ? .045 : 0
                            Behavior on opacity { NumberAnimation { duration: Design.animationFast; easing.type: Design.easingMorph } }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: choice.options[segment.index]
                            color: choice.theme.colors.foreground
                            font.family: Design.fontFamily
                            font.pixelSize: Design.fontSizeSm
                            font.weight: segment.index === choice.value ? Design.fontWeightSemibold : Design.fontWeightMedium
                        }

                        MouseArea {
                            id: pointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                choice.forceActiveFocus(Qt.MouseFocusReason)
                                if (segment.index !== choice.value) choice.changed(segment.index)
                            }
                        }
                    }
                }
            }
        }
    }
}
