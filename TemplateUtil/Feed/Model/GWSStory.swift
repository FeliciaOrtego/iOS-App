//
//  GWSStory.swift
//  SocialNetwork
//
//  Created by Jared Sullivan and Osama Naeem on 18/06/2019.
//  Copyright © 2022 Lawn and Order. All rights reserved.
//

import UIKit

class GWSStory: GWSGenericBaseModel {
    var description: String {
        return "Story"
    }

    var storyType: String
    var storyMediaURL: String
    var storyAuthorID: String
    var createdAt: Date

    init(storyType: String, storyMediaURL: String, storyAuthorID: String, createdAt: Date) {
        self.storyType = storyType
        self.storyMediaURL = storyMediaURL
        self.storyAuthorID = storyAuthorID
        self.createdAt = createdAt
    }

    required init(jsonDict: [String: Any]) {
        storyType = (jsonDict["storyType"] as? String) ?? ""
        storyMediaURL = (jsonDict["storyMediaURL"] as? String) ?? ""
        storyAuthorID = (jsonDict["storyAuthorID"] as? String) ?? ""
        createdAt = (jsonDict["createdAt"] as? Date) ?? Date()
    }
}
