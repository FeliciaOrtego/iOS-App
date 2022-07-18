//
//  GWSWalkthroughModel.swift
//  SCore
//
//  Created by Jared Sullivan and Florian Marcu on 8/13/18.
//  Copyright © 2022 Lawn and Order. All rights reserved.
//

import UIKit

class GWSWalkthroughModel {
    var title: String
    var subtitle: String
    var icon: String

    init(title: String, subtitle: String, icon: String) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }

    public required init(jsonDict _: [String: Any]) {
        fatalError()
    }

    var description: String {
        return title
    }
}
