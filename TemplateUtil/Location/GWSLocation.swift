//
//  GWSLocation.swift
//  DatingApp
//
//  Created by Jared Sullivan and Florian Marcu on 6/16/19.
//  Copyright © 2022 Lawn and Order. All rights reserved.
//

import CoreLocation
import UIKit

class GWSLocation: NSObject, GWSGenericBaseModel, NSCoding {
    var longitude: Double
    var latitude: Double

    public init(longitude: Double, latitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    public init(representation: [String: Any]) {
        longitude = representation["longitude"] as? Double ?? 0
        latitude = representation["latitude"] as? Double ?? 0
    }

    public required init(jsonDict _: [String: Any]) {
        fatalError()
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(longitude, forKey: "longitude")
        aCoder.encode(latitude, forKey: "latitude")
    }

    public required convenience init?(coder aDecoder: NSCoder) {
        self.init(longitude: aDecoder.decodeObject(forKey: "longitude") as? Double ?? 0.0,
                  latitude: aDecoder.decodeObject(forKey: "latitude") as? Double ?? 0.0)
    }

    var representation: [String: Any] {
        let rep: [String: Any] = [
            "longitude": longitude,
            "latitude": latitude,
        ]
        return rep
    }

    func isInRange(to location: GWSLocation, by distance: Double) -> Bool {
        return (self.distance(to: location) / 1609.34 <= distance)
    }

    func stringDistance(to location: GWSLocation) -> String {
        let distance = Int(self.distance(to: location) / 1609.34)
        return String(distance) + " miles"
    }

    fileprivate func distance(to otherLocation: GWSLocation) -> Double {
        let myLocation = CLLocation(latitude: latitude, longitude: longitude)
        let theirLocation = CLLocation(latitude: otherLocation.latitude, longitude: otherLocation.longitude)
        return myLocation.distance(from: theirLocation)
    }
}
