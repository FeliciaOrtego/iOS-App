//
//  GWSNetworkingManager.swift
//  AppTemplatesCore
//
//  Created by Jared Sullivan and Florian Marcu on 2/2/17.
//  Copyright © 2017 iOS App Templates. All rights reserved.
//

import Alamofire

public enum GWSNetworkResponseStatus {
    case success
    case error(string: String?)
}

public class GWSNetworkingManager {
    let queue = DispatchQueue(label: "networking-manager-requests", qos: .userInitiated, attributes: .concurrent)

    func getJSONResponse(path: String, parameters: [String: String]?, completionHandler: @escaping (_ response: Any?, _ status: GWSNetworkResponseStatus) -> Void) {
        AF.request(path, method: .get, parameters: parameters)
            .responseJSON(queue: queue, options: []) { response in
                DispatchQueue.main.async {
                    switch response.result {
                    case let .success(value):
                        completionHandler(value, .success)
                    case let .failure(error):
                        print(error)
                        completionHandler(nil, .error(string: error.localizedDescription))
                    }
                }
            }
    }

    func get(path: String, params: [String: String]?, completion: @escaping ((_ jsonResponse: Any?, _ responseStatus: GWSNetworkResponseStatus) -> Void)) {
        AF.request(path, parameters: params).responseJSON { response in
            DispatchQueue.main.async {
                switch response.result {
                case let .success(value):
                    completion(value, .success)
                case let .failure(error):
                    print(error)
                    completion(nil, .error(string: error.localizedDescription))
                }
            }
        }
    }
}
