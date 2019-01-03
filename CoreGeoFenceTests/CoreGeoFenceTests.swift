//
//  CoreGeoFenceTests.swift
//  CoreGeoFenceTests
//
//  Created by Modo Ltunzher on 1/3/19.
//  Copyright © 2019 Modo Ltunzher. All rights reserved.
//

import XCTest
import CoreLocation
import Foundation
import RxSwift
@testable import CoreGeoFence

class FakeLocationManager: LocationManager {
    /*
     CLLocationManager region monitoring is saved by iOS between launches,
     thus we mimic fake regions list
     */
    var regions: Set<CLRegion> = []
    
    internal override func monitoredRegions() -> Set<CLRegion> {
        return self.regions
    }
    
    internal override func addMonitoredRegion(_ region: CLRegion) {
        self.regions = self.regions.filter { $0.identifier != region.identifier }
        regions.insert(region)
    }
    
    internal override func removeMonitoredRegion(_ region: CLRegion) {
        self.regions = self.regions.filter { $0.identifier != region.identifier }
    }
    
    func getOwningRegions() -> [CLRegion] {
        return self.monitoredRegions().filter {
            $0.identifier == self.geofenceRegionId
        }
    }
}

enum TestFakeError: Error {
    case stubError
}

class CoreGeoFenceTests: XCTestCase {

    var manager: FakeLocationManager!
    
    override func setUp() {
        self.manager = FakeLocationManager()
    }

    override func tearDown() {
        self.manager = nil
    }

    func testUpdateGeofenceNil() {
        let location: CLLocationCoordinate2D? = nil
        let radius: CLLocationDistance = 100
        
        self.manager.updateGeofence(center: location, radius: radius)
        let count = self.manager.getOwningRegions().count

        XCTAssert(count == 0)
    }

    func testUpdateGeofenceZeroRadius() {
        let location = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let radius: CLLocationDistance = 0
        
        self.manager.updateGeofence(center: location, radius: radius)
        
        let count = self.manager.getOwningRegions().count
        XCTAssert(count == 0)
    }

    func testUpdateGeofenceValid() {
        let location = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let radius: CLLocationDistance = 100
        
        self.manager.updateGeofence(center: location, radius: radius)
        let count = self.manager.getOwningRegions().count
        
        XCTAssert(count == 1)
    }
    
    func testUpdateGeofenceMulti() {
        let location = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        
        self.manager.updateGeofence(center: location, radius: 100)
        self.manager.updateGeofence(center: location, radius: 0)
        self.manager.updateGeofence(center: location, radius: 200)
        let count = self.manager.getOwningRegions().count
        
        XCTAssert(count == 1)
    }

    func testValidRegionValues() {
        let lat: Double = 55.55
        let lon: Double = -11.11
        
        let location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let radius: CLLocationDistance = 99
        
        self.manager.updateGeofence(center: location, radius: radius)
        
        XCTAssert(self.manager.geofenceCenter.value?.latitude.isEqual(to: lat) ?? false)
        XCTAssert(self.manager.geofenceCenter.value?.longitude.isEqual(to: lon) ?? false)
        XCTAssert(self.manager.geofenceRadius.value.isEqual(to: radius))
    }

    func testGeofenceValuesUpdate() {
        let lat: Double = 0.9999999
        let lon: Double = 0.9999999
        let location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let radius: CLLocationDistance = 64.9999999

        self.manager.updateGeofence(center: CLLocationCoordinate2D(latitude: 1, longitude: 1), radius: 1)
        self.manager.updateGeofence(center: location, radius: radius)

        XCTAssert(self.manager.geofenceCenter.value?.latitude.isEqual(to: lat) ?? false)
        XCTAssert(self.manager.geofenceCenter.value?.longitude.isEqual(to: lon) ?? false)
        XCTAssert(self.manager.geofenceRadius.value.isEqual(to: radius))
    }

    func testGeofenceMonitoringValues() {
        let location = CLLocationCoordinate2D(latitude: 0.9999999, longitude: 0.9999999)
        
        self.manager.updateGeofence(center: location, radius: 1)
        
        XCTAssert(self.manager.isMonitoring)
    }

    func testGeofenceMonitoringFaultyValues() {
        self.manager.updateGeofence(center: nil, radius: 1)
        
        XCTAssertFalse(self.manager.isMonitoring)
        XCTAssert(self.manager.regionState == nil)
    }

    func testGeofenceMonitoringStartValues() {
        let location = CLLocationCoordinate2D(latitude: 0.9999999, longitude: 0.9999999)

        self.manager.updateGeofence(center: location, radius: 1)
        
        XCTAssertTrue(self.manager.isMonitoring)
        XCTAssert(self.manager.regionState != nil)
    }

    func testRegionEnter() {
        self.manager.updateGeofence(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), radius: 1)
        guard let region = self.manager.monitoredRegions().first else {
            XCTFail("There should be a region")
            return
        }
        
        self.manager.locationManager(self.manager.clLocationManager, didEnterRegion: region)
        
        XCTAssertTrue(self.manager.isMonitoring)
        XCTAssert(self.manager.regionState == .inside)
    }

    func testRegionExit() {
        self.manager.updateGeofence(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), radius: 1)
        guard let region = self.manager.monitoredRegions().first else {
            XCTFail("There should be a region")
            return
        }
        
        self.manager.locationManager(self.manager.clLocationManager, didExitRegion: region)
        
        XCTAssertTrue(self.manager.isMonitoring)
        XCTAssert(self.manager.regionState == .outside)
    }

    func testRegionStateUpdate() {
        self.manager.updateGeofence(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), radius: 1)
        guard let region = self.manager.monitoredRegions().first else {
            XCTFail("There should be a region")
            return
        }
        
        self.manager.locationManager(self.manager.clLocationManager, didDetermineState: .outside, for: region)
        
        XCTAssertTrue(self.manager.isMonitoring)
        XCTAssert(self.manager.regionState == .outside)
    }
    
    func testInvalidRegionStateUpdate() {
        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), radius: 1, identifier: "123")
        
        self.manager.locationManager(self.manager.clLocationManager, didDetermineState: .outside, for: region)
        
        XCTAssertFalse(self.manager.isMonitoring)
        XCTAssert(self.manager.regionState == nil)
    }
    
    func testRegionMonitoringFailed() {
        self.manager.updateGeofence(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), radius: 1)
        guard let region = self.manager.monitoredRegions().first else {
            XCTFail("There should be a region")
            return
        }
        
        self.manager.locationManager(self.manager.clLocationManager, monitoringDidFailFor: region, withError: TestFakeError.stubError)
        
        XCTAssertTrue(self.manager.isMonitoring)
        XCTAssert(self.manager.regionState == nil)
    }

}
