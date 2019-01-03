//
//  CLAuthorizationStatus+Description.swift
//  geofence
//
//  Created by Modo Ltunzher on 1/3/19.
//  Copyright © 2019 Modo Ltunzher. All rights reserved.
//

import CoreLocation

extension CLAuthorizationStatus {
    
    var humanReadableDescription: String {
        switch self {
        case .notDetermined: return "Not determined"
        case .restricted: return "Device restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Allowed"
        case .authorizedWhenInUse: return "Only when in use"
        }
    }
    
}
