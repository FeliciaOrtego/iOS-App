//
//  GWSChatFriendsViewModel.swift
//  ChatApp
//
//  Created by Jared Sullivan and Mayil Kannan on 22/07/21.
//

import FirebaseFirestore
import SwiftUI

let kFriendsRequestNotificationName = NSNotification.Name(rawValue: "kFriendsRequestNotificationName")

class GWSChatFriendsViewModel: ObservableObject {
    let reportingManager = GWSFirebaseUserReporter()
    @Published var friends: [GWSUser] = []
    @Published var filteredInBoundUsers: [GWSUser] = []
    @Published var outBoundUsers: [GWSUser] = []
    @Published var friendships: [GWSChatFriendship] = []
    @Published var isUsersFetching: Bool = false {
        didSet {
            if showLoaderCount == 0, isUsersFetching {
                showLoader = true
                showLoaderCount += 1
            } else if showLoader, !isUsersFetching {
                showLoader = false
            }

            if !isUsersFetching {
                updatingTime = Date()
            }
        }
    }

    @Published var isAllUsersFetching: Bool = false
    let userManager = GWSSocialFirebaseUserManager()
    var allUsers: [GWSUser] = []
    var filteredOutBoundAllUsers: [GWSUser] = []
    @Published var filteredAllUsers: [GWSUser] = []
    let socialManager = GWSFirebaseSocialGraphManager()
    @Published var showLoader: Bool = false
    @Published var showLoaderCount = 0
    @Published var updatingTime: Date = .init()
    var isFriendsListUpdated: Bool = false
    var isFollowersFollowingEnabled: Bool = false
    var showFollowers: Bool = false
    var loggedInUser: GWSUser?
    @Published var loggedInInBoundUsers: [GWSUser] = []
    @Published var loggedInOutBoundUsers: [GWSUser] = []
    @Published var followTextUpdatingTime: Date = .init()
    var showUsersWithOutFollowers = false

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(friendsRequestNotification(notification:)), name: kFriendsRequestNotificationName, object: nil)
    }

    @objc func friendsRequestNotification(notification _: Notification) {
        if !showUsersWithOutFollowers {
            fetchFriendships(viewer: loggedInUser)
        }
    }

    func fetchAllUsers(viewer: GWSUser?) {
        guard let viewer = viewer else { return }
        isAllUsersFetching = true

        filteredOutBoundAllUsers.removeAll()
        filteredAllUsers.removeAll()
        fetchUsers(viewer: viewer) { fetchAllUsers in
            self.fetchFriendships(viewer: viewer) {
                self.isAllUsersFetching = false
                self.allUsers = fetchAllUsers
                self.filteredOutBoundAllUsers = self.allUsers.filter { otherUser -> Bool in
                    !self.friendships.contains(where: { friendship -> Bool in
                        (friendship.currentUser.uid == viewer.uid && friendship.otherUser.uid == otherUser.uid) ||
                            (friendship.otherUser.uid == viewer.uid && friendship.currentUser.uid == otherUser.uid)
                    })
                }
                self.filteredAllUsers = self.filteredOutBoundAllUsers
            }
        }
    }

    private func fetchUsers(viewer: GWSUser, completion: @escaping (_ friends: [GWSUser]) -> Void) {
        reportingManager.userIDsBlockedOrReported(by: viewer) { illegalUserIDsSet in
            let usersRef = Firestore.firestore().collection("users")
            usersRef.getDocuments { querySnapshot, error in
                if error != nil {
                    completion([])
                    return
                }
                guard let querySnapshot = querySnapshot else {
                    completion([])
                    return
                }
                var users: [GWSUser] = []
                let documents = querySnapshot.documents
                for document in documents {
                    let data = document.data()
                    let user = GWSUser(representation: data)
                    if let userID = user.uid {
                        if userID != viewer.uid, !illegalUserIDsSet.contains(userID) {
                            users.append(user)
                        }
                    }
                }
                completion(users)
            }
        }
    }

    func fetchFriends(viewer: GWSUser?, completion: @escaping () -> Void = {}) {
        guard let viewer = viewer else { return }
        isUsersFetching = true

        socialManager.fetchFriends(viewer: viewer) { friends in
            self.isUsersFetching = false
            self.friends = Array(Set(friends))
            completion()
        }
    }

    func fetchFriendships(viewer: GWSUser?, completion: @escaping () -> Void = {}) {
        guard let viewer = viewer else { return }
        isUsersFetching = true

        socialManager.fetchFriendships(viewer: viewer) { friends in
            self.isUsersFetching = false
            self.friendships = friends
            completion()
        }
    }

    func addFriendRequest(fromUser: GWSUser?, toUser: GWSUser) {
        guard let fromUser = fromUser else { return }

        socialManager.sendFriendRequest(viewer: fromUser, to: toUser) {
            NotificationCenter.default.post(name: kFriendsRequestNotificationName, object: nil, userInfo: nil)
        }

        filteredOutBoundAllUsers = filteredOutBoundAllUsers.filter { $0 != toUser }
        filteredAllUsers = filteredAllUsers.filter { $0 != toUser }

        let message = "\(fromUser.fullName()) " + "sent you a friend request".localizedChat
        let notificationSender = GWSPushNotificationSender()
        if let token = toUser.pushToken, toUser.uid != fromUser.uid {
            notificationSender.sendPushNotification(to: token, title: "iMessenger", body: message)
        }
    }

    func acceptFriendRequest(fromUser: GWSUser?, toUser: GWSUser) {
        guard let fromUser = fromUser else { return }
        socialManager.acceptFriendRequest(viewer: toUser, from: fromUser) {
            self.fetchFriendships(viewer: self.loggedInUser)
        }
        friendships.filter { $0.otherUser == fromUser }.first?.type = .mutual
        let message = "\(toUser.fullName()) " + "accepted your friend request".localizedChat
        let notificationSender = GWSPushNotificationSender()
        if let token = toUser.pushToken, toUser.uid != fromUser.uid {
            notificationSender.sendPushNotification(to: token, title: "iMessenger", body: message)
        }
    }

    func cancelFriendRequest(fromUser: GWSUser?, toUser: GWSUser) {
        guard let fromUser = fromUser else { return }
        socialManager.cancelFriendRequest(viewer: fromUser, to: toUser) {
            self.fetchFriendships(viewer: self.loggedInUser)
        }
        friendships = friendships.filter { $0.otherUser != toUser }
    }

    func updateFriendshipsCounts(userID: String, inBoundFriendsCount: Int? = nil, outBoundFriendsCount: Int? = nil) {
        if inBoundFriendsCount == nil, outBoundFriendsCount == nil {
            return
        }
        let usersRef = Firestore.firestore().collection("users").document(userID)
        var data: [String: Any] = [:]
        if let inBoundFriendsCount = inBoundFriendsCount {
            data["inboundFriendsCount"] = inBoundFriendsCount
        }
        if let outBoundFriendsCount = outBoundFriendsCount {
            data["outboundFriendsCount"] = outBoundFriendsCount
        }
        usersRef.setData(data, merge: true)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: kFriendsRequestNotificationName, object: nil)
    }
}
