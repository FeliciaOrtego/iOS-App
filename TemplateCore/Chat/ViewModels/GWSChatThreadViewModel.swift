//
//  GWSChatThreadViewModel.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 25/04/21.
//

import AVKit
import FirebaseFirestore
import FirebaseStorage
import SwiftUI

class GWSChatThreadViewModel: ObservableObject {
    private let paginationBatchSize = 50
    @Published var messages: [GWSChatMessage] = []

    @Published var chatText = ""
    var allTagUsers: [String] = []
    var inReplyToMessage: String?

    @Published var showingSheet: Bool = false
    @Published var showAction: Bool = false
    @Published var showFriendGroupActionSheet: Bool = false
    @Published var showReportUserActionSheet: Bool = false
    @Published var showImagePicker: Bool = false
    @Published var showVideoPlayer: Bool = false
    @Published var videoDownloadURL: URL?
    @Published var showingAlert: Bool = false
    @Published var showingAlertForBlockUser: Bool = false
    @Published var showingAlertForRenameGroup: Bool = false
    @Published var isOkayPressed: Bool = false {
        didSet {
            showingAlertForRenameGroup = false
            if let groupNameText = groupNameText, isOkayPressed, !groupNameText.isEmpty {
                chatTitleText = groupNameText
                renameGroup(channel: channel, name: groupNameText)
            }
        }
    }

    @Published var groupNameText: String? = ""
    @Published var chatTitleText: String = ""
    var channel: GWSChatChannel
    @Published var showRecordView: Bool = false
    @Published var showLoader: Bool = false

    init(channel: GWSChatChannel) {
        self.channel = channel
    }

    func fetchChat(channel: GWSChatChannel, user: GWSUser?) {
        guard let user = user, let uid = user.uid else { return }

        let storage = Storage.storage()

        let reference = Firestore.firestore().collection(["channels", channel.id, "thread"].joined(separator: "/"))
        reference
            .order(by: "created", descending: true)
            .limit(to: paginationBatchSize)
            .getDocuments(completion: { [weak self] snapshot, _ in
                guard let self = self else { return }
                guard let docs = snapshot?.documents else { return }
                var firstMessages: [GWSChatMessage] = []
                for doc in docs {
                    guard let message = GWSChatMessage(user: user, document: doc) else {
                        return
                    }
                    if let url = message.downloadURL {
                        if let url = message.downloadURL {
                            message.image = UIImage()
                        }
                        firstMessages.append(message)
                        storage.reference(forURL: url.absoluteString).downloadURL { [weak self] url, _ in
                            guard let self = self else {
                                return
                            }
                            guard let url = url else {
                                return
                            }

                            message.objectWillChange.send()
                            message.downloadURL = url
                            message.downloadURLCompleted = true
//                            self.insertNewMessage(message)
                        }
                    } else {
                        firstMessages.append(message)
                    }
                }
                self.insertMessages(firstMessages)
                self.setupMessageListener(channel: channel, user: user)
            })
    }

    private func setupMessageListener(channel: GWSChatChannel, user: GWSUser) {
        let reference = Firestore.firestore().collection(["channels", channel.id, "thread"].joined(separator: "/"))
        reference.addSnapshotListener { [weak self] querySnapshot, error in
            guard let snapshot = querySnapshot else {
                print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
                return
            }

            guard let self = self else { return }

            snapshot.documentChanges.forEach { change in
                self.handleDocumentChange(change, user: user)
            }
        }
    }

    private func handleDocumentChange(_ change: DocumentChange, user: GWSUser) {
        guard let message = GWSChatMessage(user: user, document: change.document) else {
            return
        }
        switch change.type {
        case .added:
            if let url = message.downloadURL {
                if let url = message.downloadURL {
                    message.image = UIImage()
                }
                insertNewMessage(message)
                let storage = Storage.storage()
                storage.reference(forURL: url.absoluteString).downloadURL { [weak self] url, _ in
                    guard let self = self else {
                        return
                    }
                    guard let url = url else {
                        return
                    }

                    message.objectWillChange.send()
                    message.downloadURL = url
                    message.downloadURLCompleted = true
                    self.insertNewMessage(message)
                }
            } else if message.audioDownloadURL != nil {
                insertNewMessage(message)
            } else {
                insertNewMessage(message)
            }
        case .modified:
            insertNewMessage(message)
        default:
            break
        }
    }

    private func insertMessages(_ newMessages: [GWSChatMessage]) {
        messages.append(contentsOf: newMessages)
        messages.sort()
    }

    private func insertNewMessage(_ message: GWSChatMessage) {
        if messages.contains(message) {
            messages = messages.filter { $0 != message }
        }

        messages.append(message)
        messages.sort()
    }

    func save(_ message: GWShatMessage, _ channel: GWSChatChannel, allTagUsers: [String] = [], user: GWSUser?) {
        let reference = Firestore.firestore().collection(["channels", channel.id, "thread"].joined(separator: "/"))

        reference.addDocument(data: message.representation) { [weak self] error in
            if let e = error {
                print("Error sending message: \(e.localizedDescription)")
                return
            }
            guard let self = self else { return }

            let channelRef = Firestore.firestore().collection("channels").document(channel.id)
            var lastMessage = ""
            switch message.kind {
            case let .text(text), let .inReplyToItem((_, text)):
                lastMessage = text
            case let .attributedText(text):
                lastMessage = text.fetchAttributedText(allTagUsers: allTagUsers)
            case .audio:
                lastMessage = "Someone sent an audio message.".localizedChat
            case .photo:
                lastMessage = "Someone sent a photo.".localizedChat
            case .video:
                lastMessage = "Someone sent a video.".localizedChat
            default:
                break
            }
            let newData: [String: Any] = [
                "lastMessageDate": Date(),
                "lastMessage": lastMessage,
                "lastMessageSeeners": [],
            ]
            channelRef.setData(newData, merge: true)
            self.updateChannelParticipationIfNeeded(channel: channel)
            self.sendOutPushNotificationsIfNeeded(message: message, user: user, channel: channel)
        }
    }

    private func sendOutPushNotificationsIfNeeded(message: GWShatMessage, user: GWSUser?, channel: GWSChatChannel) {
        var lastMessage = ""
        let senderName = user?.firstName ?? "Someone"
        switch message.kind {
        case let .text(text):
            lastMessage = text
        case let .attributedText(text):
            lastMessage = text.string
        case .photo:
            lastMessage = "\(senderName) sent you a photo."
        case .audio:
            lastMessage = "\(senderName) sent you an audio message."
        case .video:
            lastMessage = "\(senderName) sent you a video message."
        default:
            break
        }

        let notificationSender = GWSPushNotificationSender()
        channel.participants.forEach { recipient in
            if let token = recipient.pushToken, recipient.uid != user?.uid {
                notificationSender.sendPushNotification(token: token,
                                                        title: user?.firstName ?? "Instachatty",
                                                        body: lastMessage,
                                                        notificationType: .chatAppNewMessage,
                                                        payload: ["channelId": channel.id])
            }
        }
    }

    func updateChannelParticipationIfNeeded(channel: GWSChatChannel) {
        if channel.participants.count != 2 {
            return
        }
        guard let uid1 = channel.participants.first?.uid, let uid2 = channel.participants[1].uid else { return }
        updateChannelParticipationIfNeeded(channel: channel, uID: uid1)
        updateChannelParticipationIfNeeded(channel: channel, uID: uid2)
    }

    private func updateChannelParticipationIfNeeded(channel: GWSChatChannel, uID: String) {
        let ref1 = Firestore.firestore().collection("channel_participation").whereField("user", isEqualTo: uID).whereField("channel", isEqualTo: channel.id)
        ref1.getDocuments { querySnapshot, _ in
            if querySnapshot?.documents.count == 0 {
                let data: [String: Any] = [
                    "user": uID,
                    "channel": channel.id,
                ]
                Firestore.firestore().collection("channel_participation").addDocument(data: data, completion: nil)
            }
        }
    }

    func sendPhoto(_ image: UIImage, channel: GWSChatChannel, user: GWSUser?) {
        guard let user = user else { return }

        uploadImage(image, to: channel) { [weak self] url in
            guard let self = self else {
                return
            }

            guard let url = url else {
                return
            }
            let message = GWShatMessage(user: user, image: image, url: url)
            message.downloadURL = url

            self.save(message, channel, user: user)
        }
    }

    private func uploadImage(_ image: UIImage, to channel: GWSChatChannel, completion: @escaping (URL?) -> Void) {
        guard let scaledImage = image.scaledToSafeUploadSize, let data = scaledImage.jpegData(compressionQuality: 0.4) else {
            completion(nil)
            return
        }
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        let imageName = [UUID().uuidString, String(Date().timeIntervalSince1970)].joined()
        let storage = Storage.storage().reference()
        storage.child(channel.id).child(imageName).putData(data, metadata: metadata) { meta, _ in
            if let name = meta?.path, let bucket = meta?.bucket {
                let path = "gs://" + bucket + "/" + name
                completion(URL(string: path))
            } else {
                completion(nil)
            }
        }
    }

    func sendMedia(_ videoFileUrl: URL, channel: GWSChatChannel, user: GWSUser?) {
        guard let user = user else { return }

        uploadMediaMessage(videoFileUrl, to: channel) { [weak self] url in

            guard let self = self else {
                return
            }

            guard let url = url else {
                return
            }

            let asset = AVURLAsset(url: videoFileUrl, options: nil)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            var videoThumbnail = UIImage()
            do {
                let thumbnailImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 1, timescale: 60), actualTime: nil)
                videoThumbnail = UIImage(cgImage: thumbnailImage)
            } catch {
                print(error)
            }
            let videoDuration = asset.duration
            let videoDurationSeconds = CMTimeGetSeconds(videoDuration)

            self.uploadImage(videoThumbnail, to: channel) { [weak self] thumbnailUrl in
                guard let self = self else {
                    return
                }

                guard let thumbnailUrl = thumbnailUrl else {
                    return
                }

                let storage = Storage.storage()
                storage.reference(forURL: thumbnailUrl.absoluteString).downloadURL { thumbnailOriginalUrl, _ in
                    if let videoThumbnailUrl = thumbnailOriginalUrl {
                        let message = GWShatMessage(user: user, videoThumbnailURL: videoThumbnailUrl, videoURL: url, videoDuration: Float(videoDurationSeconds))
                        message.videoDownloadURL = url
                        message.videoThumbnailURL = videoThumbnailUrl

                        self.save(message, channel, user: user)
                    }
                }
            }
        }
    }

    private func uploadMediaMessage(_ url: URL, to channel: GWSChatChannel, completion: @escaping (URL?) -> Void) {
        let hud = CPKProgressHUD.progressHUD(style: .loading(text: "Sending".localizedChat))

        let fileName = [UUID().uuidString, String(Date().timeIntervalSince1970)].joined()
        let storage = Storage.storage().reference()
        storage.child(channel.id).child(fileName).putFile(from: url, metadata: nil) { meta, _ in
            hud.dismiss()
            if let name = meta?.path, let bucket = meta?.bucket {
                let path = "gs://" + bucket + "/" + name
                completion(URL(string: path))
            } else {
                completion(nil)
            }
        }
    }

    func reportAction(sourceUser: GWSUser?, destUser: GWSUser?, reason: GWSReportingReason) {
        guard let sourceUser = sourceUser else { return }
        guard let destUser = destUser else { return }

        let reportingManager = GWSFirebaseUserReporter()
        reportingManager.report(sourceUser: sourceUser,
                                destUser: destUser,
                                reason: reason) { _ in
        }
    }

    func blockUser(sourceUser: GWSUser?, destUser: GWSUser?, completion: @escaping (_ success: Bool) -> Void) {
        guard let sourceUser = sourceUser else { return }
        guard let destUser = destUser else { return }

        let reportingManager = GWSFirebaseUserReporter()
        reportingManager.block(sourceUser: sourceUser,
                               destUser: destUser) { success in
            completion(success)
        }
    }

    func renameGroup(channel: GWSChatChannel, name: String) {
        let data: [String: Any] = [
            "name": name,
        ]
        Firestore.firestore().collection("channels").document(channel.id).setData(data, merge: true)
    }

    func leaveGroup(channel: GWSChatChannel, user: GWSUser?) {
        guard let user = user, let uid = user.uid else {
            return
        }
        let ref = Firestore.firestore().collection("channel_participation").whereField("user", isEqualTo: uid).whereField("channel", isEqualTo: channel.id)
        ref.getDocuments { snapshot, _ in
            if let snapshot = snapshot {
                snapshot.documents.forEach { document in
                    Firestore.firestore().collection("channel_participation").document(document.documentID).delete()
                }
            }
        }
    }
}
