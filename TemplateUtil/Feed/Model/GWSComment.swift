//
//  GWSComment.swift
//  SocialNetwork
//
//  Created by Jared Sullivan and Osama Naeem on 01/07/2019.
//  Copyright © 2022 Lawn and Order. All rights reserved.
//

import UIKit

class GWSComment: GWSGenericBaseModel {
    var commentAuthorUsername: String?
    var commentAuthorProfilePicture: String?
    var commentText: String?
    var createdAt: Date?

    var description: String {
        return "GWS Comment"
    }

    init(commentAuthorUsername: String, commentAuthorProfilePicture: String, commentText: String, createdAt: Date) {
        self.commentText = commentText
        self.commentAuthorUsername = commentAuthorUsername
        self.commentAuthorProfilePicture = commentAuthorProfilePicture
        self.createdAt = createdAt
    }

    required init(jsonDict: [String: Any]) {
        commentText = (jsonDict["commentText"] as? String) ?? ""
        commentAuthorProfilePicture = (jsonDict["commentAuthorProfilePicture"] as? String) ?? ""
        commentAuthorUsername = (jsonDict["commentAuthorUsername"] as? String) ?? ""
        createdAt = (jsonDict["createdAt"] as? Date) ?? Date()
    }
}
