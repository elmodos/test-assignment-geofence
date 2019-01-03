//
//  LocationManager.swift
//  geofence
//
//  Created by Modo Ltunzher on 1/3/19.
//  Copyright © 2019 Modo Ltunzher. All rights reserved.
//

import UIKit
import CoreLocation

public class LocationManager: NSObject, LocationService, CLLocationManagerDelegate {

// MARK: Publics

// MARK: Privates

    internal let clLocationManager = CLLocationManager()
    
// MARK: - Memory Management

    public override init() {
        super.init()
        self.clLocationManager.delegate = self
    }
    
// MARK: - Action Handlers

// MARK: - Public

    public func requestAlwaysAuthorization() {
        self.clLocationManager.requestAlwaysAuthorization()
    }
    
// MARK: - Private
    
// MARK: - CLLocationManagerDelegate

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // TODO
    }
    
}
