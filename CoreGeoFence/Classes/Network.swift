//
//  Network.swift
//  CoreGeoFence
//
//  Created by Modo Ltunzher on 1/4/19.
//  Copyright © 2019 Modo Ltunzher. All rights reserved.
//

import UIKit
import SystemConfiguration.CaptiveNetwork

class Network: NSObject {

    class func getSSIDName() -> String? {
        guard let interfaces = CNCopySupportedInterfaces() else {
            return nil
        }
        for index in 0..<CFArrayGetCount(interfaces) {
            let value: UnsafeRawPointer = CFArrayGetValueAtIndex(interfaces, index)
            let interfaceName = unsafeBitCast(value, to: AnyObject.self)
            let unsafeInterfaceData = CNCopyCurrentNetworkInfo("\(interfaceName)" as CFString)
            if let interfaceData = unsafeInterfaceData as? [String: AnyObject],
                let ssid = interfaceData["SSID"] as? String {
                return ssid
            }
        }
        return nil
    }
}
