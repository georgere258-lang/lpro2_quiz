import UIKit
import Flutter
import Firebase
import FirebaseMessaging  // ✅ ضروري لربط توكن الإشعارات بـ Firebase
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // 1️⃣ تهيئة فايربيز أولاً لضمان جاهزية الخدمات قبل الإضافات
    if FirebaseApp.app() == nil {
        FirebaseApp.configure()
    }
    
    // 2️⃣ ضبط مفوض الإشعارات (بدون casting معقد لتجنب الكراش)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    
    // 3️⃣ تسجيل إضافات فلوتر
    GeneratedPluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // 4️⃣ ✅ استلام توكن Apple وتمريره لـ Firebase (هذا يمنع كراش الإشعارات)
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    // تمرير التوكن لـ Firebase Messaging
    Messaging.messaging().apnsToken = deviceToken
    
    // تمرير التوكن للمحرك الأصلي لضمان عمل الإشعارات المحلية
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
  
  // 5️⃣ ✅ تسجيل أخطاء الوصول للإشعارات (مفيد جداً في تتبع أسباب الكراش)
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("🔴 [APNs Error]: \(error.localizedDescription)")
  }
}