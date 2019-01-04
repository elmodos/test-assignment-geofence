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

    public private(set) var geofenceCenter = Variable<CLLocationCoordinate2D?>(nil)
    public private(set) var geofenceRadius = Variable<CLLocationDistance>(100)

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
        
        let regions = self.monitoredRegions()
        if let region = regions.first(where: { $0.identifier == self.geofenceRegionId }) as? CLCircularRegion {
            self.variableIsMonitoring.value = true
            self.updateGeofenceIfNeeded(center: region.center, radius: region.radius)
        }
        self.clLocationManager.delegate = self
        
        Observable.combineLatest(self.geofenceCenter.asObservable(), self.geofenceRadius.asObservable())
            .subscribe(onNext: { [weak self] (center, radius) in
                self?.updateGeofence(center: center, radius: radius)
            }).disposed(by: self.disposeBag)
    }
    
// MARK: - Action Handlers

// MARK: - Public

    public func requestAlwaysAuthorization() {
        self.clLocationManager.requestAlwaysAuthorization()
    }
    
// MARK: - Private
    
    internal func updateGeofence(center: CLLocationCoordinate2D?, radius: CLLocationDistance) {
        guard let center = center,
            radius > 0 else {
            self.unsetRegion()
            return
        }
        self.addRegion(center: center, radius: radius)
    }
    
    private func updateGeofenceIfNeeded(center: CLLocationCoordinate2D, radius: CLLocationDistance) {
        if let existingCenter = self.geofenceCenter.value {
            if !existingCenter.latitude.isEqual(to: center.latitude)
                || !existingCenter.longitude.isEqual(to: center.longitude) {
                self.geofenceCenter.value = center
            }
        } else {
            self.geofenceCenter.value = center
        }
        
        if !self.geofenceRadius.value.isEqual(to: radius) {
            self.geofenceRadius.value = radius
        }
    }

    internal func addRegion(center: CLLocationCoordinate2D, radius: CLLocationDistance) {
        guard radius > 0 else {
            print("invalid radius")
            return
        }
        print("region add")
        let region = CLCircularRegion(center: center, radius: radius, identifier: self.geofenceRegionId)
        region.notifyOnExit = true
        region.notifyOnEntry = true
        self.addMonitoredRegion(region)
        self.variableRegionState.value = .unknown

        self.updateGeofenceIfNeeded(center: center, radius: radius)
        self.updateMonitoringIndicator()
    }
    
    internal func unsetRegion() {
        print("region unset")
        self.monitoredRegions()
            .filter {
                $0.identifier == self.geofenceRegionId
            } .forEach {
                self.removeMonitoredRegion($0)
            }
        self.variableRegionState.value = nil
        self.updateMonitoringIndicator()
    }
    
    internal func updateMonitoringIndicator() {
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
