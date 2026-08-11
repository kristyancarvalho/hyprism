import QtQuick
import ".."

Rectangle {
    property var theme
    implicitWidth: Design.separatorWidth
    implicitHeight: Design.separatorHeight
    radius: width / 2
    color: theme ? theme.colors.outline : "#426172"
}
