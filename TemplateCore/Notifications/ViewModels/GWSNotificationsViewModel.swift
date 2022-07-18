//
//  GWSNotificationsViewModel.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 25/05/21.
//

import FirebaseFirestore
import SwiftUI

class GWSNotificationsViewModel: ObservableObject {
    @Published var notifications: [GWSFeedPostNotification] = []
    @Published var showLoader: Bool = false

    func fetchNotifications(loggedInUser: GWSUser?) {
        let db = Firestore.firestore()
        let ref = db.collection("socialnetwork_notifications")
        let userManager = GWSSocialFirebaseUserManager()

        var notificationsArray: [GWSFeedPostNotification] = []
        guard let loggedInUser = loggedInUser, let loggedInUserUID = loggedInUser.uid else { return }
        let notificationRef = ref.whereField("postAuthorID", isEqualTo: loggedInUserUID) // .order(by: "createdAt", descending: true)
        showLoader = true
        notificationRef.getDocuments { querySnapshot, error in
            if let _ = error {
                self.showLoader = false
                return
            }

            guard let snapshot = querySnapshot else {
                self.showLoader = false
                return
            }

            let documents = snapshot.documents
            var documentsCount = documents.count
            if documentsCount == 0 {
                self.showLoader = false
            }
            for doc in documents {
                let data = doc.data()
                let timeStamp = doc["createdAt"] as? Timestamp
                let date = timeStamp?.dateValue()
                let notificationAuthorID = data["notificationAuthorID"] as? String ?? ""
                userManager.fetchUser(userID: notificationAuthorID, completion: { user, _ in
                    guard let user = user else {
                        documentsCount -= 1
                        if notificationsArray.count == documentsCount {
                            self.showLoader = false
                            self.notifications = notificationsArray
                        }
                        return
                    }
                    let newNotification = GWSFeedPostNotification(jsonDict: data)
                    newNotification.createdAt = date
                    newNotification.notificationAuthorProfileImage = user.profilePictureURL ?? ""
                    newNotification.notificationAuthorUsername = user.fullName()
                    notificationsArray.append(newNotification)

                    if notificationsArray.count == documentsCount {
                        self.showLoader = false
                        self.notifications = notificationsArray
                    }
                })
            }
        }
    }
}
