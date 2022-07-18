//
//  GWSAddNewStory.swift
//  SocialNetwork
//
//  Created by Jared Sullivan and Osama Naeem on 23/07/2019.
//  Copyright © 2022 Lawn and Order. All rights reserved.
//

import UIKit

class GWSAddNewStory: GWSGenericBaseModel {
    var addImageURL: String?

    init(addImageURL: String?) {
        self.addImageURL = addImageURL
    }

    required init(jsonDict _: [String: Any]) {
        fatalError()
    }

    var description: String {
        return "New Story"
    }
}
