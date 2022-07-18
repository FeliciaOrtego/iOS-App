//
//  GWSPushNotificationManager.swift
//  DatingApp
//
//  Created by Jared Sullivan and Florian Marcu on 1/27/19.
//  Copyright © 2022 Lawn and Order. All rights reserved.
//

import Firebase
import FirebaseFirestore
import FirebaseMessaging
import UIKit
import UserNotifications

class GWSPushNotificationManager: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {
    let user: GWSUser

    init(user: GWSUser) {
        self.user = user
        super.init()
    }

    func registerForPushNotifications() {
        if #available(iOS 10.0, *) {
            // For iOS 10 display notifications sent on APNS
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: { _, _ in }
            )
            // For iOS 10 data message sent by FCM
            Messaging.messaging().delegate = self
        } else {
            let settings: UIUserNotificationSettings =
                .init(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }

        UIApplication.shared.registerForRemoteNotifications()
        updateFirestorePushTokenIfNeeded()
    }

    func updateFirestorePushTokenIfNeeded() {
        if let token = Messaging.messaging().fcmToken, let uid = user.uid {
            let usersRef = Firestore.firestore().collection("users").document(uid)
            usersRef.setData(["pushToken": token], merge: true)
        }
    }

    func removeFirestorePushTokenIfNeeded() {
        if let uid = user.uid {
            let usersRef = Firestore.firestore().collection("users").document(uid)
            usersRef.updateData(["pushToken": FieldValue.delete()])
        }
    }

    func messaging(_: Messaging, didReceiveRegistrationToken _: String?) {
        updateFirestorePushTokenIfNeeded()
    }

    func userNotificationCenter(_: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler _: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        guard let notificationType = userInfo["notificationType"] as? String else { return }

        /// With swizzling disabled you must let Messaging know about the message, for Analytics
        Messaging.messaging().appDidReceiveMessage(userInfo)

        DispatchQueue.main.async {
            if let notificationType = GWSNotificationType(rawValue: notificationType) {
                NotificationCenter.default.post(name: notificationType.notiticationName, object: nil, userInfo: userInfo)
            }
        }
    }
}
