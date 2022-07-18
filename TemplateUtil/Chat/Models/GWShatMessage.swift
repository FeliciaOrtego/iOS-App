//
//  GWShatMessage.swift
//  ChatApp
//
//  Created by Jared Sullivan and Florian Marcu on 8/20/18.
//  Copyright © 2022 Lawn and Order. All rights reserved.
//

import Firebase
import FirebaseFirestore

public enum GWSMediaType {
    case video
    case audio

    var rawValue: String {
        switch self {
        case .video: return "video"
        case .audio: return "audio"
        }
    }
}

class GWSMediaItem: MediaItem {
    var duration: Float = 0.0
    var thumbnailUrl: URL?
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    init(url: URL?, image: UIImage? = nil) {
        self.url = url
        self.image = image
        placeholderImage = UIImage.localImage("camera-icon")
        size = CGSize(width: 500, height: 500)
    }
}

class GWSAudioVideoItem: MediaItem {
    var thumbnailUrl: URL?
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    var duration: Float
    var mediaType: GWSMediaType
    init(mediaType: GWSMediaType, url: URL?, image: UIImage? = nil, thumbnailUrl: URL? = nil, duration: Float) {
        self.mediaType = mediaType
        self.url = url
        self.image = image
        placeholderImage = UIImage.localImage("camera-icon")
        self.duration = duration
        self.thumbnailUrl = thumbnailUrl
        switch mediaType {
        case .video:
            let screenWidth = UIScreen.main.bounds.width * 50 / 100
            size = CGSize(width: screenWidth, height: screenWidth)
        case .audio:
            size = CGSize(width: 150, height: 45)
        default:
            size = CGSize(width: 500, height: 500)
        }
    }
}

class GWShatMessage: GWSGenericBaseModel, MessageType {
    var id: String?

    var sentDate: Date

    var kind: MessageKind

    lazy var sender: SenderType = Sender(senderId: atcSender.uid ?? "No Id", displayName: atcSender.uid ?? "No Name")

    var atcSender: GWSUser
    var recipient: GWSUser
    var lastMessageSeeners: [GWSUser]
    var seenByRecipient: Bool

    var messageId: String {
        return id ?? UUID().uuidString
    }

    var image: UIImage? {
        didSet {
            kind = .photo(GWSMediaItem(url: downloadURL, image: image))
        }
    }

    var downloadURL: URL?
    var audioDownloadURL: URL?
    var audioDuration: Float? = 0.0

    var videoThumbnailURL: URL?
    var videoDownloadURL: URL?
    var videoDuration: Float? = 0.0

    var content: String = ""
    var htmlContent: NSAttributedString?

    var allTagUsers: [String] = []
    var inReplyToMessage: String?

    init(messageId: String, messageKind: MessageKind, createdAt: Date, atcSender: GWSUser, recipient: GWSUser, lastMessageSeeners: [GWSUser], seenByRecipient: Bool, allTagUsers: [String] = [], inReplyToMessage: String? = nil) {
        id = messageId
        kind = messageKind
        sentDate = createdAt
        self.atcSender = atcSender
        self.recipient = recipient
        self.seenByRecipient = seenByRecipient
        self.lastMessageSeeners = lastMessageSeeners
        self.allTagUsers = allTagUsers
        self.inReplyToMessage = inReplyToMessage
        switch messageKind {
        case let .text(text):
            content = text
        case let .attributedText(text):
            htmlContent = text
        case let .inReplyToItem((inReplyToMessage, text)):
            content = text
            self.inReplyToMessage = inReplyToMessage
        default:
            content = ""
            htmlContent = nil
        }
    }

    init(user: GWSUser, image: UIImage, url: URL) {
        self.image = image
        content = ""
        htmlContent = nil
        sentDate = Date()
        id = nil
        let mediaItem = GWSMediaItem(url: url, image: nil)
        kind = MessageKind.photo(mediaItem)
        atcSender = user
        recipient = user
        lastMessageSeeners = []
        seenByRecipient = true
    }

    init(user: GWSUser, audioURL: URL, audioDuration: Float) {
        content = ""
        htmlContent = nil
        sentDate = Date()
        id = nil
        let audioItem = GWSAudioVideoItem(mediaType: .audio, url: audioURL, duration: audioDuration)
        kind = MessageKind.audio(audioItem)
        atcSender = user
        recipient = user
        lastMessageSeeners = []
        seenByRecipient = true
        self.audioDuration = audioDuration
    }

    init(user: GWSUser, videoThumbnailURL: URL, videoURL: URL, videoDuration: Float) {
        content = ""
        htmlContent = nil
        sentDate = Date()
        id = nil
        let videoItem = GWSAudioVideoItem(mediaType: .video, url: videoURL, thumbnailUrl: videoThumbnailURL, duration: videoDuration)
        kind = MessageKind.video(videoItem)
        atcSender = user
        recipient = user
        lastMessageSeeners = []
        seenByRecipient = true
        self.videoDuration = videoDuration
    }

    init?(user: GWSUser, document: QueryDocumentSnapshot) {
        let data = document.data()
        guard let sentDate = data["created"] as? Timestamp else {
            return nil
        }
        guard let senderID = data["senderID"] as? String else {
            return nil
        }
        guard let senderFirstName = data["senderFirstName"] as? String else {
            return nil
        }
        guard let senderLastName = data["senderLastName"] as? String else {
            return nil
        }
        guard let senderProfilePictureURL = data["senderProfilePictureURL"] as? String else {
            return nil
        }
        guard let recipientID = data["recipientID"] as? String else {
            return nil
        }
        guard let recipientFirstName = data["recipientFirstName"] as? String else {
            return nil
        }
        guard let recipientLastName = data["recipientLastName"] as? String else {
            return nil
        }
        guard let recipientProfilePictureURL = data["recipientProfilePictureURL"] as? String else {
            return nil
        }

        id = document.documentID

        self.sentDate = sentDate.dateValue()
        atcSender = GWSUser(uid: senderID, firstName: senderFirstName, lastName: senderLastName, avatarURL: senderProfilePictureURL)
        recipient = GWSUser(uid: recipientID, firstName: recipientFirstName, lastName: recipientLastName, avatarURL: recipientProfilePictureURL)

        if let content = data["content"] as? String {
            self.content = content
            let textColor = atcSender.uid == user.uid ? UIColor.white : UIColor.black
            htmlContent = content.htmlToAttributedString(textColor: textColor)
            downloadURL = nil
            if let inReplyToMessage = data["inReplyToMessage"] as? String {
                self.inReplyToMessage = inReplyToMessage
                kind = MessageKind.inReplyToItem((inReplyToMessage, content))
            } else {
                kind = MessageKind.attributedText(content.htmlToAttributedString(textColor: textColor))
            }
        } else if let urlString = data["url"] as? String, let url = URL(string: urlString) {
            downloadURL = url
            content = ""
            htmlContent = nil
            let mediaItem = GWSMediaItem(url: url, image: nil)
            kind = MessageKind.photo(mediaItem)
        } else if let urlString = data["audiourl"] as? String, let url = URL(string: urlString) {
            audioDownloadURL = url
            content = ""
            htmlContent = nil
            audioDuration = data["audioduration"] as? Float
            let audioItem = GWSAudioVideoItem(mediaType: .audio, url: url, duration: audioDuration ?? 0.0)
            kind = MessageKind.audio(audioItem)
        } else if let urlString = data["videourl"] as? String, let url = URL(string: urlString) {
            videoDownloadURL = url
            content = ""
            htmlContent = nil
            videoDuration = data["videoduration"] as? Float
            if let thumbnailUrlString = data["videothumbnailurl"] as? String, let thumbnailUrl = URL(string: thumbnailUrlString) {
                videoThumbnailURL = thumbnailUrl
            }
            let videoItem = GWSAudioVideoItem(mediaType: .video,
                                              url: url,
                                              thumbnailUrl: videoThumbnailURL,
                                              duration: videoDuration ?? 0.0)
            kind = MessageKind.video(videoItem)
        } else {
            return nil
        }
        seenByRecipient = true
        var messageSeeners: [GWSUser] = []
        if let lastMessageSeeners = data["lastMessageSeeners"] as? [[String: String]] {
            for lastMessageSeener in lastMessageSeeners {
                if let uid = lastMessageSeener["uid"] {
                    messageSeeners.append(GWSUser(uid: uid,
                                                  firstName: lastMessageSeener["firstName"],
                                                  lastName: lastMessageSeener["lastName"],
                                                  avatarURL: lastMessageSeener["profilePictureURL"]))
                }
            }
        }
        lastMessageSeeners = messageSeeners
    }

    required init(jsonDict _: [String: Any]) {
        fatalError()
    }

    var description: String {
        return messageText
    }

    var messageText: String {
        switch kind {
        case let .text(text):
            return text
        case let .inReplyToItem((_, text)):
            return text
        default:
            return ""
        }
    }

    var channelId: String {
        let id1 = (recipient.uid ?? "")
        let id2 = (atcSender.uid ?? "")
        return id1 < id2 ? id1 + id2 : id2 + id1
    }
}

extension GWShatMessage: DatabaseRepresentation {
    var representation: [String: Any] {
        var rep: [String: Any] = [
            "created": sentDate,
            "createdAt": sentDate,
            "senderID": atcSender.uid ?? "",
            "senderFirstName": atcSender.firstName ?? "",
            "senderLastName": atcSender.lastName ?? "",
            "senderProfilePictureURL": atcSender.profilePictureURL ?? "",
            "recipientID": recipient.uid ?? "",
            "recipientFirstName": recipient.firstName ?? "",
            "recipientLastName": recipient.lastName ?? "",
            "recipientProfilePictureURL": atcSender.profilePictureURL ?? "",
            "lastMessageSeeners": lastMessageSeeners,
        ]

        if let url = downloadURL {
            rep["url"] = url.absoluteString
        } else if let url = audioDownloadURL {
            rep["audiourl"] = url.absoluteString
            rep["audioduration"] = audioDuration
        } else if let url = videoDownloadURL {
            rep["videourl"] = url.absoluteString
            rep["videoduration"] = videoDuration
            rep["videothumbnailurl"] = videoThumbnailURL?.absoluteString ?? ""
        } else {
            let attributedString = htmlContent?.fetchAttributedText(allTagUsers: allTagUsers)
            rep["content"] = attributedString
        }

        if let inReplyToMessage = inReplyToMessage {
            rep["inReplyToMessage"] = inReplyToMessage
        }
        return rep
    }
}

extension GWShatMessage: Comparable {
    static func == (lhs: GWShatMessage, rhs: GWShatMessage) -> Bool {
        return lhs.id == rhs.id
    }

    static func < (lhs: GWShatMessage, rhs: GWShatMessage) -> Bool {
        return lhs.sentDate < rhs.sentDate
    }
}

import Foundation

protocol DatabaseRepresentation {
    var representation: [String: Any] { get }
}
