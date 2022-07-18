//
//  GWSSocialUserManagerProtocol.swift
//  CryptoApp
//
//  Created by Jared Sullivan and Florian Marcu on 6/29/19.
//  Copyright © 2022 Lawn and Order. All rights reserved.
//

import UIKit

let kGWSLoggedInUserDataDidChangeNotification = Notification.Name("kGWSLoggedInUserDataDidChangeNotification")

protocol GWSSocialUserManagerProtocol: AnyObject {
    func fetchUser(userID: String, completion: @escaping (_ user: GWSUser?, _ error: Error?) -> Void)
}
