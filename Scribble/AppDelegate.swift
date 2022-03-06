import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    private func application(application: UIApplication, didFinishLaunchingWithOptions _: [NSObject: AnyObject]?) -> Bool {
        application.applicationSupportsShakeToEdit = true
        return true
    }
}
