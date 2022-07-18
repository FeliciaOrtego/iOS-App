//
//  GWSProfileUpdaterProtocol.swift
//  DatingApp
//
//  Created by Jared Sullivan and Florian Marcu on 2/2/19.
//  Copyright © 2022 Lawn and Order. All rights reserved.
//

import UIKit

protocol GWSProfileUpdaterProtocol: AnyObject {
    func removePhoto(url: String, user: GWSUser, completion: @escaping () -> Void)
    func uploadPhoto(image: UIImage, user: GWSUser, isProfilePhoto: Bool, completion: @escaping (_ success: Bool) -> Void)
    func updateProfilePicture(url: String?, user: GWSUser, completion: @escaping (_ success: Bool) -> Void)
    func update(user: GWSUser,
                email: String,
                firstName: String,
                lastName: String,
                username: String,
                completion: @escaping (_ success: Bool) -> Void)
    func updateLocation(for user: GWSUser, to location: GWSLocation, completion: @escaping (_ success: Bool) -> Void)
    func updateSettings(user: GWSUser,
                        settings: [String: Any],
                        completion: @escaping (_ success: Bool) -> Void)
}
