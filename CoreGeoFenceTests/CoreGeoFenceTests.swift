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
}
