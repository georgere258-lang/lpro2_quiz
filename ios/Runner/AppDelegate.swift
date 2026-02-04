import UIKit
import Flutter
import Firebase // إضافة مكتبة Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // 1. تشغيل Firebase قبل أي شيء آخر لضمان استقرار المكتبات
    if FirebaseApp.app() == nil {
        FirebaseApp.configure()
    }

    // 2. تسجيل الـ Plugins (بما فيها Firebase Cloud Messaging)
    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}