import QtQuick
import ".."

Item {
    id: root
    property url source
    property int fillMode: Image.PreserveAspectCrop
    property bool asynchronous: true
    property bool cache: true
    property real radius: Design.radiusSm
    readonly property int status: image.status

    Image {
        id: image
        source: root.source
        asynchronous: root.asynchronous
        cache: root.cache
        visible: false
        onStatusChanged: {
            if (status === Image.Ready && root.source !== "") canvas.loadImage(root.source)
            canvas.requestPaint()
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        renderTarget: Canvas.Image
        onImageLoaded: requestPaint()
        onPaint: {
            var context = getContext("2d")
            context.reset()
            context.clearRect(0, 0, width, height)
            if (image.status !== Image.Ready || root.source === "" || !canvas.isImageLoaded(root.source)) return
            var imageWidth = image.sourceSize.width
            var imageHeight = image.sourceSize.height
            if (imageWidth <= 0 || imageHeight <= 0 || width <= 0 || height <= 0) return
            var scale = root.fillMode === Image.PreserveAspectCrop ? Math.max(width / imageWidth, height / imageHeight) : Math.min(width / imageWidth, height / imageHeight)
            var sourceWidth = width / scale
            var sourceHeight = height / scale
            var sourceX = (imageWidth - sourceWidth) / 2
            var sourceY = (imageHeight - sourceHeight) / 2
            var rounded = Math.min(root.radius, width / 2, height / 2)
            context.beginPath()
            context.moveTo(rounded, 0)
            context.lineTo(width - rounded, 0)
            context.quadraticCurveTo(width, 0, width, rounded)
            context.lineTo(width, height - rounded)
            context.quadraticCurveTo(width, height, width - rounded, height)
            context.lineTo(rounded, height)
            context.quadraticCurveTo(0, height, 0, height - rounded)
            context.lineTo(0, rounded)
            context.quadraticCurveTo(0, 0, rounded, 0)
            context.closePath()
            context.clip()
            context.drawImage(root.source, sourceX, sourceY, sourceWidth, sourceHeight, 0, 0, width, height)
        }

        Connections {
            target: root
            function onSourceChanged() {
                if (root.source !== "") canvas.loadImage(root.source)
                canvas.requestPaint()
            }
            function onRadiusChanged() { canvas.requestPaint() }
            function onWidthChanged() { canvas.requestPaint() }
            function onHeightChanged() { canvas.requestPaint() }
        }
    }
}
