//
//  GWSSocialGraphManager.swift
//  ChatApp
//
//  Created by Jared Sullivan and Florian Marcu on 6/5/19.
//  Copyright © 2022 Lawn and Order. All rights reserved.
//

import UIKit

let kSocialGraphDidUpdateNotificationName = NSNotification.Name(rawValue: "kSocialGraphDidUpdateNotificationName")
let kFriendsPresenceUpdateNotificationName = NSNotification.Name(rawValue: "kFriendsPresenceUpdateNotificationName")

protocol GWSSocialGraphManagerProtocol: AnyObject {
    var isFriendsUpdateNeeded: Bool { get set }
    func acceptFriendRequest(viewer: GWSUser, from user: GWSUser, completion: @escaping () -> Void)
    func cancelFriendRequest(viewer: GWSUser, to user: GWSUser, completion: @escaping () -> Void)
    func sendFriendRequest(viewer: GWSUser, to user: GWSUser, completion: @escaping () -> Void)
    func fetchFriendships(viewer: GWSUser, completion: @escaping (_ friendships: [GWSChatFriendship]) -> Void)
    func fetchFriends(viewer: GWSUser, completion: @escaping (_ friends: [GWSUser]) -> Void)
    func fetchUsers(viewer: GWSUser, completion: @escaping (_ friends: [GWSUser]) -> Void)
    func removeFriendListeners()
}
