import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: root
    property string name: "application-x-executable"
    property string fallback: "application-x-executable"
    property real iconSize: 20
    property bool framed: false
    property color frameColor: "transparent"
    implicitWidth: iconSize + (framed ? 12 : 0)
    implicitHeight: iconSize + (framed ? 12 : 0)

    Rectangle {
        anchors.fill: parent
        visible: root.framed
        radius: width / 2
        color: root.frameColor
    }

    IconImage {
        anchors.centerIn: parent
        width: root.iconSize
        height: root.iconSize
        implicitSize: root.iconSize
        mipmap: true
        source: root.name.startsWith("/") ? "file://" + root.name : Quickshell.iconPath(root.name, root.fallback)
    }
}
