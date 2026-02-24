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
    
    // 1️⃣ تهيئة Firebase بالكود البرمجي (لا يعتمد على ملف)
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

    // ✅ [تعديل النسخة 44]: تصفير عداد الإشعارات فور تشغيل التطبيق
    // هذا يضمن اختفاء الرقم من الأيقونة بمجرد دخول المستخدم للتطبيق
    if #available(iOS 10.0, *) {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    UIApplication.shared.applicationIconBadgeNumber = 0
    print("🧹 [Badge] Icon badge and notification center cleared on launch")
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // ✅ Handle APNs Token
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    print("✅ [APNs] Token received")
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
    
    print("🔔 [FCM] Notification received in FOREGROUND:")
    print(userInfo)
    
    // ✅ السماح بظهور الصوت والراية والرقم أثناء فتح التطبيق
    if #available(iOS 14.0, *) {
      completionHandler([[.banner, .sound, .badge]])
    } else {
      completionHandler([[.alert, .sound, .badge]])
    }
  }
  
  // ✅ CRITICAL: Handle Notification Tap (Background/Closed)
  @available(iOS 10.0, *)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    
    print("🔔 [FCM] Notification tapped:")
    print(userInfo)
    
    // تصفير العداد عند النقر على الإشعار أيضاً
    UIApplication.shared.applicationIconBadgeNumber = 0
    
    completionHandler()
  }
}

// ✅ CRITICAL: Messaging Delegate Extension
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