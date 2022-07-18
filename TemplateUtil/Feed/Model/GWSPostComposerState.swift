//
//  GWSPostComposerState.swift
//  SocialNetwork
//
//  Created by Jared Sullivan and Osama Naeem on 27/06/2019.
//  Copyright © 2022 Lawn and Order. All rights reserved.
//

import UIKit

class GWSPostComposerState {
    var postText: String?
    var postMedia: [UIImage]? = []
    var postVideoPreview: [UIImage]? = []
    var postVideo: [URL]? = []
    var location: String?
    var latitude: Double?
    var longitude: Double?
    var date: Date? = Date()
}
