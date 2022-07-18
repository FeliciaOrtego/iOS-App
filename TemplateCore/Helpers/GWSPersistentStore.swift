//
//  GWSPersistentStore.swift
//  SCore
//
//  Created by Jared Sullivan and Florian Marcu on 8/16/18.
//  Copyright © 2022 Lawn and Order. All rights reserved.
//

import UIKit

class GWSPersistentStore: ObservableObject {
    private static let kWalkthroughCompletedKey = "kWalkthroughCompletedKey"
    public static let kLoggedInUserKey = "kUserKey"
    @Published var walkthroughCompleted: Bool = false
    @Published var isLogin: Bool = false

    var appConfig: GWSConfigurationProtocol

    init(appConfig: GWSConfigurationProtocol) {
        self.appConfig = appConfig
    }

    func markWalkthroughCompleted() {
        UserDefaults.standard.set(true, forKey: GWSPersistentStore.kWalkthroughCompletedKey)
        walkthroughCompleted = true
    }

    func isWalkthroughCompleted() -> Bool {
        return UserDefaults.standard.bool(forKey: GWSPersistentStore.kWalkthroughCompletedKey)
    }

    func markUserAsLoggedIn(user: GWSUser) {
        do {
            let res = try NSKeyedArchiver.archivedData(withRootObject: user, requiringSecureCoding: false)
            UserDefaults.standard.set(res, forKey: GWSPersistentStore.kLoggedInUserKey)
            isLogin = true
        } catch {
            print("Couldn't save due to \(error)")
        }
    }

    func userIfLoggedInUser() -> GWSUser? {
        do {
            if let data = UserDefaults.standard.value(forKey: GWSPersistentStore.kLoggedInUserKey) as? Data,
               let user = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? GWSUser
            {
                return user
            }
            return nil
        } catch {
            print("Couldn't load due to \(error)")
            return nil
        }
    }

    func logout() {
        UserDefaults.standard.removeObject(forKey: GWSPersistentStore.kLoggedInUserKey)
        isLogin = false
    }
}
