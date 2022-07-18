//
//  GWSPostModel.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 12/04/21.
//

import AVKit
import UIKit

class GWSPostModel: ObservableObject, Identifiable {
//    let id = UUID()

    var postUserName: String?
    var postText: String
    var postLikes: Int
    var postComment: Int
    var postMedia: [String]
    var postMediaType: [String]
    var postReactions: [String: Int] = [:]
    var profileImage: String
    var authorID: String?
    var createdAt: Date?
    var location: String?
    var id: String
    var latitude: Double?
    var longitude: Double?
    var selectedReaction: String? {
        didSet {
            if let selectedReaction = selectedReaction {
                isSelectedReaction = (!selectedReaction.isEmpty && selectedReaction != "no_reaction")
            } else {
                isSelectedReaction = false
            }
        }
    }

    @Published var isSelectedReaction: Bool = false
    @Published var player: [Int: AVPlayer] = [:]
    @Published var player1: [Int: AVPlayer] = [:]
    @Published var isVisible: Bool = false
    @Published var isVideoStartPlay: [Int: Bool] = [:]
    @Published var isVideoStartPlay1: [Int: Bool] = [:]

    var postVideoPreview: [String]
    var postVideo: [String]

    var description: String {
        return "GWSUser post"
    }

    var dateAsString: String {
        // Formatting Date
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "d MMM yyyy HH:mm"
        if let date = createdAt {
            let stringDate = TimeFormatHelper.timeAgoString(date: date)
            return stringDate
        }
        return ""
    }

    // Creating an GWSPost in new post VC using this initializer
    init(postUserName: String, postText: String, postLikes: Int, postComment: Int, postMedia: [String], postMediaType: [String], profileImage: String, createdAt: Date?, authorID: String, location: String, id: String, latitude: Double, longitude: Double, postReactions: [String: Int], selectedReaction: String, postVideoPreview: [String], postVideo: [String]) {
        self.postUserName = postUserName
        self.postText = postText
        self.postLikes = postLikes
        self.postComment = postComment
        self.postMedia = postMedia
        self.postMediaType = postMediaType
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
        if let postMedias = jsonDict["postMedia"] as? [[String: Any]] {
            var postUrls: [String] = []
            var postMediaType: [String] = []
            for postMedia in postMedias {
                if let url = postMedia["url"] as? String {
                    postUrls.append(url)
                }
                if let mime = postMedia["mime"] as? String {
                    postMediaType.append(mime)
                }
            }
            postMedia = postUrls
            self.postMediaType = postMediaType
        } else if let postMedia = jsonDict["postMedia"] as? [String: Any] {
            var postUrls: [String] = []
            var postMediaType: [String] = []
            if let url = postMedia["url"] as? String {
                postUrls.append(url)
            }
            if let mime = postMedia["mime"] as? String {
                postMediaType.append(mime)
            }
            self.postMedia = postUrls
            self.postMediaType = postMediaType
        } else {
            postMedia = jsonDict["postMedia"] as? [String] ?? []
            postMediaType = []
        }
        postText = jsonDict["postText"] as? String ?? ""
        createdAt = jsonDict["createdAt"] as? Date ?? Date()
        if let reactionsCount = jsonDict["reactionsCount"] as? Int, reactionsCount != 0 {
            postLikes = reactionsCount
        } else {
            postLikes = (jsonDict["postLikes"] as? Int) ?? 0
        }
        postComment = (jsonDict["commentCount"] as? Int) ?? 0
        if let authorData = jsonDict["author"] as? [String: Any] {
            postUserName = (authorData["username"] as? String) ?? ""
            profileImage = (authorData["profilePictureURL"] as? String) ?? ""
        } else {
            postUserName = (jsonDict["postUserName"] as? String) ?? ""
            profileImage = (jsonDict["profileImage"] as? String) ?? ""
        }
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

class GWSPostReactionStatus: ObservableObject {
    var reaction: String?
    var postID: String?
    var reactionAuthorID: String?

    init(reaction: String, postID: String, reactionAuthorID: String) {
        self.reaction = reaction
        self.postID = postID
        self.reactionAuthorID = reactionAuthorID
    }

    required init(jsonDict: [String: Any]) {
        reaction = jsonDict["reaction"] as? String ?? ""
        postID = jsonDict["postID"] as? String ?? ""
        reactionAuthorID = jsonDict["reactionAuthorID"] as? String ?? ""
    }
}
