import QtQuick
import QtQuick.VirtualKeyboard
import QtQuick.VirtualKeyboard.Styles
import HyprismPixie

KeyboardStyle {
    id: currentStyle

    readonly property var pal: KeyboardPalette
    readonly property real keyInset: 7 * scaleHint
    readonly property real keyRadius: 22 * scaleHint

    function glyph(codePoint) {
        return String.fromCodePoint(codePoint)
    }

    keyboardDesignWidth: 2560
    keyboardDesignHeight: 800
    keyboardRelativeLeftMargin: 22 / keyboardDesignWidth
    keyboardRelativeRightMargin: 22 / keyboardDesignWidth
    keyboardRelativeTopMargin: 22 / keyboardDesignHeight
    keyboardRelativeBottomMargin: 22 / keyboardDesignHeight

    keyboardBackground: Rectangle {
        radius: 40 * currentStyle.scaleHint
        color: Qt.rgba(currentStyle.pal.background.r, currentStyle.pal.background.g, currentStyle.pal.background.b, .94)
        border.width: 1
        border.color: currentStyle.pal.surfaceVariant
    }

    component KeySurface: Rectangle {
        id: surface
        property BaseKey control
        property color idleColor: currentStyle.pal.surface
        property color activeColor: currentStyle.pal.accent
        anchors.fill: parent
        anchors.margins: currentStyle.keyInset
        radius: currentStyle.keyRadius
        color: control && control.pressed ? activeColor : idleColor
        Behavior on color { ColorAnimation { duration: 80 } }
    }

    component KeyLabel: Text {
        property BaseKey control
        property bool onAccent: !!(control && control.pressed)
        anchors.centerIn: parent
        color: onAccent ? currentStyle.pal.accentForeground : currentStyle.pal.text
        font.family: currentStyle.pal.fontFamily
        font.pixelSize: 78 * currentStyle.scaleHint
        font.weight: Font.Medium
    }

    component KeyGlyph: Text {
        property BaseKey control
        property int codePoint: 0
        property bool onAccent: !!(control && control.pressed)
        anchors.centerIn: parent
        text: currentStyle.glyph(codePoint)
        color: onAccent ? currentStyle.pal.accentForeground : currentStyle.pal.text
        font.family: currentStyle.pal.iconFamily
        font.pixelSize: 86 * currentStyle.scaleHint
    }

    keyPanel: KeyPanel {
        KeySurface { control: parent.control }
        KeyLabel {
            control: parent.control
            text: parent.control.uppercased ? parent.control.displayText.toUpperCase() : parent.control.displayText
        }
        Text {
            visible: parent.control.smallTextVisible
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16 * currentStyle.scaleHint
            text: parent.control.smallText
            color: currentStyle.pal.muted
            font.family: currentStyle.pal.fontFamily
            font.pixelSize: 40 * currentStyle.scaleHint
        }
    }

    backspaceKeyPanel: KeyPanel {
        KeySurface { control: parent.control; idleColor: currentStyle.pal.surfaceVariant }
        KeyGlyph { control: parent.control; codePoint: 0xF006E }
    }

    languageKeyPanel: KeyPanel {
        KeySurface { control: parent.control; idleColor: currentStyle.pal.surfaceVariant }
        KeyGlyph { control: parent.control; codePoint: 0xF01E7 }
    }

    enterKeyPanel: KeyPanel {
        KeySurface { control: parent.control; idleColor: currentStyle.pal.accent; activeColor: Qt.darker(currentStyle.pal.accent, 1.2) }
        KeyGlyph { control: parent.control; codePoint: 0xF0311; color: currentStyle.pal.accentForeground }
    }

    hideKeyPanel: KeyPanel {
        KeySurface { control: parent.control; idleColor: currentStyle.pal.surfaceVariant }
        KeyGlyph { control: parent.control; codePoint: 0xF030F }
    }

    shiftKeyPanel: KeyPanel {
        id: shiftPanel
        KeySurface {
            control: shiftPanel.control
            idleColor: InputContext.uppercase ? currentStyle.pal.accent : currentStyle.pal.surfaceVariant
        }
        KeyGlyph {
            control: shiftPanel.control
            codePoint: InputContext.capsLockActive ? 0xF0737 : 0xF0636
            color: InputContext.uppercase || shiftPanel.control.pressed ? currentStyle.pal.accentForeground : currentStyle.pal.text
        }
    }

    spaceKeyPanel: KeyPanel {
        id: spacePanel
        KeySurface { control: spacePanel.control }
        Text {
            anchors.centerIn: parent
            text: spacePanel.control.displayText
            color: currentStyle.pal.muted
            font.family: currentStyle.pal.fontFamily
            font.pixelSize: 44 * currentStyle.scaleHint
        }
    }

    symbolKeyPanel: KeyPanel {
        id: symbolPanel
        KeySurface { control: symbolPanel.control; idleColor: currentStyle.pal.surfaceVariant }
        KeyLabel {
            control: symbolPanel.control
            text: symbolPanel.control.displayText
            font.pixelSize: 62 * currentStyle.scaleHint
        }
    }

    modeKeyPanel: KeyPanel {
        id: modePanel
        KeySurface {
            control: modePanel.control
            idleColor: modePanel.control.mode ? currentStyle.pal.accent : currentStyle.pal.surfaceVariant
        }
        KeyLabel {
            control: modePanel.control
            text: modePanel.control.displayText
            color: modePanel.control.mode || modePanel.control.pressed ? currentStyle.pal.accentForeground : currentStyle.pal.text
            font.pixelSize: 62 * currentStyle.scaleHint
        }
    }

    handwritingKeyPanel: KeyPanel {
        id: handwritingPanel
        KeySurface { control: handwritingPanel.control; idleColor: currentStyle.pal.surfaceVariant }
        KeyGlyph { control: handwritingPanel.control; codePoint: 0xF030C }
    }

    characterPreviewMargin: 0
    characterPreviewDelegate: Item {
        id: preview
        property string text
        Rectangle {
            anchors.fill: parent
            radius: currentStyle.keyRadius
            color: currentStyle.pal.surfaceVariant
            border.width: 2
            border.color: currentStyle.pal.accent
            Text {
                anchors.centerIn: parent
                text: preview.text
                color: currentStyle.pal.text
                font.family: currentStyle.pal.fontFamily
                font.pixelSize: 90 * currentStyle.scaleHint
            }
        }
    }

    alternateKeysListItemWidth: 99 * scaleHint * 1.3
    alternateKeysListItemHeight: 150 * scaleHint
    alternateKeysListTopMargin: 10 * scaleHint
    alternateKeysListBottomMargin: 10 * scaleHint
    alternateKeysListLeftMargin: 10 * scaleHint
    alternateKeysListRightMargin: 10 * scaleHint
    alternateKeysListDelegate: Item {
        id: alternate
        width: currentStyle.alternateKeysListItemWidth
        height: currentStyle.alternateKeysListItemHeight
        Text {
            anchors.centerIn: parent
            text: model.text
            color: alternate.ListView.isCurrentItem ? currentStyle.pal.accentForeground : currentStyle.pal.text
            font.family: currentStyle.pal.fontFamily
            font.pixelSize: 70 * currentStyle.scaleHint
        }
    }
    alternateKeysListHighlight: Rectangle {
        radius: currentStyle.keyRadius
        color: currentStyle.pal.accent
    }
    alternateKeysListBackground: Rectangle {
        radius: currentStyle.keyRadius + 6 * currentStyle.scaleHint
        color: currentStyle.pal.surface
        border.width: 1
        border.color: currentStyle.pal.surfaceVariant
    }

    selectionListHeight: 110 * scaleHint
    selectionListDelegate: SelectionListItem {
        id: selectionItem
        width: Math.max(160 * currentStyle.scaleHint, label.implicitWidth + 60 * currentStyle.scaleHint)
        Text {
            id: label
            anchors.centerIn: parent
            text: decorateText(display, wordCompletionLength)
            color: currentStyle.pal.text
            font.family: currentStyle.pal.fontFamily
            font.pixelSize: 56 * currentStyle.scaleHint
        }
    }
    selectionListHighlight: Rectangle {
        radius: currentStyle.keyRadius
        color: currentStyle.pal.surfaceVariant
    }
    selectionListBackground: Item {}
    selectionListAdd: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150 } }
    selectionListRemove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 150 } }

    navigationHighlight: Rectangle {
        color: "transparent"
        radius: currentStyle.keyRadius
        border.width: 4 * currentStyle.scaleHint
        border.color: currentStyle.pal.accent
    }

    popupListDelegate: SelectionListItem {
        property real cursorAnchor: popupLabel.x + popupLabel.width
        Text {
            id: popupLabel
            anchors.centerIn: parent
            text: decorateText(display, wordCompletionLength)
            color: currentStyle.pal.text
            font.family: currentStyle.pal.fontFamily
            font.pixelSize: 56 * currentStyle.scaleHint
        }
    }
    popupListBackground: Rectangle {
        radius: currentStyle.keyRadius
        color: currentStyle.pal.surface
        border.width: 1
        border.color: currentStyle.pal.surfaceVariant
    }
    popupListHighlight: Rectangle {
        radius: currentStyle.keyRadius
        color: currentStyle.pal.surfaceVariant
    }
}
