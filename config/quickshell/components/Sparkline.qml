import QtQuick
import ".."

Canvas {
    id: graph
    property var samples: []
    property color lineColor: "white"
    property color fillColor: Qt.rgba(lineColor.r, lineColor.g, lineColor.b, .13)
    property real maximum: 100
    antialiasing: true

    onSamplesChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const context = getContext("2d")
        context.reset()
        const values = Array.isArray(samples) ? samples : []
        if (values.length < 2 || width <= 1 || height <= 1) return
        const step = width / Math.max(1, values.length - 1)
        context.beginPath()
        for (let i = 0; i < values.length; i++) {
            const x = i * step
            const y = height - Design.clamp(values[i], 0, maximum) / maximum * (height - 2) - 1
            if (i === 0) context.moveTo(x, y)
            else context.lineTo(x, y)
        }
        context.lineTo(width, height)
        context.lineTo(0, height)
        context.closePath()
        context.fillStyle = fillColor
        context.fill()
        context.beginPath()
        for (let j = 0; j < values.length; j++) {
            const px = j * step
            const py = height - Design.clamp(values[j], 0, maximum) / maximum * (height - 2) - 1
            if (j === 0) context.moveTo(px, py)
            else context.lineTo(px, py)
        }
        context.strokeStyle = lineColor
        context.lineWidth = 1.5
        context.lineJoin = "round"
        context.lineCap = "round"
        context.stroke()
    }
}
