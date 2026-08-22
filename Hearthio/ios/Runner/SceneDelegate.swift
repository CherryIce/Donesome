import Flutter
import UIKit

@objc class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    prepareLaunchSurface()
  }

  private func prepareLaunchSurface() {
    let launchBackground = UIColor(named: "LaunchBackground") ?? .systemGroupedBackground
    window?.backgroundColor = launchBackground

    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    if controller.splashScreenView == nil {
      let launchController = UIStoryboard(name: "LaunchScreen", bundle: nil)
        .instantiateInitialViewController()
      controller.splashScreenView = launchController?.view
    }
    controller.viewIfLoaded?.backgroundColor = launchBackground
  }
}
