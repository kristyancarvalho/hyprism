import QtQuick
import ".."

Item {
    id: highlight
    required property var theme
    property Item target: null
    property bool active: true
    property int inset: 0
    property real strength: 1
    property real cornerRadius: Design.radiusSm
    property color highlightColor: theme.colors.surfaceActive
    property bool geometryReady: false
    property bool animateGeometry: false

    function updateGeometry(animated) {
        if (!target || !parent) {
            geometryReady = false
            return
        }
        const position = target.mapToItem(parent, 0, 0)
        animateGeometry = animated && geometryReady && active
        x = position.x + inset
        y = position.y + inset
        width = Math.max(0, target.width - inset * 2)
        height = Math.max(0, target.height - inset * 2)
        geometryReady = true
        if (!animateGeometry) Qt.callLater(() => highlight.animateGeometry = highlight.geometryReady && highlight.active)
    }

    opacity: active && target && geometryReady ? strength : 0
    z: 1

    Rectangle {
        anchors.fill: parent
        radius: highlight.cornerRadius
        color: highlight.highlightColor
    }

    Behavior on x { enabled: highlight.animateGeometry; NumberAnimation { duration: Design.animationMorph; easing.type: Design.easingMove } }
    Behavior on y { enabled: highlight.animateGeometry; NumberAnimation { duration: Design.animationMorph; easing.type: Design.easingMove } }
    Behavior on width { enabled: highlight.animateGeometry; NumberAnimation { duration: Design.animationFast; easing.type: Design.easingMorph } }
    Behavior on height { enabled: highlight.animateGeometry; NumberAnimation { duration: Design.animationFast; easing.type: Design.easingMorph } }
    Behavior on opacity { NumberAnimation { duration: Design.animationFast; easing.type: Design.easingMorph } }

    onTargetChanged: updateGeometry(true)
    onParentChanged: updateGeometry(false)
    onActiveChanged: {
        if (active) updateGeometry(false)
        else animateGeometry = false
    }

    Connections {
        target: highlight.target
        ignoreUnknownSignals: true
        function onXChanged() { highlight.updateGeometry(true) }
        function onYChanged() { highlight.updateGeometry(true) }
        function onWidthChanged() { highlight.updateGeometry(true) }
        function onHeightChanged() { highlight.updateGeometry(true) }
        function onVisibleChanged() { highlight.updateGeometry(false) }
    }

    Component.onCompleted: updateGeometry(false)
}
