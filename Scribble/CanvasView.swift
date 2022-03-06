import UIKit

class CanvasView: UIImageView {
    // Parameters
    private let defaultLineWidth: CGFloat = 6
    private let forceSensitivity: CGFloat = 4.0
    private let tiltThreshold = CGFloat.pi / 6 // 30º
    private let minLineWidth: CGFloat = 5

    private var drawingImage: UIImage?

    private var drawColor = UIColor.red
    private var pencilTexture = UIColor(patternImage: UIImage(named: "PencilTexture")!)

    private var eraserColor: UIColor {
        return backgroundColor ?? UIColor.white
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()

        // Draw previous image into context
        drawingImage?.draw(in: bounds)

        // 1
        var touches = [UITouch]()

        // Coalesce Touches
        // 2
        if let coalescedTouches = event?.coalescedTouches(for: touch) {
            touches = coalescedTouches
        } else {
            touches.append(touch)
        }

        // 4
        for touch in touches {
            drawStroke(context: context, touch: touch)
        }

        // 1
        drawingImage = UIGraphicsGetImageFromCurrentImageContext()
        // 2
        if let predictedTouches = event?.predictedTouches(for: touch) {
            for touch in predictedTouches {
                drawStroke(context: context, touch: touch)
            }
        }

        // Update image
        image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }

    override func touchesEnded(_: Set<UITouch>, with _: UIEvent?) {
        image = drawingImage
    }

    override func touchesCancelled(_: Set<UITouch>?, with _: UIEvent?) {
        image = drawingImage
    }

    private func drawStroke(context: CGContext?, touch: UITouch) {
        let previousLocation = touch.previousLocation(in: self)
        let location = touch.location(in: self)

        var lineWidth: CGFloat
        if touch.type == .pencil {
            // Calculate line width for drawing stroke
            if touch.altitudeAngle < tiltThreshold {
                lineWidth = lineWidthForShading(context: context, touch: touch)
            } else {
                lineWidth = lineWidthForDrawing(context: context, touch: touch)
            }
            // Set color
            pencilTexture.setStroke()
        } else {
            // Erase with finger
            lineWidth = touch.majorRadius / 2
            eraserColor.setStroke()
        }

        // Configure line
        context!.setLineWidth(lineWidth)
        context!.setLineCap(.round)

        // Set up the points
        context?.move(to: .init(x: previousLocation.x, y: previousLocation.y))
        context!.addLine(to: .init(x: location.x, y: location.y))

        // Draw the stroke
        context!.strokePath()
    }

    private func lineWidthForShading(context: CGContext?, touch: UITouch) -> CGFloat {
        // 1
        let previousLocation = touch.previousLocation(in: self)
        let location = touch.location(in: self)

        // 2 - vector1 is the pencil direction
        let vector1 = touch.azimuthUnitVector(in: self)

        // 3 - vector2 is the stroke direction
        let vector2 = CGPoint(x: location.x - previousLocation.x, y: location.y - previousLocation.y)

        // 4 - Angle difference between the two vectors
        var angle = abs(atan2(vector2.y, vector2.x) - atan2(vector1.dy, vector1.dx))

        // 5
        if angle > CGFloat.pi {
            angle = 2 * CGFloat.pi - angle
        }
        if angle > CGFloat.pi / 2 {
            angle = CGFloat.pi - angle
        }

        // 6
        let minAngle: CGFloat = 0
        let maxAngle = CGFloat.pi / 2
        let normalizedAngle = (angle - minAngle) / (maxAngle - minAngle)

        // 7
        let maxLineWidth: CGFloat = 60
        var lineWidth = maxLineWidth * normalizedAngle

        // 1 - modify lineWidth by altitude (tilt of the Pencil)
        // 0.25 radians means widest stroke and TiltThreshold is where shading narrows to line.

        let minAltitudeAngle: CGFloat = 0.25
        let maxAltitudeAngle = tiltThreshold

        // 2
        let altitudeAngle = touch.altitudeAngle < minAltitudeAngle
            ? minAltitudeAngle : touch.altitudeAngle

        // 3 - normalize between 0 and 1
        let normalizedAltitude = 1 - ((altitudeAngle - minAltitudeAngle)
            / (maxAltitudeAngle - minAltitudeAngle))
        // 4
        lineWidth = lineWidth * normalizedAltitude + minLineWidth

        // Set alpha of shading using force
        let minForce: CGFloat = 0.0
        let maxForce: CGFloat = 5

        // Normalize between 0 and 1
        let normalizedAlpha = (touch.force - minForce) / (maxForce - minForce)

        context!.setAlpha(normalizedAlpha)

        return lineWidth
    }

    private func lineWidthForDrawing(context _: CGContext?, touch: UITouch) -> CGFloat {
        var lineWidth = defaultLineWidth

        if touch.force > 0 { // If finger, touch.force = 0
            lineWidth = touch.force * forceSensitivity
        }

        return lineWidth
    }

    func clearCanvas(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.5, animations: {
                self.alpha = 0
            }, completion: { _ in
                self.alpha = 1
                self.image = nil
                self.drawingImage = nil
            })
        } else {
            self.image = nil
            self.drawingImage = nil
        }
    }
}
