//
//  AppRootScreenViewModel.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 08/04/21.
//

import LocalAuthentication
import SwiftUI

class AppRootScreenViewModel: ObservableObject {
    @ObservedObject var authManager: AuthManager

    @Published var showProgress: Bool = false
    @Published var resyncSuccess: Bool = false {
        didSet {
            if resyncSuccess {
                registerForPushNotifications()
            }
        }
    }

    @Published var resyncCompleted: Bool = false
    @ObservedObject var store: GWSPersistentStore
    let userManager: GWSSocialUserManagerProtocol?
    var viewer: GWSUser?
    let faceIDKey = "face_id_enabled"
    var userStatus: Bool = false
    var appConfig: GWSConfigurationProtocol

    init(store: GWSPersistentStore, appConfig: GWSConfigurationProtocol) {
        self.store = store
        self.appConfig = appConfig
        userManager = GWSSocialFirebaseUserManager()
        authManager = AuthManager.shared
    }

    func resyncPersistentCredentials() {
        if let loggedInUser = store.userIfLoggedInUser() {
            let result = UserDefaults.standard.value(forKey: "\(loggedInUser.uid!)")
            if let finalResult = result as? [String: Bool] {
                userStatus = finalResult[faceIDKey] ?? false
            }
            if userStatus {
                biometricAuthentication(user: loggedInUser)
            } else {
                startResyncPersistentUser(user: loggedInUser)
            }
        }
    }

    private func startResyncPersistentUser(user: GWSUser) {
        showProgress = true
        resyncPersistentUser(user: user) { [weak self] syncedUser, _ in
            self?.showProgress = false
            if let syncedUser = syncedUser {
                self?.viewer = syncedUser
                // Data that needs to be polled at all times can go here

                self?.resyncSuccess = true

            } else {
                self?.resyncSuccess = false
            }
            self?.resyncCompleted = true
        }
    }

    private func biometricAuthentication(user: GWSUser) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Identify Yourself"

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [unowned self] success, _ in
                DispatchQueue.main.async {
                    if success {
                        print("Successfully match")
                        self.startResyncPersistentUser(user: user)
                    } else {
                        print("Error - not a successful match - Log in using password")
                        self.resyncSuccess = false
                        self.resyncCompleted = true
                    }
                }
            }
        } else {
            print("No Biometric Auth support")
            startResyncPersistentUser(user: user)
        }
    }

    func resyncPersistentUser(user: GWSUser, completionBlock: @escaping (_ user: GWSUser?, _ error: Error?) -> Void) {
        if let uid = user.uid {
            userManager?.fetchUser(userID: uid) { newUser, error in
                if let newUser = newUser {
                    completionBlock(newUser, error)
                } else {
                    // User is no longer existing
                    if let email = user.email, user.uid == email {
                        // We don't log out Apple Signed in users
                        completionBlock(user, error)
                        return
                    }
                    completionBlock(nil, error)
                }
            }
        }
    }

    func registerForPushNotifications() {
        if let loggedInUser = store.userIfLoggedInUser() {
            let pushManager = GWSPushNotificationManager(user: loggedInUser)
            pushManager.registerForPushNotifications()
        }
    }
}
