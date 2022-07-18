//
//  GWSChatChannel.swift
//  ChatApp
//
//  Created by Jared Sullivan and Florian Marcu on 8/26/18.
//  Copyright © 2022 Lawn and Order. All rights reserved.
//

import FirebaseFirestore

class GWSChatChannel: ObservableObject, Identifiable {
    var description: String {
        return id
    }

    let id: String
    let name: String
    let lastMessageDate: Date
    var participants: [GWSUser]
    let lastMessage: String
    let groupCreatorID: String
    var lastMessageSeeners: [[String: String]]

    init(id: String, name: String) {
        self.id = id
        self.name = name
        participants = []
        lastMessageDate = Date().oneYearAgo
        lastMessage = ""
        groupCreatorID = ""
        lastMessageSeeners = []
    }

    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        var name = ""
        if let tmp = data["name"] as? String {
            name = tmp
        }
        id = document.documentID
        self.name = name
        participants = []

        var date = Date().oneYearAgo
        if let d = data["lastMessageDate"] as? Timestamp {
            date = d.dateValue()
        }
        lastMessageDate = date
        var lastMessage = ""
        if let m = data["lastMessage"] as? String {
            lastMessage = m
        }
        var creatorID = ""
        if let id = data["creatorID"] as? String {
            creatorID = id
        }
        lastMessageSeeners = []
        if let lastMessageSeeners = data["lastMessageSeeners"] as? [[String: String]] {
            self.lastMessageSeeners = lastMessageSeeners
        }
        groupCreatorID = creatorID
        self.lastMessage = lastMessage
    }

    init(jsonDict _: [String: Any]) {
        fatalError()
    }
}

extension GWSChatChannel: DatabaseRepresentation {
    var representation: [String: Any] {
        var rep = ["name": name]
        rep["id"] = id
        return rep
    }
}

extension GWSChatChannel: Comparable {
    static func == (lhs: GWSChatChannel, rhs: GWSChatChannel) -> Bool {
        return lhs.id == rhs.id
    }

    static func < (lhs: GWSChatChannel, rhs: GWSChatChannel) -> Bool {
        return lhs.name < rhs.name
    }
}
