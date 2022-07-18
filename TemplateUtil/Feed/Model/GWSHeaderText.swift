//
//  GWSHeaderText.swift
//  SocialNetwork
//
//  Created by Jared Sullivan and Osama Naeem on 26/07/2019.
//  Copyright © 2022 Lawn and Order. All rights reserved.
//

import UIKit

class GWSHeaderText: GWSGenericBaseModel {
    var headerText: String

    init(headerText: String) {
        self.headerText = headerText
    }

    required init(jsonDict _: [String: Any]) {
        fatalError()
    }

    var description: String {
        return headerText
    }
}
