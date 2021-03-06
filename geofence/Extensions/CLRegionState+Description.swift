//
//  CLRegionState+Description.swift
//  geofence
//
//  Created by Modo Ltunzher on 1/3/19.
//  Copyright © 2019 Modo Ltunzher. All rights reserved.
//

import CoreLocation

extension CLRegionState {
    
    var humanReadableDescription: String {
        switch self {
        case .unknown: return "Unknown"
        case .inside: return "Inside region"
        case .outside: return "Outside region"            
        }
    }
    
}
