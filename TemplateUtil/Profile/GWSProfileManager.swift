//
//  GWSEcommerceProfileManager.swift
//  Shopertino
//
//  Created by Jared Sullivan and Florian Marcu on 5/18/19.
//  Copyright © 2022 Lawn and Order. All rights reserved.
//

import UIKit

protocol GWSProfileManagerDelegate: AnyObject {
    func profileEditManager(_ manager: GWSProfileManager, didFetch user: GWSUser) -> Void
    func profileEditManager(_ manager: GWSProfileManager, didUpdateProfile success: Bool) -> Void
}

protocol GWSProfileManager: AnyObject {
    var delegate: GWSProfileManagerDelegate? { get set }
    func fetchProfile(for user: GWSUser) -> Void
    func update(profile: GWSUser,
                email: String,
                firstName: String,
                lastName: String,
                phone: String) -> Void
    func updateUserPresence(profile: GWSUser, isOnline: Bool) -> Void
}
