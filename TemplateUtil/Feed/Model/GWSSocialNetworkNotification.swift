//
//  GWSNotification.swift
//  SocialNetwork
//
//  Created by Jared Sullivan and Osama Naeem on 29/07/2019.
//  Copyright © 2022 Lawn and Order. All rights reserved.
//

import UIKit

class GWSSocialNetworkNotification: GWSGenericBaseModel {
    var postID: String
    var postAuthorID: String
    var notificationAuthorID: String
    var reacted: Bool
    var commented: Bool
    var isInteracted: Bool = false
    var notificationAuthorProfileImage: String
    var notificationAuthorUsername: String
    var createdAt: Date?
    var id: String

    var description: String {
        return postID
    }

    init(postID: String, notificationAuthorID: String, postAuthorID: String, reacted: Bool, commented: Bool, isInteracted: Bool, notificationAuthorProfileImage: String, notificationAuthorUsername: String, createdAt: Date, id: String) {
        self.postID = postID
        self.postAuthorID = postAuthorID
        self.notificationAuthorID = notificationAuthorID
        self.reacted = reacted
        self.commented = commented
        self.isInteracted = isInteracted
        self.notificationAuthorProfileImage = notificationAuthorProfileImage
        self.notificationAuthorUsername = notificationAuthorUsername
        self.createdAt = createdAt
        self.id = id
    }

    required init(jsonDict: [String: Any]) {
        postID = jsonDict["postID"] as? String ?? ""
        postAuthorID = jsonDict["postAuthorID"] as? String ?? ""
        notificationAuthorID = jsonDict["notificationAuthorID"] as? String ?? ""
        reacted = jsonDict["reacted"] as? Bool ?? false
        commented = jsonDict["commented"] as? Bool ?? false
        isInteracted = jsonDict["isInteracted"] as? Bool ?? false
        notificationAuthorProfileImage = jsonDict["notificationAuthorProfileImage"] as? String ?? ""
        notificationAuthorUsername = jsonDict["notificationAuthorUsername"] as? String ?? ""
        createdAt = jsonDict["createdAt"] as? Date ?? Date()
        id = jsonDict["id"] as? String ?? ""
    }
}
