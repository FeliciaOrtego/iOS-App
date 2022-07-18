//
//  GWSFacebookAPIManager.swift
//  AppTemplatesCore
//
//  Created by Jared Sullivan and Florian Marcu on 2/2/17.
//  Copyright © 2017 iOS App Templates. All rights reserved.

import FBSDKCoreKit
import FBSDKLoginKit

let kGraphPathMe = "me"
let kGraphPathMePageLikes = "me/likes"

class GWSFacebookAPIManager {
    let accessToken: AccessToken
    let networkingManager = GWSNetworkingManager()

    init(accessToken: AccessToken) {
        self.accessToken = accessToken
    }

    func requestFacebookUser(completion: @escaping (_ facebookUser: GWSFacebookUser?) -> Void) {
        var fields = "id,email,last_name,first_name"
        // uncomment below if have facebook profile picture permission
        // fields += ",picture"
        let graphRequest = GraphRequest(graphPath: kGraphPathMe, parameters: ["fields": fields], tokenString: accessToken.tokenString, version: nil, httpMethod: .get)
        graphRequest.start { _, result, _ in
            guard let result = result as? [String: String] else {
                print("Facebook request user error")
                return
            }
            completion(GWSFacebookUser(jsonDict: result))
        }
    }

    func requestFacebookUserPageLikes() {
        let graphRequest = GraphRequest(graphPath: kGraphPathMePageLikes, parameters: [:], tokenString: accessToken.tokenString, version: nil, httpMethod: .get)
        graphRequest.start { _, result, _ in
            print(result ?? "")
        }
    }

    func requestWallPosts(completion: @escaping (_ posts: [GWSFacebookPost]) -> Void) {
        let graphRequest = GraphRequest(graphPath: "me/posts", parameters: ["fields": "link,created_time,description,picture,name", "limit": "500"], tokenString: accessToken.tokenString, version: nil, httpMethod: .get)

        graphRequest.start { _, result, _ in
            guard let result = result as? [String: String] else {
                print("Facebook request user error")
                completion([])
                return
            }
            self.processWallPostResponse(dictionary: result, posts: [], completion: completion)
        }
    }

    private func processWallPostResponse(dictionary: [String: Any?], posts: [GWSFacebookPost], completion: @escaping (_ posts: [GWSFacebookPost]) -> Void) {
        var newPosts = [GWSFacebookPost]()
        if let array = dictionary["data"] as? [[String: String]] {
            for dict in array {
                newPosts.append(GWSFacebookPost(jsonDict: dict))
            }
        }
        guard let paging = dictionary["paging"] as? [String: String], let next = paging["next"] as String?, next.count > 0 else {
            completion(posts + newPosts)
            return
        }
        networkingManager.get(path: next, params: [:], completion: { jsonResponse, responseStatus in
            switch responseStatus {
            case .success:
                guard let jsonResponse = jsonResponse, let dictionary = jsonResponse as? [String: Any] else {
                    completion(posts + newPosts)
                    return
                }
                self.processWallPostResponse(dictionary: dictionary, posts: posts + newPosts, completion: completion)
            case .error:
                completion(posts + newPosts)
            }
        })
    }
}
