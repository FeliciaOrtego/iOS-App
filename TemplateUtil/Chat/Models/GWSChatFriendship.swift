//
//  GWSChatFriendship.swift
//  ChatApp
//
//  Created by Jared Sullivan and Florian Marcu on 6/5/19.
//  Copyright © 2022 Lawn and Order. All rights reserved.
//

import UIKit

enum GWSFriendshipType {
    case mutual
    case inbound
    case outbound
}

class GWSChatFriendship: NSObject, GWSGenericBaseModel {
    var currentUser: GWSUser
    var otherUser: GWSUser
    var type: GWSFriendshipType
    var id = UUID()

    override var description: String {
        return currentUser.description + otherUser.description + String(type.hashValue)
    }

    init(currentUser: GWSUser, otherUser: GWSUser, type: GWSFriendshipType) {
        self.currentUser = currentUser
        self.otherUser = otherUser
        self.type = type
    }

    public required init(jsonDict _: [String: Any]) {
        fatalError()
    }

    override public var hash: Int {
        var hasher = Hasher()
        hasher.combine(id)
        return hasher.finalize()
    }

    override open func isEqual(_ object: Any?) -> Bool {
        guard let friendship = object as? GWSChatFriendship else { return false }
        return id == friendship.id
    }
}
