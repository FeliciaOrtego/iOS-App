//
//  GWSNewPostViewModel.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 30/04/21.
//

import FirebaseFirestore
import FirebaseStorage
import SwiftUI

let kNewPostAddedNotificationName = NSNotification.Name(rawValue: "kNewPostAddedNotificationName")

class GWSNewPostViewModel: ObservableObject {
    @Published var isPostSharing: Bool = false
    @Binding var isNewPostPresented: Bool

    init(isNewPostPresented: Binding<Bool>) {
        _isNewPostPresented = isNewPostPresented
    }

    func saveNewPost(user: GWSUser?, postComposer: GWSPostComposerState) {
        isPostSharing = true

        let photos = postComposer.postMedia ?? []
        let videos = postComposer.postVideo ?? []
//        let videosPreviews = postComposer.postVideoPreview ?? []
        let newDocumentRef = Firestore.firestore().collection("SocialNetwork_Posts").document()

        var photoURLs: [[String: String]] = []
//        var videoPreviewURLs: [String] = []
        var videoURLs: [String] = []

        var uploadedPhotos = 0

//        var uploadedVideoPreviewPhotos = 0
        var uploadedVideos = 0

        let reactionsDictionary: [String: Int] = [
            "like": 0,
            "angry": 0,
            "sad": 0,
            "surprised": 0,
            "laugh": 0,
            "cry": 0,
            "love": 0,
        ]

        var dictionary: [String: Any] = [
            "postText": (postComposer.postText ?? "").atcTrimmed(),
            "location": postComposer.location ?? "",
            "createdAt": postComposer.date ?? Date(),
            "latitude": postComposer.latitude ?? 0,
            "longitude": postComposer.longitude ?? 0,
            "reactions": reactionsDictionary,
            "commentCount": 0,
            "reactionsCount": 0,
        ]

        if let user = user {
            dictionary["authorID"] = user.uid
        }

        if photos.count == 0, videos.count == 0 {
            dictionary["id"] = newDocumentRef.documentID
            newDocumentRef.setData(dictionary)
            updateNewPost(user: user, dictionary: dictionary)
            isPostSharing = false
            isNewPostPresented = false
            return
        }

        photos.forEach { image in
            self.uploadImage(image, completion: { url in
                if let urlString = url?.absoluteString {
                    print(urlString)
                    photoURLs.append(["url": urlString,
                                      "mime": "image/jpeg"])
                }
                uploadedPhotos += 1
                if uploadedPhotos == photos.count, uploadedVideos == videos.count {
                    dictionary["id"] = newDocumentRef.documentID
                    dictionary["postMedia"] = photoURLs
                    newDocumentRef.setData(dictionary)
                    self.updateNewPost(user: user, dictionary: dictionary)
                    self.isPostSharing = false
                    self.isNewPostPresented = false
                }
            })
        }

        videos.forEach { video in
            self.uploadVideo(video) { url in
                if let urlString = url?.absoluteString {
                    print(urlString)
                    photoURLs.append(["url": urlString,
                                      "mime": "video/mp4"])
                }
                uploadedVideos += 1
                if uploadedPhotos == photos.count, uploadedVideos == videos.count {
                    dictionary["id"] = newDocumentRef.documentID
                    dictionary["postMedia"] = photoURLs
                    newDocumentRef.setData(dictionary)
                    self.updateNewPost(user: user, dictionary: dictionary)
                    self.isPostSharing = false
                    self.isNewPostPresented = false
                }
            }
        }

//        videosPreviews.forEach { (preview) in
//            self.uploadImage(preview) { (url) in
//                if let urlString = url?.absoluteString {
//                    print(urlString)
//                    photoURLs.append(["url": urlString,
//                                      "mime": "image/jpeg"])
//                }
//                uploadedVideoPreviewPhotos += 1
//                if (uploadedPhotos == photos.count && uploadedVideoPreviewPhotos == videos.count && uploadedVideos == videos.count) {
//                    dictionary["id"] = newDocumentRef.documentID
//                    dictionary["postMedia"] = photoURLs
//                    newDocumentRef.setData(dictionary)
//                    self.isPostSharing = false
//                    self.isNewPostPresented = false
//                }
//            }
//        }
    }

    private func updateNewPost(user: GWSUser?, dictionary: [String: Any]) {
        let newPost = GWSPostModel(jsonDict: dictionary)
        newPost.profileImage = user?.profilePictureURL ?? ""
        newPost.postUserName = user?.fullName()
        NotificationCenter.default.post(name: kNewPostAddedNotificationName, object: nil, userInfo: dictionary)
    }

    private func uploadImage(_ image: UIImage, completion: @escaping (URL?) -> Void) {
        let storage = Storage.storage().reference()

        guard let scaledImage = image.scaledToSafeUploadSize, let data = scaledImage.jpegData(compressionQuality: 0.4) else {
            completion(nil)
            return
        }

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        let imageName = [UUID().uuidString, String(Date().timeIntervalSince1970)].joined()
        let ref = storage.child("SocialNetwork_Posts").child(imageName)
        ref.putData(data, metadata: metadata) { _, _ in
            ref.downloadURL { url, _ in
                print("Picture URL is : \(url)")
                completion(url)
            }
        }
    }

    private func uploadVideo(_ url: URL, completion: @escaping (URL?) -> Void) {
        let storage = Storage.storage().reference()

        let metadata = StorageMetadata()
        metadata.contentType = "video/mp4"

        let fileName = [UUID().uuidString, String(Date().timeIntervalSince1970)].joined()
        let ref = storage.child("SocialNetwork_Posts").child(fileName)
        ref.putFile(from: url, metadata: metadata) { _, _ in
            ref.downloadURL(completion: { url, _ in
                print("Video URL is: \(url)")
                completion(url)
            })
        }
    }
}
