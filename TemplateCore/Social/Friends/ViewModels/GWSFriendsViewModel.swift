//
//  GWSFriendsViewModel.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 19/04/21.
//

import FirebaseFirestore
import SwiftUI

class GWSFriendsViewModel: ObservableObject {
    let reportingManager = GWSFirebaseUserReporter()
    @Published var allInBoundUsers: [GWSUser] = []
    @Published var filteredInBoundUsers: [GWSUser] = []
    @Published var outBoundUsers: [GWSUser] = []
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

    func fetchAllUsers(viewer: GWSUser?) {
        guard let viewer = viewer else { return }
        isAllUsersFetching = true

        filteredOutBoundAllUsers.removeAll()
        filteredAllUsers.removeAll()
        fetchUsers(viewer: viewer) { fetchAllUsers in
            self.isAllUsersFetching = false
            self.allUsers = fetchAllUsers
            self.filteredOutBoundAllUsers = self.allUsers.filter { user -> Bool in
                !self.outBoundUsers.contains(user)
            }
            self.filteredAllUsers = self.filteredOutBoundAllUsers
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

    func fetchFriends(viewer: GWSUser?) {
        guard let loggedInUser = loggedInUser else { return }
        guard let viewer = viewer else { return }
        isUsersFetching = true

        if isFollowersFollowingEnabled {
            if viewer.uid != loggedInUser.uid {
                socialManager.fetchInBoundOutBoundUsers(viewer: loggedInUser, isInBoundUsers: true) { inBoundUsers in
                    self.socialManager.fetchInBoundOutBoundUsers(viewer: loggedInUser, isInBoundUsers: false) { outBoundUsers in
                        self.loggedInInBoundUsers = inBoundUsers
                        self.loggedInOutBoundUsers = outBoundUsers
                        self.reportingManager.userIDsBlockedOrReported(by: viewer) { illegalUserIDsSet in
                            self.socialManager.fetchInBoundOutBoundUsers(viewer: viewer, isInBoundUsers: true) { inBoundUsers in
                                self.socialManager.fetchInBoundOutBoundUsers(viewer: viewer, isInBoundUsers: false) { outBoundUsers in
                                    self.isUsersFetching = false
                                    if self.showFollowers {
                                        self.filteredInBoundUsers = inBoundUsers.filter { $0.uid != loggedInUser.uid && !illegalUserIDsSet.contains($0.uid ?? "") }
                                    } else {
                                        self.outBoundUsers = outBoundUsers.filter { $0.uid != loggedInUser.uid && !illegalUserIDsSet.contains($0.uid ?? "") }
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                reportingManager.userIDsBlockedOrReported(by: viewer) { illegalUserIDsSet in
                    self.socialManager.fetchInBoundOutBoundUsers(viewer: viewer, isInBoundUsers: true) { inBoundUsers in
                        self.socialManager.fetchInBoundOutBoundUsers(viewer: viewer, isInBoundUsers: false) { outBoundUsers in
                            self.isUsersFetching = false
                            if self.showFollowers {
                                self.filteredInBoundUsers = inBoundUsers.filter { $0.uid != loggedInUser.uid && !illegalUserIDsSet.contains($0.uid ?? "") }
                            } else {
                                self.outBoundUsers = outBoundUsers.filter { $0.uid != loggedInUser.uid && !illegalUserIDsSet.contains($0.uid ?? "") }
                            }
                        }
                    }
                }
            }
        } else {
            socialManager.fetchInBoundOutBoundUsers(viewer: viewer, isInBoundUsers: true) { inBoundUsers in
                self.socialManager.fetchInBoundOutBoundUsers(viewer: viewer, isInBoundUsers: false) { outBoundUsers in
                    let newInBoundUsers = inBoundUsers.filter { inBoundUser -> Bool in
                        !outBoundUsers.contains(inBoundUser)
                    }
                    self.isUsersFetching = false
                    self.allInBoundUsers = inBoundUsers
                    self.filteredInBoundUsers = newInBoundUsers
                    self.outBoundUsers = outBoundUsers
                }
            }
        }
    }

    func addFriendRequest(fromUser: GWSUser?, toUser: GWSUser) {
        guard let fromUser = fromUser else { return }
        guard let fromUserId = fromUser.uid else { return }
        guard let toUserId = toUser.uid else { return }

        let socialGraphRef = Firestore.firestore().collection("social_graph")
        let fromUserRef = socialGraphRef.document(fromUserId)
        let toUserRef = socialGraphRef.document(toUserId)

        fromUserRef.collection("outbound_users").document(toUserId).setData(toUser.representation)
        toUserRef.collection("inbound_users").document(fromUserId).setData(fromUser.representation)

        userManager.fetchUser(userID: fromUserId) { fromUser, _ in
            let outboundFriendsCount = fromUser?.outboundFriendsCount ?? 0
            self.updateFriendshipsCounts(userID: fromUserId, outBoundFriendsCount: outboundFriendsCount + 1)
        }

        userManager.fetchUser(userID: toUserId) { toUser, _ in
            let inboundFriendsCount = toUser?.inboundFriendsCount ?? 0
            self.updateFriendshipsCounts(userID: toUserId, inBoundFriendsCount: inboundFriendsCount + 1)
        }

        filteredOutBoundAllUsers = allUsers.filter { user -> Bool in
            !self.outBoundUsers.contains(user)
        }
        filteredAllUsers = filteredOutBoundAllUsers

        let message = "\(fromUser.fullName()) " + "just followed you.".localizedChat
        let notificationSender = GWSPushNotificationSender()
        if let token = toUser.pushToken, toUser.uid != fromUser.uid {
            notificationSender.sendPushNotification(to: token, title: "iMessenger", body: message)
        }
    }

    func removeFriendRequest(fromUser: GWSUser?, toUser: GWSUser) {
        guard let fromUser = fromUser else { return }
        guard let fromUserId = fromUser.uid else { return }
        guard let toUserId = toUser.uid else { return }

        let socialGraphRef = Firestore.firestore().collection("social_graph")
        let fromUserRef = socialGraphRef.document(fromUserId)
        let toUserRef = socialGraphRef.document(toUserId)

        fromUserRef.collection("outbound_users").document(toUserId).delete()
        toUserRef.collection("inbound_users").document(fromUserId).delete()

        userManager.fetchUser(userID: fromUserId) { fromUser, _ in
            let outboundFriendsCount = fromUser?.outboundFriendsCount ?? 0
            self.updateFriendshipsCounts(userID: fromUserId, outBoundFriendsCount: outboundFriendsCount > 0 ? outboundFriendsCount - 1 : 0)
        }

        userManager.fetchUser(userID: toUserId) { toUser, _ in
            let inboundFriendsCount = toUser?.inboundFriendsCount ?? 0
            self.updateFriendshipsCounts(userID: toUserId, inBoundFriendsCount: inboundFriendsCount > 0 ? inboundFriendsCount - 1 : 0)
        }
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
}
