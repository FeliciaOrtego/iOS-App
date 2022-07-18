//
//  GWSNotificationType.swift
//  ChatApp
//
//  Created by Jared Sullivan and Duy Bui on 6/27/20.
//  Copyright © 2020 Lawn and Order. All rights reserved.
//

import Foundation

enum GWSNotificationType: String {
    case chatAppNewMessage
    case datingAppNewMatch

    var notiticationName: Notification.Name {
        switch self {
        case .chatAppNewMessage:
            return .didReceiveChatAppNewMessage
        case .datingAppNewMatch:
            return .didReceiveDatingAppNewMatch
        }
    }
}

extension Notification.Name {
    static let didReceiveChatAppNewMessage = Notification.Name("didReceiveChatAppNewMessage")
    static let didReceiveDatingAppNewMatch = Notification.Name("didReceiveDatingAppNewMatch")
}
