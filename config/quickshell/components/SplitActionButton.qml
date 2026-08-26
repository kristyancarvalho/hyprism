import QtQuick
import ".."

Rectangle {
    id: button
    required property var theme
    property string label: ""
    property string iconName: "settings"
    property bool active: false
    property bool available: true
    property bool toggleAvailable: true
    property bool pending: false
    readonly property bool controlFocused: activeFocus || detailArea.activeFocus
    readonly property color detailColor: Design.desaturate(color, .4)
    signal primaryClicked()
    signal detailClicked()
    signal focusEntered()

    activeFocusOnTab: available && toggleAvailable
    radius: Design.radiusSm
    color: active && available ? theme.colors.accentDim : primaryPointer.containsMouse ? theme.colors.surfaceHover : theme.colors.surfaceVariant
    opacity: available ? pending ? .72 : 1 : .5
    implicitWidth: 170
    implicitHeight: 68

    function takeFocus() {
        if (toggleAvailable) forceActiveFocus(Qt.TabFocusReason)
        else detailArea.forceActiveFocus(Qt.TabFocusReason)
    }

    onActiveFocusChanged: if (activeFocus) focusEntered()

    Row {
        anchors {
            left: parent.left
            right: detailArea.left
            top: parent.top
            bottom: parent.bottom
            margins: Design.spacingMd
        }
        spacing: Design.spacingSm

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 36
            height: 36
            radius: Design.radiusDefault
            color: button.active ? button.theme.colors.accentDim : button.theme.colors.surface

            StatusIcon {
                anchors.centerIn: parent
                name: button.pending ? "refresh" : button.iconName
                iconSize: Design.iconMd
                color: button.theme.colors.foreground
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 46
            text: Design.safeText(button.label, I18n.tr("common.unavailable"))
            color: button.available ? button.theme.colors.foreground : button.theme.colors.mutedForeground
            elide: Text.ElideRight
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            font.family: Design.fontFamily
            font.pixelSize: Design.fontSizeSm
            font.weight: Design.fontWeightMedium
        }
    }

    Item {
        id: detailArea
        anchors.right: parent.right
        width: 42
        height: parent.height
        activeFocusOnTab: button.available
        clip: true

        RoundedSurfaceSlice {
            anchors.fill: parent
            surfaceWidth: button.width
            cornerRadius: button.radius
            rightAligned: true
            color: detailPointer.containsMouse || detailArea.activeFocus ? Qt.lighter(button.detailColor, 1.08) : button.detailColor
        }

        Rectangle {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            width: 2
            height: parent.height - Design.spacingLg
            color: button.theme.colors.borderSubtle
            opacity: .82
        }

        StatusIcon {
            anchors.centerIn: parent
            name: "chevronRight"
            iconSize: Design.iconSm
            color: button.theme.colors.foreground
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Left && button.toggleAvailable) {
                button.forceActiveFocus(Qt.BacktabFocusReason)
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space || event.key === Qt.Key_Right) {
                button.detailClicked()
                event.accepted = true
            }
        }

        onActiveFocusChanged: if (activeFocus) button.focusEntered()

        MouseArea {
            id: detailPointer
            anchors.fill: parent
            enabled: button.available && !button.pending
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.detailClicked()
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Right) {
            detailArea.forceActiveFocus(Qt.TabFocusReason)
            event.accepted = true
        } else if (button.toggleAvailable && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)) {
            button.primaryClicked()
            event.accepted = true
        }
    }

    MouseArea {
        id: primaryPointer
        anchors {
            left: parent.left
            right: detailArea.left
            top: parent.top
            bottom: parent.bottom
        }
        enabled: button.available && button.toggleAvailable && !button.pending
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            button.forceActiveFocus(Qt.MouseFocusReason)
            button.primaryClicked()
        }
    }

    Behavior on color { ColorAnimation { duration: Design.animationFast; easing.type: Design.easingMorph } }
}
