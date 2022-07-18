//
//  GWSProfileViewModel.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 21/04/21.
//

import FirebaseFirestore
import SwiftUI

class GWSProfileViewModel: ObservableObject, GWSFeedPostManagerProtocol {
    @Published var posts: [GWSPostModel] = []
    @Published var postComments: [GWSPostComment] = []
    @Published var isPostFetching: Bool = false
    var viewer: GWSUser?
    var loggedInUser: GWSUser?
    @Published var showLoader: Bool = false
    let push_notification_key = "push_notifications_enabled"
    let face_id_key = "face_id_enabled"
    var pushNotificationManager: GWSPushNotificationManager?
    private let defaults = UserDefaults.standard
    let profileFirebaseUpdater: GWSProfileFirebaseUpdater = .init(usersTable: "users")
    @Published var isProfileImageUpdated: Bool = false
    @Published var uiImage: UIImage? = nil {
        didSet {
            if let uiImage = uiImage {
                isProfileImageUpdated = true
                updateProfileImage(image: uiImage)
            }
        }
    }

    @Published var shouldShowAlert = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var isInitialPostFetched = true // always true for now
    var isLoggedInUser: Bool = false

    init(loggedInUser: GWSUser?, viewer: GWSUser?) {
        self.loggedInUser = loggedInUser
        if let viewer = viewer, viewer.uid != loggedInUser?.uid {
            isLoggedInUser = false
        } else {
            isLoggedInUser = true
        }
    }

    func update(email: String, firstName: String, lastName: String, phone: String, completion: @escaping () -> Void) {
        showLoader = true
        let documentRef = Firestore.firestore().collection("users").document("\(loggedInUser?.uid ?? "0")")
        documentRef.setData([
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "phone": phone,
        ], merge: true) { err in
            self.showLoader = false
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Successfully updated")
                self.loggedInUser?.firstName = firstName
                self.loggedInUser?.lastName = lastName
                self.loggedInUser?.email = email
                self.loggedInUser?.phoneNumber = phone
                completion()
            }
        }
    }

    func updateSettings(isPushNotificationsEnabled: Bool, isFaceIDOrTouchIDEnabled: Bool) {
        showLoader = true
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        let usersRef = Firestore.firestore().collection("users").document("\(loggedInUser?.uid ?? "0")")
        let userSettingsJSON = [
            "settings": [
                push_notification_key: isPushNotificationsEnabled,
                face_id_key: isFaceIDOrTouchIDEnabled,
            ],
        ]
        usersRef.setData(userSettingsJSON, merge: true) { [weak self] error in
            guard let self = self else { return }
            self.showLoader = false
            if error == nil {
                if isPushNotificationsEnabled {
                    self.pushNotificationManager?.updateFirestorePushTokenIfNeeded()
                } else {
                    self.pushNotificationManager?.removeFirestorePushTokenIfNeeded()
                }
                self.defaults.set(userSettingsJSON, forKey: "\(self.loggedInUser?.uid ?? "0")")
                self.loggedInUser?.settings[self.push_notification_key] = isPushNotificationsEnabled
                self.loggedInUser?.settings[self.face_id_key] = isFaceIDOrTouchIDEnabled
            }
        }
    }

    func updateProfileImage(image: UIImage) {
        guard let user = loggedInUser else { return }
        showLoader = true
        profileFirebaseUpdater.uploadPhoto(image: image, user: user, isProfilePhoto: true) { [weak self] _ in
            self?.showLoader = false
        }
    }

    func removePhoto() {
        guard let user = loggedInUser else { return }
        let documentRef = Firestore.firestore().collection("users").document("\(user.uid!)")

        showLoader = true
        documentRef.updateData([
            "profilePictureURL": FieldValue.delete(),
        ]) { [weak self] _ in
            user.profilePictureURL = GWSUser.defaultAvatarURL
            self?.showLoader = false
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: kNewPostAddedNotificationName, object: nil)
    }
}
