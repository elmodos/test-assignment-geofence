//
//  LocationManager.swift
//  geofence
//
//  Created by Modo Ltunzher on 1/3/19.
//  Copyright © 2019 Modo Ltunzher. All rights reserved.
//

import UIKit
import RxSwift
import CoreLocation

public class LocationManager: NSObject, LocationService, CLLocationManagerDelegate {

// MARK: Publics

    public var serviceAuthorizationStatus: CLAuthorizationStatus {
        return self.variableServiceAuthorizationStatus.value
    }
    public var serviceAuthorizationStatusObservable: Observable<CLAuthorizationStatus> {
        return self.variableServiceAuthorizationStatus.asObservable()
    }
    public var serviceIsEnabledObservable: Observable<Bool> {
        return self.variableServiceIsEnabled.asObservable()
    }

    public var isMonitoring: Bool {
        return self.variableIsMonitoring.value
    }
    public var isMonitoringObservable: Observable<Bool> {
        return self.variableIsMonitoring.asObservable()
    }

    public var regionState: CLRegionState? {
        return self.variableRegionState.value
    }
    public var regionStateObservable: Observable<CLRegionState?> {
        return self.variableRegionState.asObservable()
    }

    public let geofenceRegion = Variable<HybridRegion>(HybridRegion())

// MARK: Privates

    internal let variableServiceAuthorizationStatus = Variable(CLLocationManager.authorizationStatus())
    internal let variableServiceIsEnabled = Variable(CLLocationManager.locationServicesEnabled())
    internal let variableIsMonitoring = Variable(false)
    internal let variableRegionState = Variable<CLRegionState?>(nil)
    internal let clLocationManager = CLLocationManager()

    internal let disposeBag = DisposeBag()
    internal let geofenceRegionId = "geofenceRegionId"
    
// MARK: - Memory Management

    public override init() {
        super.init()
        self.clLocationManager.delegate = self

        let regions = self.monitoredRegions()
        if let region = regions.first(where: { $0.identifier == self.geofenceRegionId }) as? CLCircularRegion {
            var hybridRegion = HybridRegion()
            hybridRegion.geofenceCenter = region.center
            hybridRegion.geofenceRadius = region.radius
            self.geofenceRegion.value = hybridRegion
        }
        
        self.geofenceRegion.asObservable()
            .subscribe(onNext: { [weak self] (region) in
                self?.reloadRegion(region)
            })
            .disposed(by: self.disposeBag)

    }
    
// MARK: - Action Handlers

// MARK: - Public

    public func requestAlwaysAuthorization() {
        self.clLocationManager.requestAlwaysAuthorization()
    }
    
// MARK: - Private
    
    internal func reloadRegion(_ region: HybridRegion) {
        if let center = region.geofenceCenter,
            region.geofenceRadius > 0 {
            print("region update")
            let region = CLCircularRegion(center: center, radius: region.geofenceRadius, identifier: self.geofenceRegionId)
            region.notifyOnExit = true
            region.notifyOnEntry = true
            self.addMonitoredRegion(region)
            self.variableRegionState.value = .unknown
        } else {
            print("region unset")
            self.monitoredRegions()
                .filter { $0.identifier == self.geofenceRegionId }
                .forEach { self.removeMonitoredRegion($0) }
            self.variableRegionState.value = nil
        }
        // TODO: check if monitoredRegions returns new list immediatelly with new item
        self.variableIsMonitoring.value = self.monitoredRegions().count > 0
    }
    
// MARK: - Private (XCTest)
    
    internal func monitoredRegions() -> Set<CLRegion> {
        return self.clLocationManager.monitoredRegions
    }
    
    internal func addMonitoredRegion(_ region: CLRegion) {
        self.clLocationManager.startMonitoring(for: region)
    }

    internal func removeMonitoredRegion(_ region: CLRegion) {
        self.clLocationManager.stopMonitoring(for: region)
    }
    
// MARK: - CLLocationManagerDelegate

    public func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        if region.identifier == self.geofenceRegionId {
            self.variableRegionState.value = state
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region.identifier == self.geofenceRegionId {
            self.variableRegionState.value = .inside
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region.identifier == self.geofenceRegionId {
            self.variableRegionState.value = .outside
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.variableServiceAuthorizationStatus.value = .restricted
    }
    
    public func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        if region?.identifier == self.geofenceRegionId {
            self.variableRegionState.value = nil
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.variableServiceAuthorizationStatus.value = status
        self.variableServiceIsEnabled.value = CLLocationManager.locationServicesEnabled()
    }
    
    public func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("Region monitoring started \"\(region.identifier)\"")
        if region.identifier == self.geofenceRegionId {
            manager.requestState(for: region)
        }
    }
    
}
