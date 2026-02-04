import UIKit
import Flutter
import Firebase
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // 1️⃣ Firebase لازم يشتغل قبل تسجيل أي Plugin
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

    // 2️⃣ مهم جدًا: ربط UNUserNotificationCenter
    // بدونها iOS أحيانًا يعلّق بعد شاشة إذن الإشعارات
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    // 3️⃣ تسجيل Plugins
    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}