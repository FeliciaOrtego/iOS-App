//
//  GWSFacebookUser.swift
//  AppTemplatesCore
//
//  Created by Jared Sullivan and Florian Marcu on 2/2/17.
//  Copyright © 2017 iOS App Templates. All rights reserved.
//

class GWSFacebookUser: GWSGenericBaseModel {
    var firstName: String?
    var lastName: String?
    var email: String?
    var id: String?
    var profilePicture: String?

    var description: String {
        return firstName ?? ""
    }

//    required init(jsonDict: [String: Any]) {
    ////        firstName       <- map["first_name"]
    ////        lastName        <- map["last_name"]
    ////        email           <- map["email"]
    ////        id              <- map["id"]
    ////        profilePicture  <- map["picture.data.url"]
//    }

    required init(jsonDict: [String: Any]) {
        firstName = jsonDict["first_name"] as? String
        lastName = jsonDict["last_name"] as? String
        email = jsonDict["email"] as? String
        id = jsonDict["id"] as? String
        if let profilePicObj = jsonDict["picture"] as? [String: Any] {
            if let profilePicData = profilePicObj["data"] as? [String: Any] {
                profilePicture = profilePicData["url"] as? String
            }
        }
    }
}
