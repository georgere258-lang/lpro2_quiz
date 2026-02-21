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
    
    // 1️⃣ تهيئة Firebase
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()  // ✅ استخدم GoogleService-Info.plist (أبسط وأأمن)
    }
    
    // 2️⃣ ضبط مفوض الإشعارات (بدون casting)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self  // ✅ بدون as?
    }
    
    // 3️⃣ ضبط مفوض Firebase Messaging (بدون casting)
    Messaging.messaging().delegate = self  // ✅ بدون as?
    
    // 4️⃣ تسجيل إضافات Flutter
    GeneratedPluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // ✅ Handle APNs Token
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    print("✅ [APNs] Token received successfully")
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
    
    // ✅ Show notification even when app is open:
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
    
    print("🔔 [FCM] Notification tapped (Background/Closed):")
    print(userInfo)
    
    completionHandler()
  }
}

// ✅ CRITICAL: Messaging Delegate Extension
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("🔥 [FCM] Token refreshed: \(fcmToken ?? "nil")")
    
    // Optional: Send to your backend
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }
}