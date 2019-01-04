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
import Reachability

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

    public var isMonitoringGeofenceObservable: Observable<Bool> {
        return self.variableIsMonitoringGeofence.asObservable()
    }

    public var isMonitoringWifiObservable: Observable<Bool> {
        return self.variableIsMonitoringWifi.asObservable()
    }

    public var regionState: CLRegionState? {
        return self.variableRegionState.value
    }
    public var regionStateObservable: Observable<CLRegionState?> {
        return self.variableRegionState.asObservable()
    }

    public var isWifiNameAccessible: Observable<Bool> {
        return self.variableIsWifiNameAccessible.asObservable()
    }

    public let geofenceRegion = Variable<HybridRegion>(HybridRegion())

// MARK: Privates

    internal let variableServiceAuthorizationStatus = Variable(CLLocationManager.authorizationStatus())
    internal let variableServiceIsEnabled = Variable(CLLocationManager.locationServicesEnabled())
    internal let variableIsMonitoringGeofence = Variable(false)
    internal let variableIsMonitoringWifi = Variable(false)
    internal let variableRegionState = Variable<CLRegionState?>(nil)
    internal let variableIsWifiNameAccessible = Variable(false)
    internal let clLocationManager = CLLocationManager()

    internal let disposeBag = DisposeBag()
    internal let geofenceRegionId = "geofenceRegionId"
    
    private let reachability = Reachability()
    
    private let identifier: Int
    private let userDefaults: UserDefaults
    internal lazy var keyWifiName = "LocationManager.\(self.identifier).keyWifiName"
    
// MARK: - Memory Management

    public init(identifier: Int = 0, userDefaults: UserDefaults = .standard) {
        self.identifier = identifier
        self.userDefaults = userDefaults
        
        super.init()
        self.clLocationManager.delegate = self

        // Restore state
        let cachedWifiName = self.userDefaults.string(forKey: self.keyWifiName)
        var cachedRegion: CLCircularRegion? = nil
        let regions = self.monitoredRegions()
        if let region = regions.first(where: { $0.identifier == self.geofenceRegionId }) as? CLCircularRegion {
            cachedRegion = region
        }
        if cachedWifiName != nil || cachedRegion != nil {
            var hybridRegion = HybridRegion()
            hybridRegion.wifiName = cachedWifiName
            if let region = cachedRegion {
                hybridRegion.geofenceCenter = region.center
                hybridRegion.geofenceRadius = region.radius
            }
            self.geofenceRegion.value = hybridRegion
        }
        
        self.variableIsMonitoringWifi.asObservable()
            .subscribe(onNext: { [weak self] (monitoring) in
                self?.runWifiMonitoring(monitoring)
            })
            .disposed(by: self.disposeBag)
        
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
        self.userDefaults.set(region.wifiName, forKey: self.keyWifiName)
        self.userDefaults.synchronize()
        
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

        self.variableIsMonitoringGeofence.value = self.monitoredRegions().count > 0
        self.variableIsMonitoringWifi.value = region.wifiName != nil
    }
    
    private func runWifiMonitoring(_ run: Bool) {
        guard let reachability = self.reachability else {
            self.variableIsWifiNameAccessible.value = false
            return
        }
        
        if run {
            reachability.whenReachable = { [weak self] reachability in
                self?.handleWifiReachability(reachability)
            }
            reachability.whenUnreachable = { [weak self] reachability in
                self?.handleWifiReachability(reachability)
            }
            
            do {
                try reachability.startNotifier()
                self.handleWifiReachability(reachability)
            } catch {
                print("Unable to start notifier")
            }
        } else {
            reachability.whenReachable = nil
            reachability.whenUnreachable = nil
            reachability.stopNotifier()
            self.variableIsWifiNameAccessible.value = false
        }
    }
    
    internal func handleWifiReachability(_ reachability: Reachability?) {
        guard let wifiName = self.geofenceRegion.value.wifiName,
            reachability?.connection == .wifi else {
            self.variableIsWifiNameAccessible.value = false
            return
        }
        self.variableIsWifiNameAccessible.value = wifiName == Network.getSSIDName()
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
