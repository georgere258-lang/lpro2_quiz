import UIKit
import Flutter
import UserNotifications

@main // التغيير من @UIApplicationMain لضمان التوافق مع Xcode الحديث
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // 🟢 طباعة سجل للتأكد من وصول التنفيذ لهذه النقطة في Codemagic logs
    print("🟢 [AppDelegate] Application Launching...")

    // ربط UNUserNotificationCenter للإشعارات
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    // تسجيل الإضافات (Plugins)
    GeneratedPluginRegistrant.register(with: self)

    // نستخدم القيمة الراجعة من super لضمان اكتمال دورة حياة التطبيق بشكل صحيح
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    
    print("🟢 [AppDelegate] Launch Finished with result: \(result)")
    
    return result
  }
}