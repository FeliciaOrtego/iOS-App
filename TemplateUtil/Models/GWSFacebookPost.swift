//
//  GWSFacebookPost.swift
//  AppTemplatesCore
//
//  Created by Jared Sullivan and Florian Marcu on 2/2/17.
//  Copyright © 2017 iOS App Templates. All rights reserved.
//

class GWSFacebookPost: GWSGenericBaseModel {
    var description: String {
        return ""
    }

    var link: String?
    var createdTime: String?
    var picture: String?
    var name: String?

    required init(jsonDict _: [String: Any]) {
//        link            <- map["link"]
//        createdTime     <- map["created_time"]
//        description     <- map["description"]
//        name            <- map["name"]
//        picture         <- map["picture"]
    }
}
