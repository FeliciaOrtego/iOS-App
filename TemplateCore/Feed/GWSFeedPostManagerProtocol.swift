//
//  GWSFeedPostManagerProtocol.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 27/05/21.
//

import FirebaseFirestore
import SwiftUI

protocol GWSFeedPostManagerProtocol: ObservableObject {
    var posts: [GWSPostModel] { get set }
    var shouldShowAlert: Bool { get set }
    var alertTitle: String { get set }
    var alertMessage: String { get set }
    var postComments: [GWSPostComment] { get set }
    func report(_ post: GWSPostModel, reason: GWSReportingReason, viewer: GWSUser?)
    func block(_ post: GWSPostModel, viewer: GWSUser?)
    func postNotification(composer: GWSNotificationComposerState, completion: @escaping () -> Void)
    func fetchPostComments(post: GWSPostModel)
    func sendPushToPostUser(message: String, post: GWSPostModel)
    func saveNewComment(loggedInUser: GWSUser, commentComposer: GWSCommentComposerState, post: GWSPostModel, completion: @escaping () -> Void)
    func updatePostReactions(loggedInUser: GWSUser?, post: GWSPostModel?, reaction: String, completion: @escaping () -> Void)
    func updatePost(post: GWSPostModel, completion: @escaping () -> Void)
    func deletePost(post: GWSPostModel, completion: @escaping () -> Void)
}

extension GWSFeedPostManagerProtocol {
    func deletePost(post: GWSPostModel, completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        let postID = post.id

        let postRef = db.collection("SocialNetwork_Posts").whereField("id", isEqualTo: postID)
        let commentRef = db.collection("socialnetwork_comments").whereField("postID", isEqualTo: postID)

        postRef.getDocuments { query, error in
            if let _ = error {
                return
            }
            guard let querySnapshot = query else { return }
            let documents = querySnapshot.documents

            for doc in documents {
                doc.reference.delete()
            }

            commentRef.getDocuments(completion: { query, error in
                if let _ = error {
                    return
                }

                guard let querySnapshot = query else { return }
                let comments = querySnapshot.documents

                for comment in comments {
                    comment.reference.delete()
                }
                completion()
            })
        }
    }

    func block(_ post: GWSPostModel, viewer: GWSUser?) {
        guard let sourceUser = viewer else { return }
        guard let postAuthorUID = post.authorID else { return }
        let userManager = GWSSocialFirebaseUserManager()
        let reporter = GWSFirebaseUserReporter()

        userManager.fetchUser(userID: postAuthorUID) { destUser, _ in
            guard let destUser = destUser else { return }
            reporter.block(sourceUser: sourceUser, destUser: destUser) { _ in
                self.alertTitle = "Blocked!".localizedFeed
                self.alertMessage = "The user has been blocked.".localizedFeed
                self.shouldShowAlert = true
            }
        }
    }

    func report(_ post: GWSPostModel, reason: GWSReportingReason, viewer: GWSUser?) {
        guard let sourceUser = viewer else { return }
        guard let postAuthorUID = post.authorID else { return }
        let userManager = GWSSocialFirebaseUserManager()
        let reporter = GWSFirebaseUserReporter()

        userManager.fetchUser(userID: postAuthorUID) { destUser, _ in
            guard let destUser = destUser else { return }
            reporter.report(sourceUser: sourceUser, destUser: destUser, reason: reason, completion: { _ in
                self.alertTitle = "Reported!".localizedFeed
                self.alertMessage = "The post has been reported.".localizedFeed
                self.shouldShowAlert = true
            })
        }
    }

    func postNotification(composer: GWSNotificationComposerState, completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        let ref = db.collection("socialnetwork_notifications").document()

        let post = composer.post
        let postID = post.id
        guard let postAuthorID = post.authorID else { return }

        let notificationDictionary: [String: Any] = [
            "postID": postID,
            "postAuthorID": postAuthorID,
            "notificationAuthorID": composer.notificationAuthorID,
            "reacted": composer.reacted,
            "commented": composer.commented,
            "isInteracted": composer.isInteracted,
            "createdAt": composer.createdAt ?? Date(),
            "id": ref.documentID,
        ]
        ref.setData(notificationDictionary, merge: true)
        completion()
    }

    func fetchPostComments(post: GWSPostModel) {
        let db = Firestore.firestore()
        let commentsRef = db.collection("socialnetwork_comments")
        var postCommentsArray: [GWSPostComment] = []
        let userManager = GWSSocialFirebaseUserManager()

        let postComments = commentsRef.whereField("postID", isEqualTo: post.id) // .order(by: "createdAt", descending: true)
        postComments.getDocuments { querySnapshot, error in
            if let _ = error {
                print("Comments couldn't be fetched")
                return
            }

            guard let snapshot = querySnapshot else { return }
            let documents = snapshot.documents
            var fetchedDocumentCount = documents.count
            for doc in documents {
                let data = doc.data()
                let timeStamp = data["createdAt"] as? Timestamp
                let date = timeStamp?.dateValue()
                let authorID = data["commentauthorID"] as? String ?? ""
                userManager.fetchUser(userID: authorID, completion: { user, _ in
                    guard let user = user else {
                        fetchedDocumentCount -= 1
                        return
                    }
                    let newComment = GWSPostComment(jsonDict: data)
                    newComment.createdAt = date
                    newComment.commentAuthorProfilePicture = user.profilePictureURL
                    newComment.commentAuthorUsername = user.fullName()
                    postCommentsArray.append(newComment)

                    if fetchedDocumentCount == postCommentsArray.count {
                        self.postComments.removeAll()
                        let sortedPostComments = postCommentsArray.sorted(by: { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) })
                        self.postComments = sortedPostComments
                    }
                })
            }
        }
    }

    func sendPushToPostUser(message: String, post: GWSPostModel) {
        guard let postAuthorID = post.authorID else { return }
        let userManager = GWSSocialFirebaseUserManager()
        userManager.fetchUser(userID: postAuthorID) { user, _ in
            let notificationSender = GWSPushNotificationSender()
            if let token = user?.pushToken {
                notificationSender.sendPushNotification(to: token, title: "iMessenger", body: message)
            }
        }
    }

    func saveNewComment(loggedInUser _: GWSUser, commentComposer: GWSCommentComposerState, post: GWSPostModel, completion: @escaping () -> Void) {
        // Save comments to firebase here
        let db = Firestore.firestore()
        let commentsCollectionRef = db.collection("socialnetwork_comments")

        var newCommentDictionary: [String: Any] = [
            "postID": commentComposer.postID ?? "",
            "commentauthorID": commentComposer.commentAuthorID ?? "",
            "commentText": commentComposer.commentText ?? "",
            "createdAt": commentComposer.date ?? Date(),
        ]

        let document = commentsCollectionRef.document()
        newCommentDictionary["commentID"] = document.documentID

        document.setData(newCommentDictionary)
        updatePost(post: post) {
            completion()
        }
    }

    // updating a post once a comment has been made
    func updatePost(post: GWSPostModel, completion: @escaping () -> Void) {
        let ref = Firestore.firestore().collection("SocialNetwork_Posts")
        let postID = post.id

        let postRef = ref.document("\(postID)")
        postRef.getDocument { snapshot, error in
            if let _ = error {
                print("No doc found")
                return
            }

            guard let querySnapshot = snapshot else { return }
            guard let data = querySnapshot.data() else { return }

            guard let commentCount = data["commentCount"] as? Int else { return }

            let newCommentCount = commentCount + 1
            postRef.setData(["commentCount": newCommentCount], merge: true)
            completion()
        }
    }

    func updatePostReactions(loggedInUser: GWSUser?, post: GWSPostModel?, reaction: String, completion: @escaping () -> Void) {
        // add reactions logic here
        guard let post = post else { return }
        guard let loggedInUserUID = loggedInUser?.uid else { return }

        // 1. Get the post using post.id
        // 2. Fetch the reactions dictionary
        let db = Firestore.firestore()
        let ref = db.collection("SocialNetwork_Posts").document("\(post.id)")
        let reactionRef = db.collection("socialnetwork_reactions")

        ref.getDocument { snapshot, error in
            if let _ = error {
                print("Error")
                completion()
                return
            }
            guard let querySnapshot = snapshot else { return }
            guard let data = querySnapshot.data() else { return }

            let reactionsDictionary = data["reactions"] as? [String: Int]

            guard var dictionary = reactionsDictionary else { return }

            // 3. Check which reaction is sent through function
            // 4. Increment that reaction
            switch reaction {
            case "like":
                guard let likereaction = dictionary["like"] else { return }
                dictionary["like"] = likereaction + 1
            case "surprised":
                guard let surprisedreaction = dictionary["surprised"] else { return }
                dictionary["surprised"] = surprisedreaction + 1
            case "sad":
                guard let sadreaction = dictionary["sad"] else { return }
                dictionary["sad"] = sadreaction + 1
            case "angry":
                guard let angryReaction = dictionary["angry"] else { return }
                dictionary["angry"] = angryReaction + 1
            case "laugh":
                guard let laughReaction = dictionary["laugh"] else { return }
                dictionary["laugh"] = laughReaction + 1
            case "love":
                guard let loveReaction = dictionary["love"] else { return }
                dictionary["love"] = loveReaction + 1
            default:
                break
            }

            let reactionDoc = reactionRef.whereField("reactionAuthorID", isEqualTo: loggedInUserUID)

            reactionDoc.getDocuments(completion: { querySnapshot, error in
                if let _ = error {
                    return
                }
                guard let snapshot = querySnapshot else { return }
                let documents = snapshot.documents
                for doc in documents {
                    let data = doc.data()
                    let postID = data["postID"] as? String
                    guard let postid = postID else { return }
                    if postid == post.id {
                        let prevReaction = data["reaction"] as? String
                        guard let previousReaction = prevReaction else {
                            return
                        }
                        guard let previousReactionCount = dictionary["\(previousReaction)"] else {
                            if reaction == "no_reaction" {
                                doc.reference.delete()
                                completion()
                                return
                            }
                            return
                        }
                        dictionary["\(previousReaction)"] = previousReactionCount - 1
                        let reactionValues = Array(dictionary.values)
                        let totalReactionCount = reactionValues.reduce(0, +)
                        ref.setData(["reactions": dictionary], merge: true)
                        ref.setData(["reactionsCount": totalReactionCount], merge: true)

                        if reaction == "no_reaction" {
                            doc.reference.delete()
                            completion()
                            return
                        }
                        doc.reference.setData(["reaction": reaction], merge: true)
                        completion()
                        return
                    }
                }

                let newReactionDocRef = reactionRef.document()

                // Add the new reaction to the post
                let reactionDic: [String: String] = [
                    "postID": "\(post.id)",
                    "reactionAuthorID": "\(loggedInUserUID)",
                    "reaction": reaction,
                ]
                newReactionDocRef.setData(reactionDic)

                let reactionValues = Array(dictionary.values)
                let totalReactionCount = reactionValues.reduce(0, +)

                ref.setData(["reactions": dictionary], merge: true)
                ref.setData(["reactionsCount": totalReactionCount], merge: true)
                completion()
            })
        }
    }
}
