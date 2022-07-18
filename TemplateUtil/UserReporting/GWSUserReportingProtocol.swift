//
//  GWSUserReportingProtocol.swift
//  DatingApp
//
//  Created by Jared Sullivan and Florian Marcu on 4/10/19.
//  Copyright © 2022 Lawn and Order. All rights reserved.
//

import UIKit

let kUserReportingDidUpdateNotificationName = NSNotification.Name(rawValue: "kUserReportingDidUpdateNotificationName")

enum GWSReportingReason: String {
    case sensitiveImages
    case spam
    case abusive
    case harmful

    var rawValue: String {
        switch self {
        case .sensitiveImages: return "sensitiveImages"
        case .spam: return "spam"
        case .abusive: return "abusive"
        case .harmful: return "harmful"
        }
    }
}

protocol GWSUserReportingProtocol: AnyObject {
    func report(sourceUser: GWSUser, destUser: GWSUser, reason: GWSReportingReason, completion: @escaping (_ success: Bool) -> Void)
    func block(sourceUser: GWSUser, destUser: GWSUser, completion: @escaping (_ success: Bool) -> Void)
    func userIDsBlockedOrReported(by user: GWSUser, completion: @escaping (_ users: Set<String>) -> Void)
}
