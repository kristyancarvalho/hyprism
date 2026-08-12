import QtQuick
import ".."

Item {
    property var theme
    implicitWidth: Design.compactSeparatorWidth
    implicitHeight: Design.compactItemHeight

    Rectangle {
        anchors.centerIn: parent
        width: Design.compactSeparatorWidth
        height: Design.compactSeparatorHeight
        radius: 0
        color: parent.theme ? parent.theme.colors.outline : "transparent"
    }
}
