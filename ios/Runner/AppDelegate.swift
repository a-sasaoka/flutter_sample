import Flutter
import GoogleMaps
import UIKit
import UserNotifications
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      // 🔔 親クラス(FlutterAppDelegate)が持つ通知窓口プロトコルとして安全にデリゲート登録
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsApiKey") as? String, !apiKey.isEmpty {
      GMSServices.provideAPIKey(apiKey)
    }

    // 🔔 アプリ起動時にアプリアイコンのバッジをリセット
    resetBadge()

    // 🔔 Sceneの有無に関わらず、アプリがアクティブになった通知を確実に検知してバッジをリセット
    NotificationCenter.default.addObserver(
      forName: UIApplication.didBecomeActiveNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.resetBadge()
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // 🔔 アプリ起動中（フォアグラウンド）に通知を受信した際、親クラス(Flutter/Firebase)に通知を転送しつつ、
  // リモート通知・ローカル通知ともにバナー・サウンド・バッジを確実に表示するようiOSに許可を返す
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let lock = NSLock()
    var isHandled = false

    // 1. プラグインからの完了コールバックをスレッドセーフに受けるハンドラ
    let safeCompletionHandler: (UNNotificationPresentationOptions) -> Void = { _ in
      lock.lock()
      defer { lock.unlock() }
      guard !isHandled else { return }
      isHandled = true

      // 🔔 フォアグラウンド受信時、リモート通知(APNs)・ローカル通知ともにバナー等の表示を許可
      if #available(iOS 14.0, *) {
        completionHandler([.banner, .list, .sound, .badge])
      } else {
        completionHandler([.alert, .sound, .badge])
      }
    }

    // 2. 親クラス(FlutterAppDelegate)に委譲し、Firebase等のプラグインに通知イベントを届ける
    super.userNotificationCenter(center, willPresent: notification, withCompletionHandler: safeCompletionHandler)

    // 3. 万が一プラグイン側で completionHandler が呼ばれなかった場合の保険（0.5秒後のフォールバック）
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      lock.lock()
      defer { lock.unlock() }
      guard !isHandled else { return }
      isHandled = true

      if #available(iOS 14.0, *) {
        completionHandler([.banner, .list, .sound, .badge])
      } else {
        completionHandler([.alert, .sound, .badge])
      }
    }
  }

  private func resetBadge() {
    if #available(iOS 17.0, *) {
      UNUserNotificationCenter.current().setBadgeCount(0)
    } else {
      UIApplication.shared.applicationIconBadgeNumber = 0
    }
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
  }
}
