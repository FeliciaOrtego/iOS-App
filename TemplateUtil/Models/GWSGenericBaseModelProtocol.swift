//
//  GWSGenericBaseModelProtocol.swift
//  LawnNOrder
//
//  Created by Jared Sullivan and Mayil Kannan on 12/04/21.
//

import UIKit

protocol GWSGenericJSONParsable {
    init(jsonDict: [String: Any])
}

protocol GWSGenericBaseModel: GWSGenericJSONParsable, CustomStringConvertible {}
