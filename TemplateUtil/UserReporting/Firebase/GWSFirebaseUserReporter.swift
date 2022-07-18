//
//  GWSFirebaseUserReporter.swift
//  DatingApp
//
//  Created by Jared Sullivan and Florian Marcu on 4/10/19.
//  Copyright © 2022 Lawn and Order. All rights reserved.
//

import FirebaseFirestore
import UIKit

class GWSFirebaseUserReporter: GWSUserReportingProtocol {
    func report(sourceUser: GWSUser, destUser: GWSUser, reason: GWSReportingReason, completion: @escaping (_ success: Bool) -> Void) {
        guard let sourceID = sourceUser.uid, let destID = destUser.uid else { return }
        let reportsRef = Firestore.firestore().collection("reports")
        let data: [String: Any] = [
            "source": sourceID,
            "dest": destID,
            "reason": reason.rawValue,
            "createdAt": Date(),
        ]
        reportsRef.addDocument(data: data) { error in
            if error == nil {
                NotificationCenter.default.post(name: kUserReportingDidUpdateNotificationName, object: nil)
            }
            completion(error == nil)
        }
    }

    func block(sourceUser: GWSUser, destUser: GWSUser, completion: @escaping (_ success: Bool) -> Void) {
        guard let sourceID = sourceUser.uid, let destID = destUser.uid else { return }
        let blockRef = Firestore.firestore().collection("blocks")
        let data: [String: Any] = [
            "source": sourceID,
            "dest": destID,
            "createdAt": Date(),
        ]
        blockRef.addDocument(data: data) { error in
            if error == nil {
                NotificationCenter.default.post(name: kUserReportingDidUpdateNotificationName, object: nil)
            }
            completion(error == nil)
        }
    }

    func userIDsBlockedOrReported(by user: GWSUser, completion: @escaping (_ users: Set<String>) -> Void) {
        guard let id = user.uid else { return }
        let blocksRef: Query = Firestore.firestore().collection("blocks").whereField("source", isEqualTo: id)
        blocksRef.getDocuments { querySnapshot, error in
            if error != nil {
                completion(Set<String>())
                return
            }
            guard let querySnapshot = querySnapshot else {
                completion(Set<String>())
                return
            }
            var blockedIDs: [String] = []
            let documents = querySnapshot.documents
            for document in documents {
                if let dest = document.data()["dest"] as? String {
                    blockedIDs.append(dest)
                }
            }
            let reportsRef: Query = Firestore.firestore().collection("reports").whereField("source", isEqualTo: id)
            reportsRef.getDocuments { querySnapshot, error in
                if error != nil {
                    completion(Set<String>(blockedIDs))
                    return
                }
                guard let querySnapshot = querySnapshot else {
                    completion(Set<String>(blockedIDs))
                    return
                }
                var reportedIDs: [String] = []
                let documents = querySnapshot.documents
                for document in documents {
                    if let dest = document.data()["dest"] as? String {
                        reportedIDs.append(dest)
                    }
                }
                completion(Set<String>(blockedIDs + reportedIDs))
            }
        }
    }
}
