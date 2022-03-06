import UIKit

class ViewController: UIViewController {
    @IBOutlet var canvasView: CanvasView!

    override func viewDidLoad() {
        super.viewDidLoad()
        canvasView.clearCanvas(animated: false)
    }

    // Shake to clear screen
    override func motionEnded(_: UIEvent.EventSubtype, with _: UIEvent?) {
        canvasView.clearCanvas(animated: true)
    }
}
