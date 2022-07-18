//
//  GWSSocialFirebaseUserManager.swift
//  CryptoApp
//
//  Created by Jared Sullivan and Florian Marcu on 6/29/19.
//  Copyright © 2022 Lawn and Order. All rights reserved.
//

import FirebaseFirestore
import UIKit

class GWSSocialFirebaseUserManager: GWSSocialUserManagerProtocol {
    func fetchUser(userID: String, completion: @escaping (_ user: GWSUser?, _ error: Error?) -> Void) {
        let usersRef = Firestore.firestore().collection("users").whereField("id", isEqualTo: userID)
        usersRef.getDocuments { querySnapshot, error in
            if error != nil {
                completion(nil, error)
                return
            }
            guard let querySnapshot = querySnapshot else {
                completion(nil, error)
                return
            }
            if let document = querySnapshot.documents.first {
                let data = document.data()
                let user = GWSUser(representation: data)
                completion(user, error)
            } else {
                completion(nil, error)
            }
        }
    }
}
