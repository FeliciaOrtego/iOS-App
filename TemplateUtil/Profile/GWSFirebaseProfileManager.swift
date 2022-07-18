//
//  GWSChatProfileManager.swift
//  ChatApp
//
//  Created by Jared Sullivan and Osama Naeem on 28/05/2019.
//  Copyright © 2022 Lawn and Order. All rights reserved.
//

import FirebaseFirestore
import UIKit

class GWSFirebaseProfileManager: GWSProfileManager {
    var usersListener: ListenerRegistration?

    var delegate: GWSProfileManagerDelegate?

    func fetchProfile(for user: GWSUser) {
        delegate?.profileEditManager(self, didFetch: user)
    }

    func update(profile: GWSUser, email: String, firstName: String, lastName: String, phone: String) {
        let documentRef = Firestore.firestore().collection("users").document("\(profile.uid!)")

        documentRef.updateData([
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "phone": phone,
            "id": profile.uid!,
            "userID": profile.uid!,
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
                self.delegate?.profileEditManager(self, didUpdateProfile: false)
            } else {
                print("Successfully updated")
                profile.firstName = firstName
                profile.lastName = lastName
                profile.email = email
                self.delegate?.profileEditManager(self, didUpdateProfile: true)
            }
        }
    }

    func updateUserPresence(profile: GWSUser, isOnline: Bool) {
        let documentRef = Firestore.firestore().collection("users").document("\(profile.uid!)")
        documentRef.updateData([
            "isOnline": isOnline,
            "lastOnlineTimestamp": Date(),
        ])
    }
}
