//
//  GWSLocationManager.swift
//  CupertinoKit
//
//  Created by Jared Sullivan and Florian Marcu on 6/16/19.
//  Copyright © 2022 Lawn and Order. All rights reserved.
//

import CoreLocation
import UIKit

protocol GWSLocationManagerDelegate: AnyObject {
    func locationManager(_ locationManager: GWSLocationManager, didReceive location: GWSLocation)
}

class GWSLocationManager: NSObject, CLLocationManagerDelegate {
    let manager: CLLocationManager
    weak var delegate: GWSLocationManagerDelegate?

    override init() {
        manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.distanceFilter = kCLDistanceFilterNone
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.startUpdatingLocation()
    }

    func requestWhenInUsePermission() {
        manager.requestWhenInUseAuthorization()
    }

    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let clLocation = locations.first {
            let location = GWSLocation(longitude: clLocation.coordinate.longitude,
                                       latitude: clLocation.coordinate.latitude)
            delegate?.locationManager(self, didReceive: location)
        }
    }
}
