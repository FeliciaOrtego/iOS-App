//
//  GWSFirebaseSocialGraphManager.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 27/05/21.
//

import FirebaseFirestore

class GWSFirebaseSocialGraphManager {
    let reportingManager = GWSFirebaseUserReporter()

    func fetchInBoundOutBoundUsers(viewer: GWSUser, isInBoundUsers: Bool, completion: @escaping (_ inboundusers: [GWSUser]) -> Void) {
        guard let userId = viewer.uid else { return }
        reportingManager.userIDsBlockedOrReported(by: viewer) { illegalUserIDsSet in
            let usersRef = Firestore.firestore().collection("social_graph").document(userId).collection(isInBoundUsers ? "inbound_users" : "outbound_users")
            usersRef.getDocuments { querySnapshot, error in
                if error != nil {
                    completion([])
                    return
                }
                guard let querySnapshot = querySnapshot else {
                    completion([])
                    return
                }
                var users: [GWSUser] = []
                let documents = querySnapshot.documents
                for document in documents {
                    let data = document.data()
                    let user = GWSUser(representation: data)
                    if let userID = user.uid {
                        if userID != viewer.uid {
                            users.append(user)
                        }
                    }
                }
                users = users.filter { !illegalUserIDsSet.contains($0.uid ?? "") }
                completion(users)
            }
        }
    }
}
