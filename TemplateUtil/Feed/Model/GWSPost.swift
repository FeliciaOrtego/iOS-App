//
//  GWSFeed.swift
//  SocialNetwork
//
//  Created by Jared Sullivan and Osama Naeem on 07/06/2019.
//  Copyright © 2022 Lawn and Order. All rights reserved.
//

import UIKit

class GWSPost: GWSGenericBaseModel {
    var postUserName: String?
    var postText: String
    var postLikes: Int
    var postComment: Int
    var postMedia: [String]
    var postReactions: [String: Int] = [:]
    var profileImage: String
    var authorID: String?
    var createdAt: Date?
    var location: String?
    var id: String
    var latitude: Double?
    var longitude: Double?
    var selectedReaction: String?
    var postVideoPreview: [String]
    var postVideo: [String]

    var description: String {
        return "GWSUser post"
    }

    // Creating an GWSPost in new post VC using this initializer
    init(postUserName: String, postText: String, postLikes: Int, postComment: Int, postMedia: [String], profileImage: String, createdAt: Date?, authorID: String, location: String, id: String, latitude: Double, longitude: Double, postReactions: [String: Int], selectedReaction: String, postVideoPreview: [String], postVideo: [String]) {
        self.postUserName = postUserName
        self.postText = postText
        self.postLikes = postLikes
        self.postComment = postComment
        self.postMedia = postMedia
        self.profileImage = profileImage
        self.createdAt = createdAt
        self.authorID = authorID
        self.location = location
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.postReactions = postReactions
        self.selectedReaction = selectedReaction
        self.postVideoPreview = postVideoPreview
        self.postVideo = postVideo
    }

    // When creating a post from data fetched from firebase
    required init(jsonDict: [String: Any]) {
        authorID = jsonDict["authorID"] as? String ?? ""
        postMedia = jsonDict["postMedia"] as? [String] ?? []
        postText = jsonDict["postText"] as? String ?? ""
        createdAt = jsonDict["createdAt"] as? Date ?? Date()
        postLikes = (jsonDict["postLikes"] as? Int) ?? 0
        postUserName = (jsonDict["postUserName"] as? String) ?? ""
        postComment = (jsonDict["postComment"] as? Int) ?? 0
        profileImage = (jsonDict["profileImage"] as? String) ?? ""
        location = (jsonDict["location"] as? String) ?? "San Francisco"
        id = (jsonDict["id"] as? String) ?? ""
        longitude = (jsonDict["longitude"] as? Double) ?? 0.0
        latitude = (jsonDict["latitude"] as? Double) ?? 0.0
        postReactions = (jsonDict["reactions"] as? [String: Int]) ?? [:]
        selectedReaction = (jsonDict["selectedReaction"] as? String) ?? ""
        postVideoPreview = jsonDict["postVideoPreview"] as? [String] ?? []
        postVideo = jsonDict["postVideo"] as? [String] ?? []
    }
}
