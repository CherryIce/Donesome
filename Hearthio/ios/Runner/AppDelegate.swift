import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterPluginRegistrant {
  private var systemPermissionService: SystemPermissionService?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    pluginRegistrant = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func register(with registry: FlutterPluginRegistry) {
    GeneratedPluginRegistrant.register(with: registry)
    if let registrar = registry.registrar(
      forPlugin: "HearthioSystemPermissionService"
    ) {
      systemPermissionService = SystemPermissionService(
        messenger: registrar.messenger()
      )
    }
  }
}

private final class SystemPermissionService {
  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(
      name: "hearthio/system_permissions",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "openSettings" {
      guard let url = URL(string: UIApplication.openSettingsURLString) else {
        result(false)
        return
      }
      UIApplication.shared.open(url, options: [:]) { opened in
        result(opened)
      }
      return
    }

    guard
      let arguments = call.arguments as? [String: Any],
      let permission = arguments["permission"] as? String
    else {
      result("unavailable")
      return
    }

    switch call.method {
    case "check":
      result(status(for: permission))
    case "request":
      request(permission, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func status(for permission: String) -> String {
    switch permission {
    case "camera":
      switch AVCaptureDevice.authorizationStatus(for: .video) {
      case .notDetermined: return "notDetermined"
      case .authorized: return "granted"
      case .denied: return "denied"
      case .restricted: return "restricted"
      @unknown default: return "unavailable"
      }
    default:
      return "unavailable"
    }
  }

  private func request(_ permission: String, result: @escaping FlutterResult) {
    switch permission {
    case "camera":
      AVCaptureDevice.requestAccess(for: .video) { [weak self] _ in
        DispatchQueue.main.async {
          result(self?.status(for: permission) ?? "unavailable")
        }
      }
    default:
      result("unavailable")
    }
  }
}
