//
//  GWSChatGroupMembersViewModel.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 19/04/21.
//

import FirebaseFirestore
import SwiftUI

class GWSChatGroupMembersViewModel: ObservableObject {
    @Published var showProgress: Bool = false
    @Published var groupMembers: [GWSUser] = []
    @Published var selectedFriends: [GWSUser] = []
    let socialManager = GWSFirebaseSocialGraphManager()
    var isChatApp: Bool = false

    init(isChatApp: Bool = false) {
        self.isChatApp = isChatApp
    }

    func fetchFriends(viewer: GWSUser?) {
        guard let viewer = viewer else { return }

        showProgress = true
        if isChatApp {
            let socialManager = GWSCoreFirebaseSocialGraphManager()
            socialManager.fetchFriends(viewer: viewer) { groupMembers in
                self.showProgress = false
                self.groupMembers = groupMembers
            }
        } else {
            socialManager.fetchInBoundOutBoundUsers(viewer: viewer, isInBoundUsers: true) { inBoundUsers in
                self.socialManager.fetchInBoundOutBoundUsers(viewer: viewer, isInBoundUsers: false) { outBoundUsers in
                    let inBoundAndOutBoundUsers = inBoundUsers.filter { inBoundUser -> Bool in
                        outBoundUsers.contains(inBoundUser)
                    }
                    self.showProgress = false
                    self.groupMembers = inBoundAndOutBoundUsers
                }
            }
        }
    }

    func createChannel(creator: GWSUser?, completion: @escaping (_ channel: GWSChatChannel?) -> Void) {
        showProgress = true
        guard let creator = creator, let uid = creator.uid else { return }
        let channelParticipationRef = Firestore.firestore().collection("channel_participation")
        let channelsRef = Firestore.firestore().collection("channels")

        let newChannelRef = channelsRef.document()
        let channelDict: [String: Any] = [
            "lastMessage": "No message",
            "name": "ViewModel",
            "creatorID": uid,
            "channelID": newChannelRef.documentID,
            "id": newChannelRef.documentID,
        ]
        newChannelRef.setData(channelDict)

        let allFriends = [creator] + Array(selectedFriends)
        var count = 0
        allFriends.forEach { friend in
            let doc: [String: Any] = [
                "channel": newChannelRef.documentID,
                "user": friend.uid ?? "",
                "isAdmin": friend.uid == creator.uid,
            ]
            channelParticipationRef.addDocument(data: doc, completion: { _ in
                count += 1
                if count == allFriends.count {
                    newChannelRef.getDocument(completion: { snapshot, _ in
                        guard let snapshot = snapshot else { return }
                        completion(GWSChatChannel(document: snapshot))
                        self.showProgress = false
                    })
                }
            })
        }
    }
}
