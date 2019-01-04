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
    public var wifiName: String?
    init(geofenceCenter: CLLocationCoordinate2D? = nil, geofenceRadius: CLLocationDistance = 0, wifiName: String? = nil) {
        self.geofenceCenter = geofenceCenter
        self.geofenceRadius = geofenceRadius
        self.wifiName = wifiName
    }
}

public protocol LocationService {
    
    var serviceAuthorizationStatus: CLAuthorizationStatus { get }
    var serviceAuthorizationStatusObservable: Observable<CLAuthorizationStatus> { get }
    
    var serviceIsEnabledObservable: Observable<Bool> { get }
    var isMonitoringGeofenceObservable: Observable<Bool> { get }
    var isMonitoringWifiObservable: Observable<Bool> { get }
    var regionStateObservable: Observable<CLRegionState?> { get }
    var isWifiNameAccessible: Observable<Bool> { get }
    
    func requestAlwaysAuthorization()
    
    var geofenceRegion: Variable<HybridRegion> { get }
}
