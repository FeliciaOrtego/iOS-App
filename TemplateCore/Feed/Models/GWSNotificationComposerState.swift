//
//  GWSNotificationComposerState.swift
//  SocialNetwork
//
//  Created by Jared Sullivan and Osama Naeem on 29/07/2019.
//  Copyright © 2022 Lawn and Order. All rights reserved.
//

import UIKit

class GWSNotificationComposerState {
    var post: GWSPostModel
    var notificationAuthorID: String
    var reacted: Bool
    var commented: Bool
    var isInteracted: Bool = false
    var createdAt: Date?

    init(post: GWSPostModel, notificationAuthorID: String, reacted: Bool, commented: Bool, isInteracted: Bool, createdAt: Date) {
        self.post = post
        self.notificationAuthorID = notificationAuthorID
        self.reacted = reacted
        self.commented = commented
        self.isInteracted = isInteracted
        self.createdAt = createdAt
    }
}
