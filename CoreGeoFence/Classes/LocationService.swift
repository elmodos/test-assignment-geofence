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

public protocol LocationService {
    
    var serviceAuthorizationStatus: CLAuthorizationStatus { get }
    var serviceAuthorizationStatusObservable: Observable<CLAuthorizationStatus> { get }
    
    var serviceIsEnabled: Bool { get }
    var serviceIsEnabledObservable: Observable<Bool> { get }

    var isMonitoring: Bool { get }
    var isMonitoringObservable: Observable<Bool> { get }

    var regionState: CLRegionState? { get }
    var regionStateObservable: Observable<CLRegionState?> { get }

    func requestAlwaysAuthorization()
    
    var geofenceCenter: Variable<CLLocationCoordinate2D?> { get }
    var geofenceRadius: Variable<CLLocationDistance> { get }
}
