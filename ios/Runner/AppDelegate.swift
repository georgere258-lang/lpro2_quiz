import UIKit
import Flutter
import Firebase
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // 1️⃣ تهيئة فايربيز برمجياً (بدون الاعتماد على ملف Plist المفقود)
    if FirebaseApp.app() == nil {
        // إنشاء الإعدادات يدوياً باستخدام بياناتك الخاصة
        let options = FirebaseOptions(
            googleAppID: "1:905243871570:ios:7dd006b803e36a4c66928b",
            gcmSenderID: "905243871570"
        )
        options.apiKey = "AIzaSyBWYT8L88sd9Vz1tvnKRg1TJZmaEi_HMZw"
        options.projectID = "lpro2-quiz"
        options.bundleID = "com.george.lpro"
        options.clientID = "905243871570-1e1rl17ir696ml70u9ejvdev651t81f6.apps.googleusercontent.com"
        options.storageBucket = "lpro2-quiz.firebasestorage.app"
        
        // تشغيل فايربيز بالإعدادات اليدوية
        FirebaseApp.configure(options: options)
    }
    
    // 2️⃣ ضبط مفوض الإشعارات
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    
    // 3️⃣ تسجيل إضافات فلوتر
    GeneratedPluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // 4️⃣ استلام توكن Apple وتمريره لـ Firebase
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
  
  // 5️⃣ تسجيل أخطاء الوصول للإشعارات
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("🔴 [APNs Error]: \(error.localizedDescription)")
  }
}