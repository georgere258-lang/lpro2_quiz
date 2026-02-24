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
    
    // 1️⃣ تهيئة Firebase بالكود البرمجي
    if FirebaseApp.app() == nil {
      let options = FirebaseOptions(
        googleAppID: "1:905243871570:ios:7dd006b803e36a4c66928b",
        gcmSenderID: "905243871570"
      )
      options.apiKey = "AIzaSyBWYT8L88sd9Vz1tvnKRg1TJZmaEi_HMZw"
      options.projectID = "lpro2-quiz"
      options.bundleID = "com.george.lpro"
      options.clientID = "905243871570-1e1rl17ir696ml70u9ejvdev651t81f6.apps.googleusercontent.com"
      options.storageBucket = "lpro2-quiz.firebasestorage.app"
      
      FirebaseApp.configure(options: options)
      print("✅ [Firebase] Configured programmatically")
    }
    
    // 2️⃣ ضبط مفوض الإشعارات
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    
    // 3️⃣ ضبط مفوض Firebase Messaging
    Messaging.messaging().delegate = self
    
    // 4️⃣ تسجيل إضافات Flutter
    GeneratedPluginRegistrant.register(with: self)

    // تصفير عداد الإشعارات فور تشغيل التطبيق لضمان اختفاء الرقم
    if #available(iOS 10.0, *) {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    UIApplication.shared.applicationIconBadgeNumber = 0
    print("🧹 [Badge] Icon badge and notification center cleared on launch")
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // ✅ التعديل الجوهري: ربط التوكن يدوياً بـ Firebase لفك القفلة
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    print("✅ [APNs] Token received from Apple")
    
    // إرسال التوكن لـ Firebase يدوياً (هذا السطر هو الحل)
    Messaging.messaging().apnsToken = deviceToken
    
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
  
  // ✅ Handle APNs Registration Failure
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("🔴 [APNs] Registration failed: \(error.localizedDescription)")
  }
  
  // ✅ CRITICAL: Handle Foreground Notifications
  @available(iOS 10.0, *)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo
    print("🔔 [FCM] Notification received in FOREGROUND: \(userInfo)")
    
    if #available(iOS 14.0, *) {
      completionHandler([[.banner, .sound, .badge]])
    } else {
      completionHandler([[.alert, .sound, .badge]])
    }
  }
  
  // ✅ CRITICAL: Handle Notification Tap
  @available(iOS 10.0, *)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    print("🔔 [FCM] Notification tapped")
    UIApplication.shared.applicationIconBadgeNumber = 0
    completionHandler()
  }
}

// ✅ Messaging Delegate Extension
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("🔥 [FCM] Token: \(fcmToken ?? "nil")")
    
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }
}