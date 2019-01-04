//
//  LocationService.swift
//  geofence
//
//  Created by Modo Ltunzher on 1/3/19.
//  Copyright © 2019 Modo Ltunzher. All rights reserved.
//

import Foundation
import RxSwift
import CoreLocation

public struct HybridRegion {
    public var geofenceCenter: CLLocationCoordinate2D?
    public var geofenceRadius: CLLocationDistance = 0
    // TODO: public var wifiName: String?
}

public protocol LocationService {
    
    var serviceAuthorizationStatus: CLAuthorizationStatus { get }
    var serviceAuthorizationStatusObservable: Observable<CLAuthorizationStatus> { get }
    
    var serviceIsEnabledObservable: Observable<Bool> { get }
    var isMonitoringObservable: Observable<Bool> { get }
    var regionStateObservable: Observable<CLRegionState?> { get }

    func requestAlwaysAuthorization()
    
    var geofenceRegion: Variable<HybridRegion> { get }
}
